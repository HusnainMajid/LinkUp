import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../features/chat/data/repositories/chat_repository.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _chatRepository = ChatRepository();
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    _startGlobalMessageListener();
  }

  void _startGlobalMessageListener() {
    _messageSubscription = _chatRepository.subscribeToAllMessages().listen((message) {
      // Show in-app notification if the message is not from the current user
      // and we are not already in that specific chat room
      _showInAppNotification(message.content);
    });
  }

  void _showInAppNotification(String content) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'New Message: $content',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Navigation to the chat can be added here
            widget.navigationShell.goBranch(1); // Go to Chats tab
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    super.dispose();
  }

  void _onTap(int index) {
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: widget.navigationShell,
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
            selectedIndex: widget.navigationShell.currentIndex,
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
                icon: Icon(Icons.call_outlined, size: 24),
                selectedIcon: Icon(Icons.call_rounded, color: AppColors.primary, size: 26),
                label: 'Calls',
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
