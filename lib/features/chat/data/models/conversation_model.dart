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
  final String? groupName;
  final String? groupAvatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<Profile>? members;
  final Map<String, String>? roles; // userId -> role
  final Message? latestMessage;
  final ConversationPreferences? preferences;
  final int unreadCount;

  Conversation({
    required this.id,
    required this.type,
    this.groupName,
    this.groupAvatarUrl,
    required this.createdAt,
    required this.updatedAt,
    this.members,
    this.roles,
    this.latestMessage,
    this.preferences,
    this.unreadCount = 0,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    List<Profile> membersList = [];
    Map<String, String> rolesMap = {};
    if (json['members'] != null) {
      membersList = (json['members'] as List).map((m) {
        final profile = Profile.fromJson(m['profile']);
        rolesMap[profile.id] = m['role'] ?? 'MEMBER';
        return profile;
      }).toList();
    }

    return Conversation(
      id: json['id'],
      type: json['type'],
      groupName: json['group_name'],
      groupAvatarUrl: json['group_avatar_url'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      members: membersList,
      roles: rolesMap,
      latestMessage: json['latest_message'] != null ? Message.fromJson(json['latest_message']) : null,
      preferences: ConversationPreferences.fromJson(json['preferences']),
      unreadCount: json['unread_count'] ?? 0,
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
