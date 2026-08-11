import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Hub'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hub_outlined, size: 64, color: Colors.grey),
            Gap.h24,
            Text(
              'Your Personal Hub',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Gap.h8,
            const Text('Manage tasks, events, and notes here.'),
          ],
        ),
      ),
    );
  }
}
