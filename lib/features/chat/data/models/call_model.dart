class Call {
  final String id;
  final String callerId;
  final String receiverId;
  final String status;
  final String type;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final int? duration;

  Call({
    required this.id,
    required this.callerId,
    required this.receiverId,
    required this.status,
    required this.type,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.duration,
  });

  factory Call.fromJson(Map<String, dynamic> json) {
    return Call(
      id: json['id'],
      callerId: json['caller_id'],
      receiverId: json['receiver_id'],
      status: json['status'],
      type: json['type'],
      createdAt: DateTime.parse(json['created_at']),
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      endedAt: json['ended_at'] != null ? DateTime.parse(json['ended_at']) : null,
      duration: json['duration'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caller_id': callerId,
      'receiver_id': receiverId,
      'status': status,
      'type': type,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'ended_at': endedAt?.toIso8601String(),
      'duration': duration,
    };
  }
}
