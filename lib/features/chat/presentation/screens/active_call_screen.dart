import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/models/profile_model.dart';
import '../../domain/services/call_service.dart';
import '../widgets/call_widgets.dart';

class ActiveCallScreen extends StatefulWidget {
  final Profile otherParticipant;
  const ActiveCallScreen({super.key, required this.otherParticipant});

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  final _callService = CallService();
  bool _isMuted = false;
  bool _isSpeakerOn = false;

  @override
  void initState() {
    super.initState();
    _callService.addListener(_onCallStateChanged);
  }

  void _onCallStateChanged() {
    if (_callService.state == CallState.ended || 
        _callService.state == CallState.rejected || 
        _callService.state == CallState.cancelled ||
        _callService.state == CallState.failed ||
        _callService.state == CallState.idle) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _callService.removeListener(_onCallStateChanged);
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Container(
        height: double.infinity,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.backgroundDark,
              AppColors.backgroundDark.withValues(alpha: 0.9),
              Colors.black,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: SizedBox(
              height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  const Text(
                    'On Call',
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 14,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.otherParticipant.fullName ?? 'User',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDuration(_callService.durationSeconds),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  const Spacer(),
                  AvatarPulse(
                    imageUrl: widget.otherParticipant.avatarUrl,
                    initials: widget.otherParticipant.fullName ?? 'U',
                    isPulseActive: false,
                    showOnlineIndicator: true,
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60, left: 24, right: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CallControlButton(
                          icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                          label: 'Mute',
                          isActive: _isMuted,
                          onTap: () {
                            setState(() => _isMuted = !_isMuted);
                            _callService.toggleMute(_isMuted);
                          },
                        ),
                        CallControlButton(
                          icon: Icons.call_end_rounded,
                          label: 'End',
                          isActive: false,
                          color: AppColors.error,
                          isLarge: true,
                          onTap: () => _callService.endCall(),
                        ),
                        CallControlButton(
                          icon: _isSpeakerOn ? Icons.volume_up_rounded : Icons.volume_down_rounded,
                          label: 'Speaker',
                          isActive: _isSpeakerOn,
                          onTap: () {
                            setState(() => _isSpeakerOn = !_isSpeakerOn);
                            _callService.toggleSpeaker(_isSpeakerOn);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
