import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/friend_request_model.dart';
import '../../data/repositories/friend_repository.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({super.key});

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen> {
  final _friendRepository = FriendRepository();
  List<FriendRequest> _incoming = [];
  List<FriendRequest> _outgoing = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    try {
      final incoming = await _friendRepository.getIncomingRequests();
      final outgoing = await _friendRepository.getOutgoingRequests();
      if (mounted) {
        setState(() {
          _incoming = incoming;
          _outgoing = outgoing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _respond(String requestId, bool accept) async {
    try {
      await _friendRepository.respondToFriendRequest(requestId, accept);
      _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(accept ? 'Friend request accepted' : 'Friend request declined')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action failed. Try again.')),
        );
      }
    }
  }

  Future<void> _cancel(String requestId) async {
    try {
      await _friendRepository.cancelFriendRequest(requestId);
      _loadRequests();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request cancelled')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Action failed. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Friend Requests'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRequests,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSectionHeader('Incoming Requests', _incoming.length),
                  if (_incoming.isEmpty)
                    _buildEmptySection('No incoming requests')
                  else
                    ..._incoming.map((req) => _buildIncomingItem(req)),
                  
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader('Outgoing Requests', _outgoing.length),
                  if (_outgoing.isEmpty)
                    _buildEmptySection('No outgoing requests')
                  else
                    ..._outgoing.map((req) => _buildOutgoingItem(req)),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 16),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptySection(String message) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(color: Colors.grey, fontSize: 13),
        ),
      ),
    );
  }

  Widget _buildIncomingItem(FriendRequest request) {
    final profile = request.senderProfile;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: AppAvatar(
                imageUrl: profile?.avatarUrl,
                initials: profile?.fullName ?? 'U',
                size: 48,
              ),
              title: Text(profile?.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('@${profile?.username ?? 'username'}', style: const TextStyle(fontSize: 12)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Decline',
                    type: AppButtonType.outlined,
                    onPressed: () => _respond(request.id, false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppButton(
                    text: 'Accept',
                    type: AppButtonType.gradient,
                    onPressed: () => _respond(request.id, true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOutgoingItem(FriendRequest request) {
    final profile = request.receiverProfile;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            AppAvatar(
              imageUrl: profile?.avatarUrl,
              initials: profile?.fullName ?? 'U',
              size: 48,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile?.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('@${profile?.username ?? 'username'}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _cancel(request.id),
              child: const Text('Cancel', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }
}
