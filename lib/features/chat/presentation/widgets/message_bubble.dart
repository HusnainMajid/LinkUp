import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/message_model.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final bool isMe;
  final VoidCallback? onLongPress;
  final Function(Message)? onReplyTap;
  final Future<String> Function(String)? getMediaUrl;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onLongPress,
    this.onReplyTap,
    this.getMediaUrl,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final time = DateFormat('h:mm a').format(message.createdAt.toLocal());

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onLongPress: onLongPress,
            child: Container(
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
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.replyToMessageId != null && message.repliedMessage != null)
                      _buildReplyPreview(isDark),
                    
                    if (message.messageType == 'image')
                      _buildImageContent()
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
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (message.editedAt != null && message.deletedAt == null)
                            const Padding(
                              padding: EdgeInsets.only(right: 4),
                              child: Text(
                                'edited',
                                style: TextStyle(color: Colors.white60, fontSize: 10, fontStyle: FontStyle.italic),
                              ),
                            ),
                          Text(
                            time,
                            style: TextStyle(
                              color: (isMe || isDark ? Colors.white : Colors.black54).withValues(alpha: 0.6),
                              fontSize: 10,
                            ),
                          ),
                          if (isMe) ...[
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
    );
  }

  Widget _buildReplyPreview(bool isDark) {
    final replied = message.repliedMessage!;
    return GestureDetector(
      onTap: () => onReplyTap?.call(replied),
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reply',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              replied.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isMe || isDark ? Colors.white70 : Colors.black54,
                fontSize: 12,
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
            height: 200,
            width: double.infinity,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return CachedNetworkImage(
          imageUrl: snapshot.data ?? '',
          fit: BoxFit.cover,
          placeholder: (context, url) => const SizedBox(
            height: 200,
            width: double.infinity,
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          ),
          errorWidget: (context, url, error) => const Icon(Icons.error),
        );
      },
    );
  }

  Widget _buildStatusIcon() {
    if (message.readAt != null) {
      return const Icon(Icons.done_all_rounded, size: 14, color: Colors.blueAccent);
    } else if (message.deliveredAt != null) {
      return const Icon(Icons.done_all_rounded, size: 14, color: Colors.white60);
    } else {
      return const Icon(Icons.check_rounded, size: 14, color: Colors.white60);
    }
  }

  Widget _buildReactions(bool isDark) {
    final reactionMap = <String, int>{};
    for (var r in message.reactions!) {
      reactionMap[r.reaction] = (reactionMap[r.reaction] ?? 0) + 1;
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 4,
        children: reactionMap.entries.map((e) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e.key, style: const TextStyle(fontSize: 12)),
                if (e.value > 1) ...[
                  const SizedBox(width: 2),
                  Text(
                    e.value.toString(),
                    style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black54),
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
