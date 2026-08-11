import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:path/path.dart' as path;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  const ChatScreen({super.key, required this.conversationId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _chatRepository = ChatRepository();
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  
  Profile? _otherParticipant;
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
    _presenceSubscription = _chatRepository.subscribeToPresence(widget.conversationId).listen((profiles) {
      if (_otherParticipant != null) {
        final updated = profiles.firstWhere((p) => p.id == _otherParticipant!.id, orElse: () => _otherParticipant!);
        if (mounted) {
          setState(() {
            _otherParticipant = updated;
          });
        }
      }
    });
    _chatRepository.updatePresence(true);
  }

  void _onTextChanged() {
    final isEmpty = _messageController.text.trim().isEmpty;
    if (isEmpty != _isInputEmpty) {
      setState(() {
        _isInputEmpty = isEmpty;
      });
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
      final isFriends = await _chatRepository.isStillFriends(widget.conversationId);
      if (!isFriends) {
        if (mounted) {
          setState(() {
            _isFriends = false;
            _isLoading = false;
          });
        }
        return;
      }

      final conversations = await _chatRepository.getUserConversations();
      final conversation = conversations.firstWhere((c) => c.id == widget.conversationId);
      
      if (mounted) {
        setState(() {
          _otherParticipant = _chatRepository.getOtherParticipant(conversation);
          _isLoading = false;
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    NotificationService().setActiveConversation(null);
    _chatRepository.updatePresence(false);
    _chatRepository.setTypingStatus(widget.conversationId, false);
    _typingSubscription?.cancel();
    _presenceSubscription?.cancel();
    _typingTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    _chatRepository.dispose();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Attach',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                _buildAttachmentOption(
                  icon: Icons.image_rounded,
                  label: 'Gallery',
                  subtitle: 'Pick an image',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(width: 16),
                _buildAttachmentOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  subtitle: 'Take a photo',
                  color: Colors.green,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    
    if (image != null) {
      if (mounted) {
        _showImagePreview(File(image.path));
      }
    }
  }

  void _showImagePreview(File file) {
    showDialog(
      context: context,
      useSafeArea: false,
      builder: (context) => _ImagePreviewDialog(
        imageFile: file,
        onSend: (caption) => _uploadAndSendImage(file, caption),
      ),
    );
  }

  Future<void> _uploadAndSendImage(File file, String? caption) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Uploading image...'), duration: Duration(seconds: 1)),
    );

    try {
      final fileName = path.basename(file.path);
      final currentUserId = sb.Supabase.instance.client.auth.currentUser!.id;
      final storagePath = '${widget.conversationId}/$currentUserId/images/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _chatRepository.uploadFile('chat-media', storagePath, file);

      await _chatRepository.sendMessage(
        conversationId: widget.conversationId,
        content: caption ?? '',
        type: 'image',
        storagePath: storagePath,
        fileName: fileName,
        fileSize: await file.length(),
        mimeType: 'image/jpeg',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Couldn\'t upload image: $e')),
        );
      }
    }
  }

  void _showMessageMenu(Message message, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuReactionRow(message),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.reply_rounded),
              title: const Text('Reply'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _replyToMessage = message);
              },
            ),
            if (isMe && message.messageType == 'text' && message.deletedAt == null)
              ListTile(
                leading: const Icon(Icons.edit_rounded),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _editingMessage = message;
                    _messageController.text = message.content;
                  });
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy_rounded),
              title: const Text('Copy Text'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Copy');
              },
            ),
            if (isMe && message.deletedAt == null)
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppColors.error),
                title: const Text('Delete for Everyone', style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _chatRepository.deleteMessageForEveryone(message.id);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuReactionRow(Message message) {
    final reactions = ['❤️', '😂', '👍', '😮', '😢', '🔥'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: reactions.map((r) => GestureDetector(
          onTap: () {
            Navigator.pop(context);
            _chatRepository.addReaction(message.id, r);
          },
          child: Text(r, style: const TextStyle(fontSize: 28)),
        )).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_isLoading && !_isFriends) {
      return _buildBlockedState(isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: _isSearching ? _buildSearchAppBar(isDark) : _buildDefaultAppBar(isDark),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
                          const SizedBox(height: 16),
                          const Text(
                            'Error loading messages',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please ensure you have executed the migration 007 in Supabase SQL Editor.\n\nError: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) return _buildEmptyState();

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == sb.Supabase.instance.client.auth.currentUser?.id;
                    return MessageBubble(
                      message: message,
                      isMe: isMe,
                      onLongPress: () => _showMessageMenu(message, isMe),
                      getMediaUrl: _chatRepository.getMediaUrl,
                    );
                  },
                );
              },
            ),
          ),
          if (_replyToMessage != null || _editingMessage != null)
            _buildActiveContextPreview(isDark),
          _buildComposer(isDark),
        ],
      ),
    );
  }

  AppBar _buildDefaultAppBar(bool isDark) {
    return AppBar(
      titleSpacing: 0,
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      title: _isLoading 
        ? const Text('Loading...') 
        : Row(
            children: [
              AppAvatar(
                imageUrl: _otherParticipant?.avatarUrl,
                initials: _otherParticipant?.fullName ?? 'U',
                size: 40,
                showOnlineIndicator: _otherParticipant?.isOnline ?? false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _otherParticipant?.fullName ?? 'User',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _typingUser.isNotEmpty 
                        ? 'typing...' 
                        : (_otherParticipant?.isOnline ?? false 
                            ? 'Online' 
                            : (_otherParticipant?.lastSeen != null 
                                ? 'Last seen ${DateFormat('h:mm a').format(_otherParticipant!.lastSeen!)}'
                                : 'Offline')),
                      style: TextStyle(
                        fontSize: 11, 
                        color: _typingUser.isNotEmpty || (_otherParticipant?.isOnline ?? false)
                            ? AppColors.primary 
                            : Colors.grey
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
      actions: [
        IconButton(icon: const Icon(Icons.videocam_outlined), onPressed: () => _showComingSoon('Video call')),
        IconButton(icon: const Icon(Icons.call_outlined, size: 22), onPressed: () => _showComingSoon('Voice call')),
        PopupMenuButton<String>(
          onSelected: (v) {
            if (v == 'search') setState(() => _isSearching = true);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'search', child: Text('Search')),
            const PopupMenuItem(value: 'clear', child: Text('Clear Chat')),
          ],
        ),
      ],
    );
  }

  AppBar _buildSearchAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: () => setState(() => _isSearching = false),
      ),
      title: TextField(
        controller: _searchController,
        autofocus: true,
        decoration: const InputDecoration(hintText: 'Search messages...', border: InputBorder.none),
        onSubmitted: (q) => _showComingSoon('Search functionality'),
      ),
    );
  }

  Widget _buildActiveContextPreview(bool isDark) {
    final isEditing = _editingMessage != null;
    final msg = isEditing ? _editingMessage! : _replyToMessage!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
      child: Row(
        children: [
          Icon(isEditing ? Icons.edit_rounded : Icons.reply_rounded, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Editing message' : 'Replying to ${_otherParticipant?.fullName ?? 'User'}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                ),
                Text(
                  msg.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 20),
            onPressed: () => setState(() {
              _replyToMessage = null;
              _editingMessage = null;
              if (isEditing) _messageController.clear();
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: isDark ? AppColors.surfaceDark : Colors.white),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 28),
              onPressed: _showAttachmentSheet,
            ),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.elevatedDark : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: _messageController,
                  maxLines: 5,
                  minLines: 1,
                  decoration: const InputDecoration(hintText: 'Message...', border: InputBorder.none),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
              onPressed: _isInputEmpty ? null : _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedState(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(title: const Text('Chat')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_person_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 24),
            const Text("You're no longer friends.", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 32),
            AppButton(text: 'Back', onPressed: () => context.pop()),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Text('No messages yet', style: TextStyle(color: Colors.grey.shade500)));
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
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(child: Center(child: Image.file(widget.imageFile))),
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.surfaceDark,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _captionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(hintText: 'Add a caption...', hintStyle: TextStyle(color: Colors.white54), border: InputBorder.none),
                    ),
                  ),
                  FloatingActionButton(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onSend(_captionController.text.trim());
                    },
                    child: const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
