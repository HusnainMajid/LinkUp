import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsToggleTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primary,
      ),
    );
  }
}

class SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  const SettingsActionTile({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value != null)
            Text(value!, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
        ],
      ),
      onTap: onTap,
    );
  }
}

class SettingsInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const SettingsInfoTile({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      trailing: Text(value, style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
}
