import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';

class ChatsScreen extends StatelessWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
            Gap.h24,
            Text(
              'No conversations yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Gap.h8,
            const Text('Start a conversation with someone.'),
          ],
        ),
      ),
    );
  }
}
