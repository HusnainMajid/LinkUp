import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/app_avatar.dart';
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
  int _currentIndex = 0;
  Timer? _timer;
  double _progress = 0.0;
  static const int _momentDurationSeconds = 5;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _trackView();
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      context.pop();
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

  @override
  Widget build(BuildContext context) {
    final moment = widget.moments[_currentIndex];
    final user = moment.user;

    return Scaffold(
      backgroundColor: Colors.black,
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
                      moment.image_url!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator(color: Colors.white));
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
                        style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
            ),
          ),

          // Caption (if any)
          if (moment.type == 'image' && moment.content != null && moment.content!.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  moment.content!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),

          // Top Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Progress Indicators
                  Row(
                    children: List.generate(widget.moments.length, (index) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: LinearProgressIndicator(
                            value: index < _currentIndex
                                ? 1.0
                                : (index == _currentIndex ? _progress : 0.0),
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            minHeight: 2,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  // User Info
                  Row(
                    children: [
                      AppAvatar(imageUrl: user?.avatarUrl, initials: user?.fullName ?? 'U', size: 40),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'User',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              DateFormatter.formatChatDate(moment.createdAt),
                              style: const TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Footer Actions
          Positioned(
            bottom: 32,
            left: 20,
            right: 20,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: TextField(
                      readOnly: true,
                      decoration: const InputDecoration(
                        hintText: 'Reply...',
                        hintStyle: TextStyle(color: Colors.white60),
                        border: InputBorder.none,
                      ),
                      onTap: () => _replyToMoment(moment),
                    ),
                  ),
                ),
                if (moment.userId == _momentRepository.supabase.auth.currentUser?.id)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                    onPressed: () => _confirmDelete(moment),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(String? hex) {
    if (hex == null) return AppColors.primary;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xff')));
    } catch (_) {
      return AppColors.primary;
    }
  }

  void _replyToMoment(Moment moment) {
    // Open chat
  }

  void _confirmDelete(Moment moment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Moment?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await _momentRepository.deleteMoment(moment.id);
              if (mounted) {
                Navigator.pop(context);
                context.pop();
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
