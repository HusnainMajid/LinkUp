import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

enum AppButtonType { primary, secondary, outlined, text, gradient, error }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == AppButtonType.outlined || type == AppButtonType.text
                    ? AppColors.primary
                    : Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.1,
            color: _getTextColor(theme),
          ),
        ),
      ],
    );

    switch (type) {
      case AppButtonType.primary:
        return SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: content,
          ),
        );
      case AppButtonType.secondary:
        return SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
              foregroundColor: isDark ? Colors.white : Colors.black87,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: content,
          ),
        );
      case AppButtonType.outlined:
        return SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: content,
          ),
        );
      case AppButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          child: content,
        );
      case AppButtonType.gradient:
        return Container(
          width: width ?? double.infinity,
          height: height,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: content,
          ),
        );
      case AppButtonType.error:
         return SizedBox(
          width: width ?? double.infinity,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: content,
          ),
        );
    }
  }

  Color _getTextColor(ThemeData theme) {
     if (type == AppButtonType.primary || type == AppButtonType.gradient || type == AppButtonType.error) {
       return Colors.white;
     }
     if (type == AppButtonType.secondary) {
        return theme.brightness == Brightness.dark ? Colors.white : Colors.black87;
     }
     return AppColors.primary;
  }
}
