import '../models/message_model.dart';
import '../../../auth/models/profile_model.dart';

class ConversationPreferences {
  final bool isPinned;
  final bool isArchived;
  final bool isMuted;
  final bool isDeleted;
  final DateTime? lastReadAt;

  ConversationPreferences({
    this.isPinned = false,
    this.isArchived = false,
    this.isMuted = false,
    this.isDeleted = false,
    this.lastReadAt,
  });

  factory ConversationPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) return ConversationPreferences();
    return ConversationPreferences(
      isPinned: json['is_pinned'] ?? false,
      isArchived: json['is_archived'] ?? false,
      isMuted: json['is_muted'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      lastReadAt: json['last_read_at'] != null ? DateTime.parse(json['last_read_at']) : null,
    );
  }
}

class Conversation {
  final String id;
  final String type;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Profile>? members;
  final Message? latestMessage;
  final ConversationPreferences? preferences;

  Conversation({
    required this.id,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.members,
    this.latestMessage,
    this.preferences,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    List<Profile> membersList = [];
    if (json['members'] != null) {
      membersList = (json['members'] as List).map((m) {
        return Profile.fromJson(m['profile']);
      }).toList();
    }

    return Conversation(
      id: json['id'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      members: membersList,
      latestMessage: json['latest_message'] != null ? Message.fromJson(json['latest_message']) : null,
      preferences: ConversationPreferences.fromJson(json['preferences']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
