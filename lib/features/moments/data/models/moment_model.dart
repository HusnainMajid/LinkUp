import '../../../auth/models/profile_model.dart';

class Moment {
  final String id;
  final String userId;
  final String? content;
  final String? imageUrl;
  final String type; // 'text' or 'image'
  final String? backgroundColor;
  final DateTime createdAt;
  final DateTime expiresAt;
  final DateTime updatedAt;
  final Profile? user;
  final int viewerCount;
  final bool isViewed;

  Moment({
    required this.id,
    required this.userId,
    this.content,
    this.imageUrl,
    required this.type,
    this.backgroundColor,
    required this.createdAt,
    required this.expiresAt,
    required this.updatedAt,
    this.user,
    this.viewerCount = 0,
    this.isViewed = false,
  });

  factory Moment.fromJson(Map<String, dynamic> json) {
    return Moment(
      id: json['id'],
      userId: json['user_id'],
      content: json['content'],
      imageUrl: json['image_url'],
      type: json['type'],
      backgroundColor: json['background_color'],
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: DateTime.parse(json['expires_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      user: json['user'] != null ? Profile.fromJson(json['user']) : null,
      viewerCount: json['viewer_count'] ?? 0,
      isViewed: json['is_viewed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'content': content,
      'image_url': imageUrl,
      'type': type,
      'background_color': backgroundColor,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class MomentView {
  final String id;
  final String momentId;
  final String viewerId;
  final DateTime viewedAt;
  final Profile? viewer;

  MomentView({
    required this.id,
    required this.momentId,
    required this.viewerId,
    required this.viewedAt,
    this.viewer,
  });

  factory MomentView.fromJson(Map<String, dynamic> json) {
    return MomentView(
      id: json['id'],
      momentId: json['moment_id'],
      viewerId: json['viewer_id'],
      viewedAt: DateTime.parse(json['viewed_at']),
      viewer: json['viewer'] != null ? Profile.fromJson(json['viewer']) : null,
    );
  }
}
