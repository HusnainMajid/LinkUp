import 'package:flutter/material.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/theme/app_colors.dart';

enum AppButtonType { primary, secondary, outlined, text, gradient }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonType type;
  final bool isLoading;
  final IconData? icon;
  final double? width;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.type = AppButtonType.primary,
    this.isLoading = false,
    this.icon,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                type == AppButtonType.outlined || type == AppButtonType.text
                    ? theme.primaryColor
                    : Colors.white,
              ),
            ),
          ),
          Gap.w8,
        ] else if (icon != null) ...[
          Icon(icon, size: 20),
          Gap.w8,
        ],
        Text(text),
      ],
    );

    switch (type) {
      case AppButtonType.primary:
        return SizedBox(
          width: width ?? double.infinity,
          height: AppSizes.buttonHeight,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            child: content,
          ),
        );
      case AppButtonType.secondary:
        return SizedBox(
          width: width ?? double.infinity,
          height: AppSizes.buttonHeight,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: theme.colorScheme.onSecondary,
            ),
            child: content,
          ),
        );
      case AppButtonType.outlined:
        return SizedBox(
          width: width ?? double.infinity,
          height: AppSizes.buttonHeight,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: theme.primaryColor.withValues(alpha: 0.5)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
            ),
            child: content,
          ),
        );
      case AppButtonType.text:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          child: content,
        );
      case AppButtonType.gradient:
        return Container(
          width: width ?? double.infinity,
          height: AppSizes.buttonHeight,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          ),
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              elevation: 0,
            ),
            child: content,
          ),
        );
    }
  }
}
