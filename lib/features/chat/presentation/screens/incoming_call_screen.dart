import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../auth/models/profile_model.dart';
import '../../domain/services/call_service.dart';

class IncomingCallScreen extends StatefulWidget {
  final Profile caller;
  const IncomingCallScreen({super.key, required this.caller});

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final _callService = CallService();

  @override
  void initState() {
    super.initState();
    _callService.addListener(_onCallStateChanged);
  }

  void _onCallStateChanged() {
    if (_callService.state == CallState.connected || _callService.state == CallState.connecting) {
      context.pushReplacement('/active-call');
    } else if (_callService.state == CallState.idle || 
               _callService.state == CallState.rejected || 
               _callService.state == CallState.ended) {
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
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            AppAvatar(
              imageUrl: widget.caller.avatarUrl,
              initials: widget.caller.fullName,
              size: 120,
            ),
            const SizedBox(height: 24),
            Text(
              widget.caller.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Incoming Voice Call',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton(
                    heroTag: 'decline',
                    onPressed: () => _callService.rejectCall(),
                    backgroundColor: AppColors.error,
                    child: const Icon(Icons.call_end_rounded, color: Colors.white),
                  ),
                  FloatingActionButton(
                    heroTag: 'accept',
                    onPressed: () => _callService.acceptCall(),
                    backgroundColor: AppColors.success,
                    child: const Icon(Icons.call_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
