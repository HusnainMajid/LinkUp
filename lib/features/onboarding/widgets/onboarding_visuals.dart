import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_sizes.dart';

class OnboardingVisual1 extends StatelessWidget {
  const OnboardingVisual1({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide * 0.8;
        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glowing Background
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.15),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Decorative connecting paths (Simplified abstract circles)
                ...List.generate(3, (index) {
                  return Container(
                    width: size * (0.6 + index * 0.2),
                    height: size * (0.6 + index * 0.2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        width: 1,
                      ),
                    ),
                  );
                }),
                // Connection Nodes
                _PositionedNode(size: size, angle: 0, color: AppColors.primary),
                _PositionedNode(size: size, angle: 72, color: AppColors.secondary),
                _PositionedNode(size: size, angle: 144, color: AppColors.primaryLight),
                _PositionedNode(size: size, angle: 216, color: AppColors.primary),
                _PositionedNode(size: size, angle: 288, color: AppColors.accent),
                
                // Central LinkUp Identity
                Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.link_rounded,
                      size: 40,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PositionedNode extends StatelessWidget {
  final double size;
  final double angle;
  final Color color;

  const _PositionedNode({
    required this.size,
    required this.angle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double radian = angle * (3.14159 / 180);
    final double radius = size * 0.4;
    return Transform.translate(
      offset: Offset(radius * 1.0 * (radian > 1.5 && radian < 4.7 ? -1 : 1) * (angle == 0 || angle == 180 ? 1 : 0.8), 0), // Math is hard, let's just use manual offsets for a clean star pattern
      child: _NodeCircle(color: color, angle: angle, dist: radius),
    );
  }
}

class _NodeCircle extends StatelessWidget {
  final Color color;
  final double angle;
  final double dist;
  const _NodeCircle({required this.color, required this.angle, required this.dist});

  @override
  Widget build(BuildContext context) {
    // Better positioning
    return Transform.translate(
      offset: Offset(dist * 0.9 * (angle == 0 ? 1 : (angle == 180 ? -1 : (angle < 180 ? 0.8 : -0.8))), 
                     dist * 0.9 * (angle == 90 ? 1 : (angle == 270 ? -1 : (angle > 0 && angle < 180 ? 0.6 : -0.6)))),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, spreadRadius: 2),
          ],
        ),
      ),
    );
  }
}

class OnboardingVisual2 extends StatelessWidget {
  const OnboardingVisual2({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final cardWidth = width * 0.45;
        
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Organized structure background
                Container(
                  width: width * 0.7,
                  height: height * 0.7,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.03),
                    borderRadius: BorderRadius.circular(AppSizes.radiusExtraLarge),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.05)),
                  ),
                ),
                // Flowing message cards
                _MessageCard(
                  offset: const Offset(-40, -60),
                  color: Colors.white,
                  icon: Icons.chat_bubble_outline,
                  delay: 0,
                  width: cardWidth,
                ),
                _MessageCard(
                  offset: const Offset(50, -20),
                  color: AppColors.primary.withValues(alpha: 0.1),
                  icon: Icons.image_outlined,
                  delay: 200,
                  width: cardWidth,
                ),
                _MessageCard(
                  offset: const Offset(-20, 30),
                  color: AppColors.secondary.withValues(alpha: 0.1),
                  icon: Icons.attach_file_rounded,
                  delay: 400,
                  width: cardWidth,
                ),
                _MessageCard(
                  offset: const Offset(40, 80),
                  color: Colors.white,
                  icon: Icons.videocam_outlined,
                  delay: 600,
                  width: cardWidth,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MessageCard extends StatelessWidget {
  final Offset offset;
  final Color color;
  final IconData icon;
  final int delay;
  final double width;

  const _MessageCard({
    required this.offset,
    required this.color,
    required this.icon,
    required this.delay,
    required this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Container(
        width: width,
        padding: const EdgeInsets.all(AppSizes.p12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(height: 6, width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(3))),
                  Gap.h4,
                  Container(height: 6, width: width * 0.4, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(3))),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingVisual3 extends StatelessWidget {
  const OnboardingVisual3({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest.shortestSide * 0.7;
        return Center(
          child: SizedBox(
            width: size,
            height: size * 1.3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow behind capsule
                Container(
                  width: size * 0.9,
                  height: size * 1.2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(size),
                    gradient: RadialGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.2),
                        AppColors.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // The Capsule
                Container(
                  width: size * 0.7,
                  height: size * 1.1,
                  decoration: BoxDecoration(
                    gradient: AppColors.violetGradient,
                    borderRadius: BorderRadius.circular(size),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
                      Gap.h16,
                      Container(
                        width: size * 0.4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      Gap.h8,
                      Container(
                        width: size * 0.3,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
                // Decorative elements around capsule
                _PositionedDecoration(offset: const Offset(-60, -80), icon: Icons.chat_rounded),
                _PositionedDecoration(offset: const Offset(60, 20), icon: Icons.star_rounded),
                _PositionedDecoration(offset: const Offset(-40, 90), icon: Icons.lock_rounded),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PositionedDecoration extends StatelessWidget {
  final Offset offset;
  final IconData icon;

  const _PositionedDecoration({required this.offset, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: offset,
      child: Container(
        padding: const EdgeInsets.all(AppSizes.p8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
            ),
          ],
        ),
        child: Icon(icon, size: 18, color: AppColors.primary),
      ),
    );
  }
}
