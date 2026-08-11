class Message {
  final String id;
  final String conversationId;
  final String senderId;
  final String content;
  final String messageType;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? deletedAt;
  final String? replyToMessageId;
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
    this.deletedAt,
    this.replyToMessageId,
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
      deletedAt: json['deleted_at'] != null ? DateTime.parse(json['deleted_at']) : null,
      replyToMessageId: json['reply_to_message_id'],
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
    };
  }
}
