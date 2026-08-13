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
    ],
    'sdpSemantics': 'unified-plan',
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
    debugPrint('CallService: initCall started for receiver: $receiverId');
    if (_state != CallState.idle) {
      debugPrint('CallService: Call already in progress');
      return;
    }

    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) {
      debugPrint('CallService: No current user session');
      _updateState(CallState.failed);
      return;
    }
    final callerId = currentUser.id;
    final callId = const Uuid().v4();

    _updateState(CallState.outgoing);
    
    try {
      debugPrint('CallService: Setting up WebRTC...');
      await _setupWebRTC();
      debugPrint('CallService: WebRTC setup complete');

      debugPrint('CallService: Creating Offer...');
      RTCSessionDescription offer = await _peerConnection!.createOffer(_constraints);
      await _peerConnection!.setLocalDescription(offer);
      debugPrint('CallService: Local description set');

      _currentCall = Call(
        id: callId,
        callerId: callerId,
        receiverId: receiverId,
        status: 'outgoing',
        type: 'voice',
        createdAt: DateTime.now(),
      );

      debugPrint('CallService: Inserting call into DB...');
      await _supabase.from('voice_calls').insert({
        ..._currentCall!.toJson(),
        'signaling_data': {
          'offer': {'sdp': offer.sdp, 'type': offer.type},
          'ice_candidates': [],
        },
      });
      debugPrint('CallService: DB insertion successful');

      _startCallUpdateSubscription(callId);
      debugPrint('CallService: Subscription started');
    } catch (e, stack) {
      debugPrint('CallService: Error initiating call: $e');
      debugPrint('CallService: Stack trace: $stack');
      _updateState(CallState.failed);
      _cleanup();
    }
  }

  Future<void> handleIncomingCall(Map<String, dynamic> data) async {
    if (_state != CallState.idle) return;

    final callId = data['call_id'];
    
    final response = await _supabase
        .from('voice_calls')
        .select()
        .eq('id', callId)
        .single();
    
    _currentCall = Call.fromJson(response);
    _updateState(CallState.ringing);

    _startCallUpdateSubscription(callId);
  }

  Future<void> acceptCall() async {
    if (_state != CallState.ringing || _currentCall == null) return;

    _updateState(CallState.connecting);

    try {
      await _setupWebRTC();

      // Get offer from DB
      final response = await _supabase
          .from('voice_calls')
          .select('signaling_data')
          .eq('id', _currentCall!.id)
          .single();
      
      final signalingData = response['signaling_data'] as Map<String, dynamic>;
      final offerMap = signalingData['offer'] as Map<String, dynamic>;
      
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(offerMap['sdp'], offerMap['type']),
      );

      RTCSessionDescription answer = await _peerConnection!.createAnswer(_constraints);
      await _peerConnection!.setLocalDescription(answer);

      // Add existing candidates
      final candidates = signalingData['ice_candidates'] as List;
      for (var c in candidates) {
        await _peerConnection!.addCandidate(
          RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']),
        );
      }

      await _supabase.from('voice_calls').update({
        'status': 'connected',
        'started_at': DateTime.now().toIso8601String(),
        'signaling_data': {
          ...signalingData,
          'answer': {'sdp': answer.sdp, 'type': answer.type},
        },
      }).eq('id', _currentCall!.id);

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
    _updateState(CallState.rejected);
    _cleanup();
  }

  Future<void> cancelCall() async {
    if (_currentCall == null) return;
    await _supabase.from('voice_calls').update({
      'status': 'cancelled',
      'ended_at': DateTime.now().toIso8601String(),
    }).eq('id', _currentCall!.id);
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
    _updateState(CallState.ended);
    _cleanup();
  }

  Future<void> _setupWebRTC() async {
    try {
      debugPrint('CallService: Getting user media...');
      _localStream = await navigator.mediaDevices.getUserMedia({'audio': true, 'video': false});
      debugPrint('CallService: User media obtained');
      
      debugPrint('CallService: Creating PeerConnection...');
      _peerConnection = await createPeerConnection(_iceServers, _constraints);
      debugPrint('CallService: PeerConnection created');

      _peerConnection!.onIceCandidate = (candidate) async {
        debugPrint('CallService: ICE Candidate generated');
        final currentCallId = _currentCall?.id;
        if (currentCallId == null) return;
        
        try {
          final response = await _supabase.from('voice_calls').select('signaling_data').eq('id', currentCallId).single();
          
          final data = response['signaling_data'] as Map<String, dynamic>? ?? {};
          final candidates = data['ice_candidates'] as List? ?? [];
          candidates.add({
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          });
          data['ice_candidates'] = candidates;
          await _supabase.from('voice_calls').update({'signaling_data': data}).eq('id', currentCallId);
        } catch (e) {
          debugPrint('CallService: Error updating ICE candidates: $e');
        }
      };

      _peerConnection!.onTrack = (RTCTrackEvent event) {
        debugPrint('CallService: Remote track received: ${event.track.kind}');
        if (event.streams.isNotEmpty) {
          _remoteStream = event.streams[0];
          notifyListeners();
        }
      };

      _peerConnection!.onConnectionState = (state) {
        debugPrint('CallService: Connection state changed: $state');
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _updateState(CallState.connected);
          _startTimer();
        }
      };

      debugPrint('CallService: Adding local tracks to PeerConnection');
      _localStream!.getTracks().forEach((track) {
        _peerConnection!.addTrack(track, _localStream!);
      });
    } catch (e) {
      debugPrint('CallService: _setupWebRTC error: $e');
      rethrow;
    }
  }

  void _startCallUpdateSubscription(String callId) {
    _callUpdateSubscription = _supabase
        .from('voice_calls')
        .stream(primaryKey: ['id'])
        .eq('id', callId)
        .listen((event) async {
          if (event.isNotEmpty && _currentCall != null) {
            final row = event.first;
            final status = row['status'];
            final signalingData = row['signaling_data'] as Map<String, dynamic>? ?? {};
            
            // Handle signaling
            final currentUserId = _supabase.auth.currentUser?.id;
            if (currentUserId != null && currentUserId == _currentCall!.callerId) {
              if (signalingData.containsKey('answer') && _peerConnection?.getRemoteDescription() == null) {
                final answer = signalingData['answer'];
                await _peerConnection?.setRemoteDescription(RTCSessionDescription(answer['sdp'], answer['type']));
              }
              // Add new candidates for caller
              final candidates = signalingData['ice_candidates'] as List? ?? [];
              // Simple check: if local candidates are few, add them all (WebRTC handles duplicates)
              for (var c in candidates) {
                await _peerConnection?.addCandidate(RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']));
              }
            }

            if (status == 'connected' && _state != CallState.connected) {
              _updateState(CallState.connected);
              _startTimer();
            } else if (['ended', 'rejected', 'cancelled', 'missed', 'failed'].contains(status)) {
              _updateState(_mapStatusToState(status));
              _cleanup();
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
    _peerConnection?.close();
    _peerConnection?.dispose();
    _callUpdateSubscription?.cancel();
    _localStream = null;
    _remoteStream = null;
    _peerConnection = null;
    _callUpdateSubscription = null;
    
    Future.delayed(const Duration(seconds: 3), () {
      if (![CallState.idle, CallState.connected, CallState.connecting].contains(_state)) {
        _currentCall = null;
        _updateState(CallState.idle);
      }
    });
  }

  void toggleMute(bool isMuted) => _localStream?.getAudioTracks().forEach((t) => t.enabled = !isMuted);
  void toggleSpeaker(bool isSpeaker) => Helper.setSpeakerphoneOn(isSpeaker);
}
