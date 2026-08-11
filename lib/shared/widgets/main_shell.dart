import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';

class MainShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: NavigationBar(
            elevation: 0,
            backgroundColor: Colors.transparent,
            height: 64,
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onTap,
            indicatorColor: AppColors.primary.withValues(alpha: 0.1),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined, size: 24),
                selectedIcon: Icon(Icons.home_rounded, color: AppColors.primary, size: 26),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_bubble_outline_rounded, size: 24),
                selectedIcon: Icon(Icons.chat_bubble_rounded, color: AppColors.primary, size: 26),
                label: 'Chats',
              ),
              NavigationDestination(
                icon: Icon(Icons.group_outlined, size: 24),
                selectedIcon: Icon(Icons.group_rounded, color: AppColors.primary, size: 26),
                label: 'Groups',
              ),
              NavigationDestination(
                icon: Icon(Icons.auto_awesome_mosaic_outlined, size: 24),
                selectedIcon: Icon(Icons.auto_awesome_mosaic_rounded, color: AppColors.primary, size: 26),
                label: 'Hub',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded, size: 24),
                selectedIcon: Icon(Icons.person_rounded, color: AppColors.primary, size: 26),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
