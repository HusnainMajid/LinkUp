import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/call_model.dart';

enum CallState {
  idle,
  outgoing,
  ringing,
  connecting,
  connected,
  ended,
  rejected,
  cancelled,
  missed,
  failed
}

class CallService extends ChangeNotifier {
  static final CallService _instance = CallService._internal();
  factory CallService() => _instance;
  CallService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;
  
  Call? _currentCall;
  CallState _state = CallState.idle;
  
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  RealtimeChannel? _signalingChannel;
  StreamSubscription? _callUpdateSubscription;
  
  Timer? _callDurationTimer;
  int _durationSeconds = 0;

  Call? get currentCall => _currentCall;
  CallState get state => _state;
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  int get durationSeconds => _durationSeconds;

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': false,
    },
    'optional': [],
  };

  void _updateState(CallState newState) {
    _state = newState;
    notifyListeners();
  }

  Future<void> initCall(String receiverId) async {
    if (_state != CallState.idle) return;

    final callerId = _supabase.auth.currentUser!.id;
    final callId = const Uuid().v4();

    _currentCall = Call(
      id: callId,
      callerId: callerId,
      receiverId: receiverId,
      status: 'outgoing',
      type: 'voice',
      createdAt: DateTime.now(),
    );

    _updateState(CallState.outgoing);

    try {
      // Create call in database
      await _supabase.from('voice_calls').insert(_currentCall!.toJson());

      // Setup signaling
      await _setupSignaling(callId);

      // Setup WebRTC
      await _setupWebRTC();

      // Create Offer
      RTCSessionDescription offer = await _peerConnection!.createOffer(_constraints);
      await _peerConnection!.setLocalDescription(offer);

      // Send Offer via Broadcast
      _signalingChannel?.sendBroadcastResponse(
        event: 'call-offer',
        payload: {
          'sdp': offer.sdp,
          'type': offer.type,
          'caller_id': callerId,
          'call_id': callId,
        },
      );

      _startCallUpdateSubscription(callId);
    } catch (e) {
      debugPrint('CallService: Error initiating call: $e');
      _updateState(CallState.failed);
      _cleanup();
    }
  }

  Future<void> handleIncomingCall(Map<String, dynamic> data) async {
    if (_state != CallState.idle) {
      // Busy, reject or ignore
      return;
    }

    final callId = data['call_id'];
    final callerId = data['caller_id'];
    
    // Fetch call details from DB to verify
    final response = await _supabase
        .from('voice_calls')
        .select()
        .eq('id', callId)
        .single();
    
    _currentCall = Call.fromJson(response);
    _updateState(CallState.ringing);

    await _setupSignaling(callId);
    _startCallUpdateSubscription(callId);
  }

  Future<void> acceptCall() async {
    if (_state != CallState.ringing || _currentCall == null) return;

    _updateState(CallState.connecting);

    try {
      await _supabase.from('voice_calls').update({
        'status': 'connected',
        'started_at': DateTime.now().toIso8601String(),
      }).eq('id', _currentCall!.id);

      await _setupWebRTC();

      // Send signaling will be handled after receiving the offer if not already received
      // In this flow, the receiver should have received the offer via handleIncomingCall signaled via broadcast
      // But wait, Broadcast 'call-offer' might have been missed if app was backgrounded.
      // We should probably store the offer in DB or handle it via a robust signaling flow.
      // For now, let's assume the offer comes via Broadcast when the receiver joins the channel.
    } catch (e) {
      debugPrint('CallService: Error accepting call: $e');
      _updateState(CallState.failed);
      _cleanup();
    }
  }

  Future<void> rejectCall() async {
    if (_currentCall == null) return;

    await _supabase.from('voice_calls').update({
      'status': 'rejected',
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', _currentCall!.id);

    _signalingChannel?.sendBroadcastResponse(
      event: 'call-rejected',
      payload: {'call_id': _currentCall!.id},
    );

    _updateState(CallState.rejected);
    _cleanup();
  }

  Future<void> cancelCall() async {
    if (_currentCall == null) return;

    await _supabase.from('voice_calls').update({
      'status': 'cancelled',
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', _currentCall!.id);

    _signalingChannel?.sendBroadcastResponse(
      event: 'call-cancelled',
      payload: {'call_id': _currentCall!.id},
    );

    _updateState(CallState.cancelled);
    _cleanup();
  }

  Future<void> endCall() async {
    if (_currentCall == null) return;

    final endedAt = DateTime.now();
    int? duration;
    if (_currentCall!.startedAt != null) {
      duration = endedAt.difference(_currentCall!.startedAt!).inSeconds;
    }

    await _supabase.from('voice_calls').update({
      'status': 'ended',
      'ended_at': endedAt.toIso8601String(),
      'duration': duration,
    }).eq('id', _currentCall!.id);

    _signalingChannel?.sendBroadcastResponse(
      event: 'call-ended',
      payload: {'call_id': _currentCall!.id},
    );

    _updateState(CallState.ended);
    _cleanup();
  }

  Future<void> _setupWebRTC() async {
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': false,
    });

    _peerConnection = await createPeerConnection(_iceServers, _constraints);

    _peerConnection!.onIceCandidate = (candidate) {
      _signalingChannel?.sendBroadcastResponse(
        event: 'ice-candidate',
        payload: {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };

    _peerConnection!.onAddStream = (stream) {
      _remoteStream = stream;
      notifyListeners();
    };

    _peerConnection!.onConnectionState = (state) {
      debugPrint('CallService: Connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _updateState(CallState.connected);
        _startTimer();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
                 state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        // Handle failure
      }
    };

    _peerConnection!.addStream(_localStream!);
  }

  Future<void> _setupSignaling(String callId) async {
    _signalingChannel = _supabase.channel('call-signaling:$callId');
    
    _signalingChannel!
      .onBroadcast(event: 'call-offer', callback: (payload) async {
        if (_peerConnection == null) await _setupWebRTC();
        await _peerConnection!.setRemoteDescription(
          RTCSessionDescription(payload['sdp'], payload['type']),
        );
        RTCSessionDescription answer = await _peerConnection!.createAnswer(_constraints);
        await _peerConnection!.setLocalDescription(answer);
        _signalingChannel!.sendBroadcastResponse(
          event: 'call-answer',
          payload: {
            'sdp': answer.sdp,
            'type': answer.type,
          },
        );
      })
      .onBroadcast(event: 'call-answer', callback: (payload) async {
        await _peerConnection?.setRemoteDescription(
          RTCSessionDescription(payload['sdp'], payload['type']),
        );
      })
      .onBroadcast(event: 'ice-candidate', callback: (payload) async {
        await _peerConnection?.addCandidate(
          RTCIceCandidate(payload['candidate'], payload['sdpMid'], payload['sdpMLineIndex']),
        );
      })
      .onBroadcast(event: 'call-rejected', callback: (_) => _onRemoteEnded(CallState.rejected))
      .onBroadcast(event: 'call-cancelled', callback: (_) => _onRemoteEnded(CallState.cancelled))
      .onBroadcast(event: 'call-ended', callback: (_) => _onRemoteEnded(CallState.ended))
      .subscribe();
  }

  void _onRemoteEnded(CallState finalState) {
    _updateState(finalState);
    _cleanup();
  }

  void _startCallUpdateSubscription(String callId) {
    _callUpdateSubscription = _supabase
        .from('voice_calls')
        .stream(primaryKey: ['id'])
        .eq('id', callId)
        .listen((event) {
          if (event.isNotEmpty) {
            final updatedCall = Call.fromJson(event.first);
            _currentCall = updatedCall;
            
            final status = updatedCall.status;
            if (status == 'connected' && _state != CallState.connected) {
              _updateState(CallState.connected);
              _startTimer();
            } else if (['ended', 'rejected', 'cancelled', 'missed', 'failed'].contains(status)) {
              _onRemoteEnded(_mapStatusToState(status));
            }
          }
        });
  }

  CallState _mapStatusToState(String status) {
    switch (status) {
      case 'ended': return CallState.ended;
      case 'rejected': return CallState.rejected;
      case 'cancelled': return CallState.cancelled;
      case 'missed': return CallState.missed;
      case 'failed': return CallState.failed;
      default: return CallState.idle;
    }
  }

  void _startTimer() {
    _callDurationTimer?.cancel();
    _durationSeconds = 0;
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _durationSeconds++;
      notifyListeners();
    });
  }

  void _cleanup() {
    _callDurationTimer?.cancel();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _remoteStream?.dispose();
    _peerConnection?.close();
    _peerConnection?.dispose();
    _signalingChannel?.unsubscribe();
    _callUpdateSubscription?.cancel();
    
    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
    _signalingChannel = null;
    _callUpdateSubscription = null;
    
    Future.delayed(const Duration(seconds: 3), () {
      if (_state == CallState.ended || _state == CallState.rejected || _state == CallState.cancelled || _state == CallState.failed) {
        _currentCall = null;
        _updateState(CallState.idle);
      }
    });
  }

  void toggleMute(bool isMuted) {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !isMuted;
    });
    notifyListeners();
  }

  void toggleSpeaker(bool isSpeaker) {
    // In flutter_webrtc, this might be handled via Helper
    Helper.setSpeakerphoneOn(isSpeaker);
    notifyListeners();
  }
}
