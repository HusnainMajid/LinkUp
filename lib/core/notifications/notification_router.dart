import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../routing/app_router.dart';

class NotificationRouter {
  static void handleRemoteMessage(RemoteMessage message) {
    _navigate(message.data);
  }

  static void handlePayload(String payload) {
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      _navigate(data);
    } catch (e) {
      // Fallback for old/crude payloads if necessary
      final data = _parsePayload(payload);
      _navigate(data);
    }
  }

  static void _navigate(Map<String, dynamic> data) {
    final type = data['type'];
    final id = data['conversation_id'] ?? data['sender_id'];

    if (type == 'message' && id != null) {
      AppRouter.router.push('/chat/$id');
    } else if (type == 'voice_call' && id != null) {
      AppRouter.router.push('/incoming-call', extra: data);
    } else if (type == 'friend_request') {
      AppRouter.router.push('/friend-requests');
    } else if (type == 'friend_request_accepted' && id != null) {
      AppRouter.router.push('/user/$id');
    }
  }

  static Map<String, dynamic> _parsePayload(String payload) {
    // Crude parsing for stringified map {key: value, ...}
    final map = <String, dynamic>{};
    payload = payload.replaceAll('{', '').replaceAll('}', '');
    final parts = payload.split(',');
    for (var part in parts) {
      final kv = part.split(':');
      if (kv.length == 2) {
        map[kv[0].trim()] = kv[1].trim();
      }
    }
    return map;
  }
}
