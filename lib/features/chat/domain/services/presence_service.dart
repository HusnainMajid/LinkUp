import 'dart:async';
import 'package:flutter/material.dart';
import '../../data/repositories/chat_repository.dart';

class PresenceService with WidgetsBindingObserver {
  static final PresenceService _instance = PresenceService._internal();
  factory PresenceService() => _instance;
  PresenceService._internal();

  final _chatRepository = ChatRepository();
  Timer? _heartbeatTimer;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;
    WidgetsBinding.instance.addObserver(this);
    _updatePresence(true);
    _startHeartbeat();
    _isInitialized = true;
  }

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _updatePresence(true);
    });
  }

  void _updatePresence(bool isOnline) {
    _chatRepository.updatePresence(isOnline);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _updatePresence(true);
      _startHeartbeat();
    } else {
      _updatePresence(false);
      _heartbeatTimer?.cancel();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeatTimer?.cancel();
    _updatePresence(false);
    _isInitialized = false;
  }
}
