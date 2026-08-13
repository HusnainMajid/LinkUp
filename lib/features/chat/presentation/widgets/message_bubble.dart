import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final bool isGroup;
  final VoidCallback? onLongPress;
  final Function(Message)? onReplyTap;
  final Future<String> Function(String)? getMediaUrl;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.isGroup = false,
    this.onLongPress,
    this.onReplyTap,
    this.getMediaUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('h:mm a').format(message.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onLongPress: onLongPress,
              child: Container(
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                decoration: BoxDecoration(
                  color: isMe 
                    ? AppColors.primary
                    : (isDark ? AppColors.cardDark : Colors.white),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.replyToMessageId != null && message.repliedMessage != null)
                        _buildReplyPreview(isDark),
                      
                      if (isGroup && !isMe && message.deletedAt == null)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                          child: Text(
                            message.senderName ?? 'User',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),

                      if (message.messageType == 'image')
                        _buildImageContent()
                      else if (message.deletedAt != null)
                        _buildDeletedContent(isDark)
                      else
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
                          child: Text(
                            message.content,
                            style: TextStyle(
                              color: isMe ? Colors.white : (isDark ? Colors.white : AppColors.textPrimary),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              height: 1.4,
                            ),
                          ),
                        ),
                      
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 10, 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (message.editedAt != null && message.deletedAt == null)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Text(
                                  'edited',
                                  style: TextStyle(
                                    color: (isMe ? Colors.white60 : Colors.grey).withValues(alpha: 0.6), 
                                    fontSize: 9, 
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            Text(
                              time,
                              style: TextStyle(
                                color: (isMe ? Colors.white60 : Colors.grey).withValues(alpha: 0.6),
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isMe && message.deletedAt == null) ...[
                              const SizedBox(width: 4),
                              _buildStatusIcon(),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (message.reactions != null && message.reactions!.isNotEmpty)
              _buildReactions(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDeletedContent(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.block_rounded,
            size: 14,
            color: (isMe ? Colors.white60 : Colors.grey).withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'This message was deleted',
            style: TextStyle(
              color: (isMe ? Colors.white60 : Colors.grey).withValues(alpha: 0.6),
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyPreview(bool isDark) {
    final replied = message.repliedMessage!;
    return GestureDetector(
      onTap: () => onReplyTap?.call(replied),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(10, 10, 10, 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? Colors.black.withValues(alpha: 0.1) : (isDark ? Colors.black.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: isMe ? Colors.white60 : AppColors.primary, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reply',
              style: TextStyle(
                color: isMe ? Colors.white : AppColors.primary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              replied.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isMe ? Colors.white70 : (isDark ? Colors.white70 : AppColors.textSecondary),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (message.storagePath == null) return const SizedBox.shrink();
    return FutureBuilder<String>(
      future: getMediaUrl?.call(message.storagePath!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            width: 240,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
          );
        }
        return Padding(
          padding: const EdgeInsets.all(6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: snapshot.data ?? '',
              fit: BoxFit.cover,
              width: 240,
              placeholder: (context, url) => Container(
                height: 180,
                width: 240,
                color: Colors.grey.withValues(alpha: 0.1),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusIcon() {
    if (message.readAt != null) {
      return const Icon(Icons.done_all_rounded, size: 16, color: Color(0xFF40C4FF));
    } else if (message.deliveredAt != null) {
      return const Icon(Icons.done_all_rounded, size: 16, color: Colors.white60);
    } else {
      return const Icon(Icons.check_rounded, size: 16, color: Colors.white60);
    }
  }

  Widget _buildReactions(bool isDark) {
    final reactionMap = <String, int>{};
    for (var r in message.reactions!) {
      reactionMap[r.reaction] = (reactionMap[r.reaction] ?? 0) + 1;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4, left: 4, right: 4),
      child: Wrap(
        spacing: 4,
        children: reactionMap.entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.key, style: const TextStyle(fontSize: 14)),
                if (e.value > 1) ...[
                  const SizedBox(width: 4),
                  Text(
                    e.value.toString(),
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: isDark ? Colors.white70 : Colors.black87),
                  ),
                ],
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
