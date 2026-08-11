import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final String? imageUrl;
  final String? initials;
  final double size;
  final Color? backgroundColor;
  final bool showOnlineIndicator;

  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.size = AppSizes.avatarMedium,
    this.backgroundColor,
    this.showOnlineIndicator = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? (imageUrl == null ? null : theme.colorScheme.primaryContainer),
            gradient: imageUrl == null && backgroundColor == null
                ? AppColors.primaryGradient
                : null,
            shape: BoxShape.circle,
            border: Border.all(
              color: theme.scaffoldBackgroundColor,
              width: 2,
            ),
            image: imageUrl != null
                ? DecorationImage(
                    image: NetworkImage(imageUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: imageUrl == null && initials != null
              ? Center(
                  child: Text(
                    initials!.substring(0, initials!.length > 1 ? 2 : 1).toUpperCase(),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.4,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
        ),
        if (showOnlineIndicator)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.25,
              height: size * 0.25,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
