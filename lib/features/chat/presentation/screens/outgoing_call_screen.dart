import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../auth/models/profile_model.dart';
import '../../domain/services/call_service.dart';

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
      context.pushReplacement('/active-call');
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
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            AppAvatar(
              imageUrl: widget.receiver.avatarUrl,
              initials: widget.receiver.fullName,
              size: 120,
            ),
            const SizedBox(height: 24),
            Text(
              widget.receiver.fullName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Calling...',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: FloatingActionButton(
                onPressed: () => _callService.cancelCall(),
                backgroundColor: AppColors.error,
                child: const Icon(Icons.call_end_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
