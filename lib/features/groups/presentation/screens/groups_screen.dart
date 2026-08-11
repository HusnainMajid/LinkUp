import 'package:flutter/material.dart';
import '../../../../core/constants/app_sizes.dart';

class GroupsScreen extends StatelessWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.group_outlined, size: 64, color: Colors.grey),
            Gap.h24,
            Text(
              'No groups yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Gap.h8,
            const Text('Connect with multiple people at once.'),
          ],
        ),
      ),
    );
  }
}
