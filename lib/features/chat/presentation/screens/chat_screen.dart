import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:path/path.dart' as path;
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/models/message_model.dart';
import '../../data/repositories/chat_repository.dart';

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
  Profile? _otherParticipant;
  bool _isLoading = true;
  bool _isFriends = true;
  bool _isInputEmpty = true;
  Stream<List<Message>>? _messageStream;

  @override
  void initState() {
    super.initState();
    _loadConversationDetails();
    _messageController.addListener(_onTextChanged);
    _messageStream = _chatRepository.subscribeToMessages(widget.conversationId);
  }

  void _onTextChanged() {
    final isEmpty = _messageController.text.trim().isEmpty;
    if (isEmpty != _isInputEmpty) {
      setState(() {
        _isInputEmpty = isEmpty;
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
        // Mark conversation as read
        _chatRepository.markAsRead(widget.conversationId);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();
    try {
      await _chatRepository.sendMessage(
        conversationId: widget.conversationId,
        content: content,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message.')),
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
    _messageController.dispose();
    _scrollController.dispose();
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
                  label: 'Photo',
                  subtitle: 'Choose from gallery',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                const SizedBox(width: 16),
                _buildAttachmentOption(
                  icon: Icons.description_rounded,
                  label: 'File',
                  subtitle: 'Send a document',
                  color: Colors.orange,
                  onTap: () {
                    Navigator.pop(context);
                    _showComingSoon('File sharing');
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

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
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

      await sb.Supabase.instance.client.storage
          .from('chat-media')
          .upload(storagePath, file);

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (!_isLoading && !_isFriends) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: AppBar(title: const Text('Chat')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_person_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.2)),
                const SizedBox(height: 24),
                const Text(
                  "You're no longer friends with this user.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Conversation is locked until you become friends again.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 32),
                AppButton(
                  text: 'Back',
                  onPressed: () => context.pop(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: _isLoading 
          ? const Text('Loading...') 
          : Row(
              children: [
                AppAvatar(
                  imageUrl: _otherParticipant?.avatarUrl,
                  initials: _otherParticipant?.fullName ?? 'U',
                  size: 40,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _otherParticipant?.fullName ?? 'User',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _otherParticipant?.bio != null && _otherParticipant!.bio!.isNotEmpty
                          ? _otherParticipant!.bio!
                          : (_otherParticipant?.username != null ? '@${_otherParticipant!.username}' : 'LinkUp'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12, 
                          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        actions: [
          IconButton(
            icon: const Icon(Icons.videocam_outlined, size: 24), 
            onPressed: () => _showComingSoon('Video calling'),
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined, size: 22), 
            onPressed: () => _showComingSoon('Voice calling'),
          ),
          _buildOverflowMenu(),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messageStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return _buildEmptyState();
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == sb.Supabase.instance.client.auth.currentUser?.id;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildComposer(isDark),
        ],
      ),
    );
  }

  Widget _buildOverflowMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (value) {
        switch (value) {
          case 'search':
            _showComingSoon('Search in conversation');
            break;
          case 'clear':
            _confirmClearChat();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'search', child: Text('Search in conversation')),
        const PopupMenuItem(value: 'profile', child: Text('View profile')),
        const PopupMenuItem(value: 'media', child: Text('Media, links & files')),
        const PopupMenuItem(value: 'mute', child: Text('Mute notifications')),
        const PopupMenuItem(value: 'clear', child: Text('Clear chat')),
        const PopupMenuItem(value: 'delete', child: Text('Delete conversation')),
        const PopupMenuItem(value: 'block', child: Text('Block user')),
        const PopupMenuItem(value: 'report', child: Text('Report user')),
      ],
    );
  }

  Future<void> _confirmClearChat() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear chat?'),
        content: const Text('This will remove your messages from this conversation.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Clear', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _chatRepository.clearChat(widget.conversationId);
    }
  }

  Widget _buildMessageBubble(Message message, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final localTime = message.createdAt.toLocal();
    final time = DateFormat('h:mm a').format(localTime);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe 
            ? AppColors.primary.withValues(alpha: isDark ? 0.9 : 1.0)
            : (isDark ? AppColors.cardDark : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (message.messageType == 'image')
              _buildImageContent(message)
            else if (message.messageType == 'file')
              _buildFileContent(message, isMe)
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  message.content,
                  style: TextStyle(
                    color: isMe || isDark ? Colors.white : Colors.black87,
                    fontSize: 15,
                  ),
                ),
              ),
            
            Padding(
              padding: const EdgeInsets.only(right: 12, bottom: 8, left: 16),
              child: Text(
                time,
                style: TextStyle(
                  color: (isMe || isDark ? Colors.white : Colors.black54).withValues(alpha: 0.6),
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent(Message message) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            if (message.storagePath != null) {
              _openImageFullscreen(message.storagePath!);
            }
          },
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: FutureBuilder<String>(
              future: _chatRepository.getMediaUrl(message.storagePath!),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                if (snapshot.hasError || !snapshot.hasData) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey)),
                  );
                }
                return CachedNetworkImage(
                  imageUrl: snapshot.data!,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                );
              },
            ),
          ),
        ),
        if (message.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              message.content,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildFileContent(Message message, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sizeStr = message.fileSize != null 
        ? '${(message.fileSize! / 1024 / 1024).toStringAsFixed(2)} MB' 
        : 'Unknown size';

    return InkWell(
      onTap: () => _showComingSoon('File viewing'),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.description_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'File',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isMe || isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    sizeStr,
                    style: TextStyle(
                      color: (isMe || isDark ? Colors.white : Colors.black54).withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.download_rounded, 
              size: 20, 
              color: (isMe || isDark ? Colors.white : Colors.black54).withValues(alpha: 0.6)
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppAvatar(
            imageUrl: _otherParticipant?.avatarUrl,
            initials: _otherParticipant?.fullName ?? 'U',
            size: 80,
          ),
          const SizedBox(height: 24),
          Text(
            'Start your conversation',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Send your first message to start the conversation with ${_otherParticipant?.fullName ?? 'your friend'}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary, 
                fontSize: 13,
                height: 1.5
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.elevatedDark : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.add_rounded, color: AppColors.primary, size: 24),
                onPressed: _showAttachmentSheet,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.elevatedDark : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(fontSize: 15),
                  maxLines: 5,
                  minLines: 1,
                  decoration: const InputDecoration(
                    hintText: 'Message...',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _isInputEmpty 
                  ? (isDark ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade200)
                  : AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_upward_rounded, 
                  color: _isInputEmpty ? Colors.grey : Colors.white, 
                  size: 22
                ),
                onPressed: _isInputEmpty ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openImageFullscreen(String storagePath) async {
    final url = await _chatRepository.getMediaUrl(storagePath);
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => _ImageFullscreenView(imageUrl: url),
        ),
      );
    }
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Image.file(widget.imageFile),
            ),
          ),
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
                      decoration: InputDecoration(
                        hintText: 'Add a caption...',
                        hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.6)),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onSend(_captionController.text.trim());
                    },
                    backgroundColor: AppColors.primary,
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
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

class _ImageFullscreenView extends StatelessWidget {
  final String imageUrl;
  const _ImageFullscreenView({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            placeholder: (context, url) => const CircularProgressIndicator(),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      ),
    );
  }
}
