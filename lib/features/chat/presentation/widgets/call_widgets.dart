import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_avatar.dart';

class AvatarPulse extends StatefulWidget {
  final String? imageUrl;
  final String initials;
  final bool isPulseActive;
  final bool showOnlineIndicator;

  const AvatarPulse({
    super.key,
    this.imageUrl,
    required this.initials,
    this.isPulseActive = true,
    this.showOnlineIndicator = false,
  });

  @override
  State<AvatarPulse> createState() => _AvatarPulseState();
}

class _AvatarPulseState extends State<AvatarPulse> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isPulseActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AvatarPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulseActive != oldWidget.isPulseActive) {
      if (widget.isPulseActive) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isPulseActive)
              ...List.generate(3, (index) {
                final progress = (_controller.value + index / 3) % 1.0;
                return Container(
                  width: 140 + (progress * 100),
                  height: 140 + (progress * 100),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.2 * (1 - progress)),
                  ),
                );
              }),
            AppAvatar(
              imageUrl: widget.imageUrl,
              initials: widget.initials,
              size: 140,
              showOnlineIndicator: widget.showOnlineIndicator,
            ),
          ],
        );
      },
    );
  }
}

class CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final Color? color;
  final bool isLarge;

  const CallControlButton({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.color,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? (isActive ? Colors.white : Colors.white.withValues(alpha: 0.1));
    final iconColor = isActive ? AppColors.backgroundDark : Colors.white;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(isLarge ? 48 : 32),
            child: Container(
              width: isLarge ? 80 : 64,
              height: isLarge ? 80 : 64,
              decoration: BoxDecoration(
                color: effectiveColor,
                shape: BoxShape.circle,
                boxShadow: isLarge ? [
                  BoxShadow(
                    color: effectiveColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ] : null,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: isLarge ? 32 : 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
