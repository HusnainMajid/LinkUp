import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notification_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Handle background messages
  debugPrint('Handling a background message: ${message.messageId}');
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _activeConversationId;

  Future<void> initialize() async {
    // 1. Initialize Local Notifications for Foreground
    const AndroidInitializationSettings androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidInit);
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null) {
          NotificationRouter.handlePayload(response.payload!);
        }
      },
    );

    // 2. Create Android Notification Channel
    if (Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'linkup_messages',
        'LinkUp Messages',
        description: 'Notifications for new messages and friend requests',
        importance: Importance.max,
      );

      final androidPlugin = _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(channel);
      }
    }

    // 3. Request Permissions
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 4. Set Background Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 5. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _handleForegroundMessage(message);
    });

    // 6. Handle Notification Taps (Background/Terminated)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      NotificationRouter.handleRemoteMessage(message);
    });

    // 7. Check for Initial Message (Terminated state)
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // Delay slightly to ensure app is ready
      Future.delayed(const Duration(seconds: 1), () {
        NotificationRouter.handleRemoteMessage(initialMessage);
      });
    }

    // 8. Handle Token Refresh
    _fcm.onTokenRefresh.listen((token) {
      _saveTokenToSupabase(token);
    });

    // 9. Initial Token Save
    final token = await _fcm.getToken();
    if (token != null) {
      _saveTokenToSupabase(token);
    }
  }

  void setActiveConversation(String? conversationId) {
    _activeConversationId = conversationId;
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final type = message.data['type'];
    final conversationId = message.data['conversation_id'];

    // Don't show notification if user is already in the chat
    if (type == 'message' && conversationId == _activeConversationId) {
      return;
    }

    // Show local notification
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'linkup_messages',
      'LinkUp Messages',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'New Message',
      message.notification?.body ?? '',
      platformDetails,
      payload: message.data.toString(),
    );
  }

  Future<void> _saveTokenToSupabase(String token) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client.from('user_devices').upsert({
        'user_id': user.id,
        'fcm_token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id, fcm_token');
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  Future<void> removeToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final token = await _fcm.getToken();
    if (token == null) return;

    try {
      await Supabase.instance.client
          .from('user_devices')
          .delete()
          .match({'user_id': user.id, 'fcm_token': token});
    } catch (e) {
      debugPrint('Error removing FCM token: $e');
    }
  }
}
