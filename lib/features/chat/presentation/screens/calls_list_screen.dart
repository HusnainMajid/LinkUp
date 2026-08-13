import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../data/models/call_model.dart';
import '../../data/repositories/chat_repository.dart';

class CallsListScreen extends StatefulWidget {
  const CallsListScreen({super.key});

  @override
  State<CallsListScreen> createState() => _CallsListScreenState();
}

class _CallsListScreenState extends State<CallsListScreen> {
  final _chatRepository = ChatRepository();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calls', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_call, color: AppColors.primary),
            onPressed: () => context.push('/friends'),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _chatRepository.subscribeToCallHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) return _buildEmptyState();

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 20),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final callMap = data[index];
              final call = Call.fromJson(callMap);
              // In this app structure, the other participant info might be nested or we fetch it
              return _buildCallRow(call, isDark, callMap['other_participant']);
            },
          );
        },
      ),
    );
  }

  Widget _buildCallRow(Call call, bool isDark, Map<String, dynamic>? otherJson) {
    final other = otherJson != null ? otherJson : null;
    final isMissed = call.status == 'missed' && call.type == 'incoming';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: AppAvatar(
        imageUrl: other?['avatar_url'],
        initials: other?['full_name'] ?? 'U',
        size: 54,
        showOnlineIndicator: other?['is_online'] ?? false,
      ),
      title: Text(
        other?['full_name'] ?? 'Unknown User',
        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: isMissed ? AppColors.error : (isDark ? Colors.white : Colors.black)),
      ),
      subtitle: Row(
        children: [
          Icon(
            call.type == 'outgoing' ? Icons.call_made_rounded : Icons.call_received_rounded,
            size: 14,
            color: isMissed ? AppColors.error : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            '${DateFormat('MMM d, h:mm a').format(call.createdAt)} ${call.duration != null ? '(${call.duration}s)' : ''}',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey),
          ),
        ],
      ),
      trailing: IconButton(
        icon: const Icon(Icons.call_outlined, color: AppColors.primary, size: 22),
        onPressed: () => context.push('/user/${other?['id']}'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.08), shape: BoxShape.circle),
            child: const Icon(Icons.phone_missed_rounded, size: 48, color: AppColors.primary),
          ),
          const SizedBox(height: 32),
          const Text('No calls yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          const Text('Your call history will appear here.', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
