import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:path/path.dart' as path;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/models/conversation_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../../hub/data/repositories/ai_repository.dart';
import '../../domain/services/call_service.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatRepository = ChatRepository();
  final _aiRepository = AIRepository();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  
  Profile? _otherParticipant;
  Conversation? _conversation;
  bool _isLoading = true;
  bool _isFriends = true;
  bool _isInputEmpty = true;
  bool _isSearching = false;
  String _typingUser = '';
  Message? _replyToMessage;
  Message? _editingMessage;
  
  Stream<List<Message>>? _messageStream;
  StreamSubscription? _typingSubscription;
  StreamSubscription? _presenceSubscription;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _loadConversationDetails();
    _messageController.addListener(_onTextChanged);
    _messageStream = _chatRepository.subscribeToMessages(widget.conversationId);
    _setupTypingStatus();
    _setupPresence();
    _chatRepository.markMessagesAsRead(widget.conversationId);
    NotificationService().setActiveConversation(widget.conversationId);
  }

  void _setupTypingStatus() {
    _typingSubscription = _chatRepository.subscribeToTypingStatus(widget.conversationId).listen((payload) {
      if (payload['user_id'] == _otherParticipant?.id) {
        if (mounted) {
          setState(() {
            _typingUser = payload['is_typing'] ? (_otherParticipant?.fullName ?? 'User') : '';
          });
        }
      }
    });
  }

  void _setupPresence() {
    _chatRepository.updatePresence(true);
  }

  void _onTextChanged() {
    final isEmpty = _messageController.text.trim().isEmpty;
    if (isEmpty != _isInputEmpty) {
      setState(() => _isInputEmpty = isEmpty);
    }

    if (!isEmpty) {
      _chatRepository.setTypingStatus(widget.conversationId, true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 2), () {
        _chatRepository.setTypingStatus(widget.conversationId, false);
      });
    }
  }

  Future<void> _loadConversationDetails() async {
    try {
      final conversations = await _chatRepository.getUserConversations();
      final conversation = conversations.firstWhere((c) => c.id == widget.conversationId);
      
      if (conversation.type == 'direct') {
        final isFriends = await _chatRepository.isStillFriends(widget.conversationId);
        if (!isFriends) {
          if (mounted) setState(() { _isFriends = false; _isLoading = false; });
          return;
        }
      }

      final other = _chatRepository.getOtherParticipant(conversation);
      
      if (mounted) {
        setState(() {
          _conversation = conversation;
          _otherParticipant = other;
          _isLoading = false;
        });
      }

      if (other != null) {
        _presenceSubscription?.cancel();
        _presenceSubscription = _chatRepository.subscribeToUserPresence(other.id).listen((p) {
          if (mounted) setState(() => _otherParticipant = p);
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    final replyId = _replyToMessage?.id;
    final editId = _editingMessage?.id;

    _messageController.clear();
    setState(() {
      _replyToMessage = null;
      _editingMessage = null;
    });

    try {
      if (editId != null) {
        await _chatRepository.editMessage(editId, content);
      } else {
        await _chatRepository.sendMessage(
          conversationId: widget.conversationId,
          content: content,
          replyToMessageId: replyId,
        );
        _scrollToBottom();
      }
      _chatRepository.setTypingStatus(widget.conversationId, false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _improveWithAI() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('AI is helping...'), duration: Duration(seconds: 1)),
    );

    try {
      final improved = await _aiRepository.getAIResponse(
        conversationId: 'temp_improvement',
        prompt: 'Rewrite this message to be more professional or natural in a chat context, keeping the same meaning: "$text". Return only the rewritten message without any other text.',
        saveToHistory: false,
      );

      if (mounted) _messageController.text = improved;
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('AI helper error: $e')));
    }
  }

  Future<void> _startVoiceCall() async {
    if (_otherParticipant == null) return;
    
    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Microphone permission required.')));
        return;
      }

      await CallService().initCall(_otherParticipant!.id);
      if (mounted) context.push('/outgoing-call', extra: _otherParticipant);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Call failed: $e')));
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  @override
  void dispose() {
    NotificationService().setActiveConversation(null);
    _chatRepository.setTypingStatus(widget.conversationId, false);
    _typingSubscription?.cancel();
    _presenceSubscription?.cancel();
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _focusNode.dispose();
    _chatRepository.dispose();
    super.dispose();
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.only(top: 12, bottom: 32, left: 24, right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            const Text('Attach', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildAttachOption(Icons.image_rounded, 'Gallery', Colors.blue, () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
                const SizedBox(width: 16),
                _buildAttachOption(Icons.camera_alt_rounded, 'Camera', Colors.green, () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachOption(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: color)),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 70);
    if (image != null && mounted) _showImagePreview(File(image.path));
  }

  void _showImagePreview(File file) {
    showDialog(context: context, useSafeArea: false, builder: (context) => _ImagePreviewDialog(imageFile: file, onSend: (caption) => _uploadAndSendImage(file, caption)));
  }

  Future<void> _uploadAndSendImage(File file, String? caption) async {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uploading image...'), duration: Duration(seconds: 1)));
    try {
      final fileName = path.basename(file.path);
      final storagePath = '${widget.conversationId}/${sb.Supabase.instance.client.auth.currentUser!.id}/images/${DateTime.now().millisecondsSinceEpoch}_$fileName';
      await _chatRepository.uploadFile('chat-media', storagePath, file);
      await _chatRepository.sendMessage(conversationId: widget.conversationId, content: caption ?? '', type: 'image', storagePath: storagePath, fileName: fileName, fileSize: await file.length(), mimeType: 'image/jpeg');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }
  }

  void _showMessageMenu(Message message, bool isMe) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).cardTheme.color, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        padding: const EdgeInsets.only(top: 12, bottom: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            _buildReactionsRow(message),
            const Divider(),
            _buildMenuItem(Icons.reply_rounded, 'Reply', () { Navigator.pop(context); setState(() { _replyToMessage = message; _editingMessage = null; }); _focusNode.requestFocus(); }),
            if (isMe && message.messageType == 'text' && message.deletedAt == null)
              _buildMenuItem(Icons.edit_rounded, 'Edit', () { Navigator.pop(context); setState(() { _editingMessage = message; _replyToMessage = null; _messageController.text = message.content; }); _focusNode.requestFocus(); }),
            _buildMenuItem(Icons.copy_rounded, 'Copy', () { Navigator.pop(context); }),
            if (isMe && message.deletedAt == null)
              _buildMenuItem(Icons.delete_forever_rounded, 'Delete', () { Navigator.pop(context); _chatRepository.deleteMessageForEveryone(message.id); }, color: AppColors.error),
          ],
        ),
      ),
    );
  }

  Widget _buildReactionsRow(Message message) {
    final reactions = ['❤️', '😂', '👍', '😮', '😢', '🔥'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: reactions.map((r) => GestureDetector(onTap: () { Navigator.pop(context); _chatRepository.addReaction(message.id, r); }, child: Text(r, style: const TextStyle(fontSize: 30)))).toList(),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(leading: Icon(icon, color: color, size: 22), title: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)), onTap: onTap);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isLoading && !_isFriends) return _buildBlockedState(isDark);

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF7F8FA),
      appBar: _isSearching ? _buildSearchAppBar() : _buildDefaultAppBar(isDark),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(bottom: 24, top: 12),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == sb.Supabase.instance.client.auth.currentUser?.id;
                    bool showDate = index == messages.length - 1 || !_isSameDay(message.createdAt, messages[index + 1].createdAt);

                    return Column(
                      children: [
                        if (showDate) _buildDateSeparator(message.createdAt),
                        MessageBubble(
                          message: message,
                          isMe: isMe,
                          isGroup: _conversation?.type == 'group',
                          onLongPress: () => _showMessageMenu(message, isMe),
                          getMediaUrl: _chatRepository.getMediaUrl,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (_replyToMessage != null || _editingMessage != null) _buildActiveContextPreview(isDark),
          _buildComposer(isDark),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime d1, DateTime d2) => d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;

  Widget _buildDateSeparator(DateTime date) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Text(DateFormatter.formatChatDate(date.toLocal()), style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  AppBar _buildDefaultAppBar(bool isDark) {
    final isGroup = _conversation?.type == 'group';
    return AppBar(
      titleSpacing: 0,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18), onPressed: () => context.pop()),
      title: _isLoading ? const Text('Loading...') : InkWell(
        onTap: () => isGroup ? context.push('/group-details/${widget.conversationId}') : context.push('/user/${_otherParticipant?.id}'),
        child: Row(
          children: [
            AppAvatar(imageUrl: isGroup ? _conversation?.groupAvatarUrl : _otherParticipant?.avatarUrl, initials: isGroup ? _conversation?.groupName : _otherParticipant?.fullName, size: 42, showOnlineIndicator: !isGroup && (_otherParticipant?.isOnline ?? false)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isGroup ? (_conversation?.groupName ?? 'Group') : (_otherParticipant?.fullName ?? 'User'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                  Text(
                    _typingUser.isNotEmpty ? 'typing...' : (isGroup ? '${_conversation?.members?.length ?? 0} members' : DateFormatter.formatLastSeen(_otherParticipant?.lastSeen, _otherParticipant?.isOnline ?? false)),
                    style: TextStyle(fontSize: 11, color: _typingUser.isNotEmpty || (!isGroup && (_otherParticipant?.isOnline ?? false)) ? AppColors.primary : Colors.grey, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!isGroup) IconButton(icon: const Icon(Icons.call_rounded, size: 20, color: AppColors.primary), onPressed: _startVoiceCall),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert_rounded),
          onSelected: (v) { if (v == 'search') setState(() => _isSearching = true); },
          itemBuilder: (context) => [const PopupMenuItem(value: 'search', child: Text('Search')), const PopupMenuItem(value: 'clear', child: Text('Clear Chat'))],
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  AppBar _buildSearchAppBar() {
    return AppBar(
      leading: IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _isSearching = false)),
      title: TextField(controller: _searchController, autofocus: true, decoration: const InputDecoration(hintText: 'Search messages...', border: InputBorder.none, filled: false)),
    );
  }

  Widget _buildActiveContextPreview(bool isDark) {
    final isEditing = _editingMessage != null;
    final msg = isEditing ? _editingMessage! : _replyToMessage!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF1C2128) : Colors.white, border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.1)))),
      child: Row(
        children: [
          Container(width: 4, height: 32, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(isEditing ? 'Edit Message' : 'Reply to ${_otherParticipant?.fullName ?? 'User'}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: AppColors.primary, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text(msg.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
          ])),
          IconButton(icon: const Icon(Icons.close_rounded, size: 18), onPressed: () => setState(() { _replyToMessage = null; _editingMessage = null; if (isEditing) _messageController.clear(); })),
        ],
      ),
    );
  }

  Widget _buildComposer(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 12, 8, MediaQuery.of(context).padding.bottom + 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          IconButton(icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.auto_awesome_rounded, color: AppColors.secondary, size: 22)), onPressed: _improveWithAI),
          IconButton(icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 22)), onPressed: _showAttachmentSheet),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade200),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _focusNode,
                maxLines: 5,
                minLines: 1,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                decoration: const InputDecoration(hintText: 'Message...', border: InputBorder.none, filled: false, contentPadding: EdgeInsets.symmetric(vertical: 10)),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: _isInputEmpty ? null : _sendMessage,
            icon: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: _isInputEmpty ? Colors.grey.shade300 : AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlockedState(bool isDark) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.lock_person_rounded, size: 64, color: Colors.grey),
        const SizedBox(height: 24),
        const Text("You're no longer friends.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        const SizedBox(height: 32),
        AppButton(text: 'Back', width: 120, onPressed: () => context.pop()),
      ])),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.forum_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.2)),
      const SizedBox(height: 16),
      const Text('No messages yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w700)),
    ]));
  }
}

class _ImagePreviewDialog extends StatefulWidget {
  final File imageFile;
  final Function(String?) onSend;
  const _ImagePreviewDialog({required this.imageFile, required this.onSend});
  @override
  State<_ImagePreviewDialog> createState() => _ImagePreviewDialogState();
}

class _ImagePreviewDialogState extends State<_ImagePreviewDialog> {
  final _captionController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Colors.black, body: Column(children: [
      Expanded(child: Center(child: Image.file(widget.imageFile))),
      Container(padding: const EdgeInsets.all(20), color: AppColors.surfaceDark, child: SafeArea(child: Row(children: [
        Expanded(child: TextField(controller: _captionController, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'Add a caption...', hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none, filled: false))),
        const SizedBox(width: 16),
        FloatingActionButton(onPressed: () { Navigator.pop(context); widget.onSend(_captionController.text.trim()); }, backgroundColor: AppColors.primary, child: const Icon(Icons.send_rounded)),
      ]))),
    ]));
  }
}
