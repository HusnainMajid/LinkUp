import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_sizes.dart';
import '../../auth/services/auth_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('LinkUp'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.home_outlined, size: 64, color: Colors.grey),
            Gap.h24,
            Text(
              'Welcome to LinkUp!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Gap.h8,
            Text(
              user?.email ?? 'User',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Gap.h48,
            const Text('Your feed will appear here soon.'),
          ],
        ),
      ),
    );
  }
}
