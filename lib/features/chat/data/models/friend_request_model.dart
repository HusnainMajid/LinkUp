import '../../../../features/auth/models/profile_model.dart';

enum FriendStatus {
  none,
  pendingSent,
  pendingReceived,
  friends,
  rejected,
}

class FriendRequest {
  final String id;
  final String senderId;
  final String receiverId;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Profile? senderProfile;
  final Profile? receiverProfile;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.senderProfile,
    this.receiverProfile,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id'],
      senderId: json['sender_id'],
      receiverId: json['receiver_id'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      senderProfile: json['sender_profile'] != null ? Profile.fromJson(json['sender_profile']) : null,
      receiverProfile: json['receiver_profile'] != null ? Profile.fromJson(json['receiver_profile']) : null,
    );
  }
}
