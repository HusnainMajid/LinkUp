import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/models/profile_model.dart';
import '../../domain/services/call_service.dart';
import '../widgets/call_widgets.dart';

class OutgoingCallScreen extends StatefulWidget {
  final Profile receiver;
  const OutgoingCallScreen({super.key, required this.receiver});

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  final _callService = CallService();

  @override
  void initState() {
    super.initState();
    _callService.addListener(_onCallStateChanged);
  }

  void _onCallStateChanged() {
    if (_callService.state == CallState.connected) {
      context.pushReplacement('/active-call', extra: widget.receiver);
    } else if (_callService.state == CallState.cancelled || 
               _callService.state == CallState.rejected || 
               _callService.state == CallState.ended ||
               _callService.state == CallState.failed) {
      if (mounted) context.pop();
    }
  }

  @override
  void dispose() {
    _callService.removeListener(_onCallStateChanged);
    super.dispose();
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
              AppColors.backgroundDark.withValues(alpha: 0.8),
              AppColors.primary.withValues(alpha: 0.1),
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
                    'Outgoing Call',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.receiver.fullName ?? 'User',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getStatusText(),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  AvatarPulse(
                    imageUrl: widget.receiver.avatarUrl,
                    initials: widget.receiver.fullName ?? 'U',
                    isPulseActive: true,
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CallControlButton(
                          icon: Icons.call_end_rounded,
                          label: 'End',
                          isActive: false,
                          color: AppColors.error,
                          isLarge: true,
                          onTap: () => _callService.cancelCall(),
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

  String _getStatusText() {
    switch (_callService.state) {
      case CallState.outgoing:
        return 'Calling...';
      case CallState.connecting:
        return 'Connecting...';
      default:
        return 'Calling...';
    }
  }
}
