import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';

class MomentRing extends StatelessWidget {
  final Widget child;
  final bool isUnseen;
  final bool isCurrentUser;
  final double size;

  const MomentRing({
    super.key,
    required this.child,
    this.isUnseen = false,
    this.isCurrentUser = false,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isUnseen ? AppColors.primaryGradient : null,
        border: !isUnseen ? Border.all(
          color: Colors.grey.withValues(alpha: 0.2),
          width: 2,
        ) : null,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          shape: BoxShape.circle,
        ),
        child: child,
      ),
    );
  }
}

class UserMomentButton extends StatelessWidget {
  final VoidCallback onAdd;
  final VoidCallback onView;
  final String? avatarUrl;
  final String? initials;
  final bool hasActiveMoments;

  const UserMomentButton({
    super.key,
    required this.onAdd,
    required this.onView,
    this.avatarUrl,
    this.initials,
    this.hasActiveMoments = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: hasActiveMoments ? onView : onAdd,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Stack(
            children: [
              MomentRing(
                isUnseen: hasActiveMoments,
                isCurrentUser: true,
                child: AppAvatar(
                  imageUrl: avatarUrl,
                  initials: initials ?? 'Me',
                  size: 58,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: onAdd,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: isDark ? AppColors.backgroundDark : Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'My Moment',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
