import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../chat/data/repositories/chat_repository.dart';
import '../../data/models/moment_model.dart';
import '../../data/repositories/moment_repository.dart';

class MomentViewerScreen extends StatefulWidget {
  final List<Moment> moments;
  const MomentViewerScreen({super.key, required this.moments});

  @override
  State<MomentViewerScreen> createState() => _MomentViewerScreenState();
}

class _MomentViewerScreenState extends State<MomentViewerScreen> {
  final _momentRepository = MomentRepository();
  final _chatRepository = ChatRepository();
  final _replyController = TextEditingController();
  int _currentIndex = 0;
  Timer? _timer;
  double _progress = 0.0;
  static const int _momentDurationSeconds = 6;
  bool _isSendingReply = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _trackView();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _replyController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _progress = 0.0;
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _progress += 0.05 / _momentDurationSeconds;
          if (_progress >= 1.0) {
            _nextMoment();
          }
        });
      }
    });
  }

  void _nextMoment() {
    if (_currentIndex < widget.moments.length - 1) {
      setState(() {
        _currentIndex++;
        _startTimer();
        _trackView();
      });
    } else {
      if (mounted) context.pop();
    }
  }

  void _previousMoment() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _startTimer();
        _trackView();
      });
    } else {
      _startTimer();
    }
  }

  void _trackView() {
    _momentRepository.trackView(widget.moments[_currentIndex].id);
  }

  Future<void> _sendReply(Moment moment) async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSendingReply = true);
    _timer?.cancel();

    try {
      final conversationId = await _chatRepository.getOrCreateDirectConversation(moment.userId);
      await _chatRepository.sendMessage(conversationId: conversationId, content: 'Replied to moment: $text');
      if (mounted) {
        _replyController.clear();
        FocusScope.of(context).unfocus();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply sent!'), duration: Duration(seconds: 2)));
        _startTimer();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send reply: $e')));
        _startTimer();
      }
    } finally {
      if (mounted) setState(() => _isSendingReply = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final moment = widget.moments[_currentIndex];
    final user = moment.user;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Content
          GestureDetector(
            onTapUp: (details) {
              final width = MediaQuery.of(context).size.width;
              if (details.globalPosition.dx < width / 3) {
                _previousMoment();
              } else {
                _nextMoment();
              }
            },
            onLongPressStart: (_) => _timer?.cancel(),
            onLongPressEnd: (_) => _startTimer(),
            child: Center(
              child: moment.type == 'image'
                  ? Image.network(
                      moment.imageUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2));
                      },
                    )
                  : Container(
                      width: double.infinity,
                      height: double.infinity,
                      color: _getBackgroundColor(moment.backgroundColor),
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Text(
                        moment.content ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                      ),
                    ),
            ),
          ),

          // Caption
          if (moment.type == 'image' && moment.content != null && moment.content!.isNotEmpty)
            Positioned(
              bottom: 140,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(16)),
                child: Text(moment.content!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              ),
            ),

          // Top Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: List.generate(widget.moments.length, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: LinearProgressIndicator(
                            value: index < _currentIndex ? 1.0 : (index == _currentIndex ? _progress : 0.0),
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 2.5,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      AppAvatar(imageUrl: user?.avatarUrl, initials: user?.fullName ?? 'U', size: 44),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user?.fullName ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                            Text(DateFormatter.formatChatDate(moment.createdAt), style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28), onPressed: () => context.pop()),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Footer
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withValues(alpha: 0.9)]),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (moment.userId == _momentRepository.supabase.auth.currentUser?.id)
                    _buildViewerCount(moment),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
                          child: Theme(
                            data: Theme.of(context).copyWith(textSelectionTheme: const TextSelectionThemeData(cursorColor: Colors.black)),
                            child: TextField(
                              controller: _replyController,
                              style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w500),
                              decoration: const InputDecoration(hintText: 'Reply...', hintStyle: TextStyle(color: Colors.black38), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12), filled: false),
                              onTap: () => _timer?.cancel(),
                              onSubmitted: (_) => _sendReply(moment),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (moment.userId != _momentRepository.supabase.auth.currentUser?.id)
                        _isSendingReply 
                          ? const SizedBox(width: 48, height: 48, child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                          : Container(
                              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                              child: IconButton(icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22), onPressed: () => _sendReply(moment)),
                            ),
                      if (moment.userId == _momentRepository.supabase.auth.currentUser?.id)
                        Container(
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), shape: BoxShape.circle),
                          child: IconButton(icon: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22), onPressed: () => _confirmDelete(moment)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewerCount(Moment moment) {
    return InkWell(
      onTap: () => _showViewerList(moment),
      child: Column(
        children: [
          const Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white70),
          Text('${moment.viewerCount} views', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Color _getBackgroundColor(String? hex) {
    if (hex == null) return AppColors.primary;
    try { return Color(int.parse(hex.replaceFirst('#', '0xff'))); } catch (_) { return AppColors.primary; }
  }

  void _showViewerList(Moment moment) {
    _timer?.cancel();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2))),
            const Padding(padding: EdgeInsets.all(24), child: Text('Viewed by', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20))),
            Expanded(
              child: FutureBuilder<List<MomentView>>(
                future: _momentRepository.getMomentViewers(moment.id),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                  final views = snapshot.data ?? [];
                  if (views.isEmpty) return const Center(child: Text('No views yet', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)));
                  return ListView.builder(
                    itemCount: views.length,
                    itemBuilder: (context, index) {
                      final view = views[index];
                      final user = view.viewer;
                      return ListTile(
                        leading: AppAvatar(imageUrl: user?.avatarUrl, initials: user?.fullName ?? 'U', size: 48),
                        title: Text(user?.fullName ?? 'User', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        subtitle: Text(DateFormatter.formatChatDate(view.viewedAt), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).whenComplete(() => _startTimer());
  }

  void _confirmDelete(Moment moment) {
    _timer?.cancel();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Moment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); _startTimer(); }, child: const Text('Cancel')),
          TextButton(onPressed: () async { await _momentRepository.deleteMoment(moment.id); if (mounted) { Navigator.pop(context); context.pop(); } }, child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }
}
