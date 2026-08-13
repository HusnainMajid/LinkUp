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
        border: Border.all(
          color: isCurrentUser 
              ? Colors.grey.withValues(alpha: 0.3)
              : (isUnseen ? AppColors.primary : Colors.grey.withValues(alpha: 0.3)),
          width: 2,
        ),
      ),
      child: child,
    );
  }
}

class AddMomentButton extends StatelessWidget {
  final VoidCallback onTap;
  final String? avatarUrl;
  final String? initials;

  const AddMomentButton({
    super.key,
    required this.onTap,
    this.avatarUrl,
    this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Stack(
            children: [
              MomentRing(
                isCurrentUser: true,
                child: AppAvatar(
                  imageUrl: avatarUrl,
                  initials: initials ?? 'U',
                  size: 58,
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'My Moment',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
