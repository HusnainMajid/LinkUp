import 'message_reaction_model.dart';

class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  final String? replyToMessageId;
  final Message? repliedMessage;
  final List<MessageReaction>? reactions;
  final String? storagePath;
  final String? fileName;
  final int? fileSize;
  final String? mimeType;

  Message({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.content,
    required this.messageType,
    required this.createdAt,
    this.updatedAt,
    this.editedAt,
    this.deletedAt,
    this.deliveredAt,
    this.readAt,
    this.replyToMessageId,
    this.repliedMessage,
    this.reactions,
    this.storagePath,
    this.fileName,
    this.fileSize,
    this.mimeType,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] ?? '',
      conversationId: json['conversation_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      content: json['content'] ?? '',
      messageType: json['message_type'] ?? 'text',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      editedAt: json['edited_at'] != null ? DateTime.parse(json['edited_at']) : null,
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      readAt: json['read_at'] != null ? DateTime.parse(json['read_at']) : null,
      replyToMessageId: json['reply_to_message_id'],
      repliedMessage: json['replied_message'] != null 
          ? Message.fromJson(json['replied_message']) 
          : null,
      reactions: json['reactions'] != null 
          ? (json['reactions'] as List).map((r) => MessageReaction.fromJson(r)).toList()
          : null,
      storagePath: json['storage_path'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      mimeType: json['mime_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'reply_to_message_id': replyToMessageId,
      'storage_path': storagePath,
      'file_name': fileName,
      'file_size': fileSize,
      'mime_type': mimeType,
      'edited_at': editedAt?.toIso8601String(),
      'delivered_at': deliveredAt?.toIso8601String(),
      'read_at': readAt?.toIso8601String(),
    };
  }

  Message copyWith({
    String? content,
    DateTime? editedAt,
    DateTime? deletedAt,
    DateTime? deliveredAt,
    DateTime? readAt,
    List<MessageReaction>? reactions,
  }) {
    return Message(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      content: content ?? this.content,
      messageType: messageType,
      createdAt: createdAt,
      updatedAt: updatedAt,
      editedAt: editedAt ?? this.editedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      deliveredAt: deliveredAt ?? this.deliveredAt,
      readAt: readAt ?? this.readAt,
      replyToMessageId: replyToMessageId,
      repliedMessage: repliedMessage,
      reactions: reactions ?? this.reactions,
      storagePath: storagePath,
      fileName: fileName,
      fileSize: fileSize,
      mimeType: mimeType,
    );
  }
}
