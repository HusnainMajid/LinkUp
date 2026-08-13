import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/services/call_service.dart';
import '../widgets/call_widgets.dart';

class IncomingCallScreen extends StatefulWidget {
  final String callerId;
  final Map<String, dynamic> callData;

  const IncomingCallScreen({
    super.key, 
    required this.callerId, 
    required this.callData,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  final _callService = CallService();
  final _chatRepository = ChatRepository();
  Profile? _caller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCallerProfile();
    _callService.addListener(_onCallStateChanged);
    _callService.handleIncomingCall(widget.callData);
  }

  Future<void> _loadCallerProfile() async {
    try {
      final profile = await _chatRepository.getUserProfile(widget.callerId);
      if (mounted) {
        setState(() {
          _caller = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onCallStateChanged() {
    if (_callService.state == CallState.connected || _callService.state == CallState.connecting) {
      if (_caller != null) {
        context.pushReplacement('/active-call', extra: _caller);
      }
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
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.backgroundDark,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              AppColors.success.withValues(alpha: 0.1),
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
                    'Incoming Voice Call',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _caller?.fullName ?? 'Unknown User',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  AvatarPulse(
                    imageUrl: _caller?.avatarUrl,
                    initials: _caller?.fullName ?? 'U',
                    isPulseActive: true,
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 60, left: 40, right: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        CallControlButton(
                          icon: Icons.call_end_rounded,
                          label: 'Decline',
                          isActive: false,
                          color: AppColors.error,
                          isLarge: true,
                          onTap: () => _callService.rejectCall(),
                        ),
                        CallControlButton(
                          icon: Icons.call_rounded,
                          label: 'Accept',
                          isActive: false,
                          color: AppColors.success,
                          isLarge: true,
                          onTap: () => _callService.acceptCall(),
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
