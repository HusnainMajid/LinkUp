class UserSettings {
  final String userId;
  final String themeMode;
  final bool showOnlineStatus;
  final bool showLastSeen;
  final bool allowDiscovery;
  final bool notifyMessages;
  final bool notifyCalls;
  final bool notifyMoments;
  final DateTime updatedAt;

  UserSettings({
    required this.userId,
    required this.themeMode,
    required this.showOnlineStatus,
    required this.showLastSeen,
    required this.allowDiscovery,
    required this.notifyMessages,
    required this.notifyCalls,
    required this.notifyMoments,
    required this.updatedAt,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      userId: json['user_id'],
      themeMode: json['theme_mode'] ?? 'system',
      showOnlineStatus: json['show_online_status'] ?? true,
      showLastSeen: json['show_last_seen'] ?? true,
      allowDiscovery: json['allow_discovery'] ?? true,
      notifyMessages: json['notify_messages'] ?? true,
      notifyCalls: json['notify_calls'] ?? true,
      notifyMoments: json['notify_moments'] ?? true,
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'theme_mode': themeMode,
      'show_online_status': showOnlineStatus,
      'show_last_seen': showLastSeen,
      'allow_discovery': allowDiscovery,
      'notify_messages': notifyMessages,
      'notify_calls': notifyCalls,
      'notify_moments': notifyMoments,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserSettings copyWith({
    String? userId,
    String? themeMode,
    bool? showOnlineStatus,
    bool? showLastSeen,
    bool? allowDiscovery,
    bool? notifyMessages,
    bool? notifyCalls,
    bool? notifyMoments,
    DateTime? updatedAt,
  }) {
    return UserSettings(
      userId: userId ?? this.userId,
      themeMode: themeMode ?? this.themeMode,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      showLastSeen: showLastSeen ?? this.showLastSeen,
      allowDiscovery: allowDiscovery ?? this.allowDiscovery,
      notifyMessages: notifyMessages ?? this.notifyMessages,
      notifyCalls: notifyCalls ?? this.notifyCalls,
      notifyMoments: notifyMoments ?? this.notifyMoments,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
