import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/repositories/chat_repository.dart';
import '../../domain/services/call_service.dart';

class CallsListScreen extends StatefulWidget {
  const CallsListScreen({super.key});

  @override
  State<CallsListScreen> createState() => _CallsListScreenState();
}

class _CallsListScreenState extends State<CallsListScreen> {
  final _chatRepository = ChatRepository();
  final _callService = CallService();
  Stream<List<Map<String, dynamic>>>? _callsStream;

  @override
  void initState() {
    super.initState();
    _callsStream = _chatRepository.subscribeToCallHistory();
  }

  String _formatDateTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final callDate = DateTime(date.year, date.month, date.day);

    if (callDate == today) {
      return 'Today, ${DateFormat('h:mm a').format(date)}';
    } else if (today.difference(callDate).inDays == 1) {
      return 'Yesterday, ${DateFormat('h:mm a').format(date)}';
    } else {
      return DateFormat('MMM d, h:mm a').format(date);
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes == 0) return '${remainingSeconds}s';
    return '${minutes}m ${remainingSeconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () {
              // Implementation for clearing history could go here
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _callsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final calls = snapshot.data ?? [];
          if (calls.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            itemCount: calls.length,
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemBuilder: (context, index) {
              final call = calls[index];
              final otherProfile = Profile.fromJson(call['other_participant_profile']);
              final status = call['status'];
              final isOutgoing = call['caller_id'] == Supabase.instance.client.auth.currentUser?.id;
              final createdAt = DateTime.parse(call['created_at']).toLocal();
              final duration = call['duration'] as int?;

              return _buildCallItem(
                context: context,
                profile: otherProfile,
                status: status,
                isOutgoing: isOutgoing,
                dateTime: createdAt,
                duration: duration,
                isDark: isDark,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCallItem({
    required BuildContext context,
    required Profile profile,
    required String status,
    required bool isOutgoing,
    required DateTime dateTime,
    required int? duration,
    required bool isDark,
  }) {
    IconData statusIcon;
    Color statusColor;
    String statusText;

    if (status == 'ended' || status == 'connected') {
      statusIcon = isOutgoing ? Icons.call_made_rounded : Icons.call_received_rounded;
      statusColor = AppColors.success;
      statusText = isOutgoing ? 'Outgoing voice call' : 'Incoming voice call';
    } else if (status == 'missed' || (status == 'rejected' && !isOutgoing)) {
      statusIcon = Icons.call_missed_rounded;
      statusColor = AppColors.error;
      statusText = 'Missed voice call';
    } else if (status == 'rejected' && isOutgoing) {
      statusIcon = Icons.call_made_rounded;
      statusColor = Colors.grey;
      statusText = 'Declined call';
    } else if (status == 'cancelled') {
      statusIcon = Icons.call_made_rounded;
      statusColor = Colors.grey;
      statusText = 'Cancelled call';
    } else {
      statusIcon = Icons.call_made_rounded;
      statusColor = AppColors.error;
      statusText = 'Failed call';
    }

    return ListTile(
      onTap: () async {
        final convId = await _chatRepository.getOrCreateDirectConversation(profile.id);
        if (mounted) context.push('/chat/$convId');
      },
      leading: AppAvatar(
        imageUrl: profile.avatarUrl,
        initials: profile.fullName ?? 'U',
        size: 50,
      ),
      title: Text(
        profile.fullName ?? 'User',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Row(
        children: [
          Icon(statusIcon, size: 14, color: statusColor),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '$statusText • ${_formatDateTime(dateTime)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: status == 'missed' ? AppColors.error : Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (duration != null \u0026\u0026 duration \u003e 0)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(
                _formatDuration(duration),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.call_outlined, color: AppColors.primary, size: 22),
            onPressed: () => _startCall(profile),
          ),
        ],
      ),
    );
  }

  Future<void> _startCall(Profile profile) async {
    try {
      await _callService.initCall(profile.id);
      if (mounted) {
        context.push('/outgoing-call', extra: profile);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not start call: $e')),
        );
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.call_end_rounded, size: 64, color: Colors.grey.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          const Text(
            'No calls yet',
            style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
