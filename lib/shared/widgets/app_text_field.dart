import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class AppTextField extends StatelessWidget {
  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? errorText;
  final bool enabled;
  final int? maxLines;
  final int? minLines;
  final TextInputType keyboardType;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const AppTextField({
    super.key,
    this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.errorText,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.keyboardType = TextInputType.text,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              label!,
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
        TextField(
          controller: controller,
          obscureText: obscureText,
          enabled: enabled,
          maxLines: maxLines,
          minLines: minLines,
          keyboardType: keyboardType,
          onChanged: onChanged,
          onTap: onTap,
          readOnly: readOnly,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
              fontSize: 14,
            ),
            prefixIcon: prefixIcon != null
                ? IconTheme(
                    data: IconThemeData(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      size: 20,
                    ),
                    child: prefixIcon!,
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? IconTheme(
                    data: IconThemeData(
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      size: 20,
                    ),
                    child: suffixIcon!,
                  )
                : null,
            errorText: errorText,
            filled: true,
            fillColor: isDark ? AppColors.surfaceDark : Colors.black.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppColors.error, width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          ),
        ),
      ],
    );
  }
}
