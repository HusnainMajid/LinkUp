import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/app_avatar.dart';
import '../../../auth/models/profile_model.dart';
import '../../data/models/conversation_model.dart';
import '../../data/repositories/chat_repository.dart';

class ArchivedChatsScreen extends StatefulWidget {
  const ArchivedChatsScreen({super.key});

  @override
  State<ArchivedChatsScreen> createState() => _ArchivedChatsScreenState();
}

class _ArchivedChatsScreenState extends State<ArchivedChatsScreen> {
  final _chatRepository = ChatRepository();
  Stream<List<Conversation>>? _conversationsStream;

  @override
  void initState() {
    super.initState();
    _conversationsStream = _chatRepository.subscribeToConversations();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Chats'),
      ),
      body: StreamBuilder<List<Conversation>>(
        stream: _conversationsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = (snapshot.data ?? []).where((c) => c.preferences?.isArchived ?? false).toList();

          if (conversations.isEmpty) {
            return const Center(
              child: Text('No archived conversations', style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              final otherUser = _chatRepository.getOtherParticipant(conversation);
              return _buildChatRow(context, conversation, otherUser);
            },
          );
        },
      ),
    );
  }

  Widget _buildChatRow(BuildContext context, Conversation conversation, Profile? otherUser) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      leading: AppAvatar(
        imageUrl: otherUser?.avatarUrl,
        initials: otherUser?.fullName ?? 'U',
        size: 56,
      ),
      title: Text(
        otherUser?.fullName ?? 'User',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        conversation.latestMessage?.content ?? 'No messages',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: const Icon(Icons.unarchive_outlined),
        onPressed: () => _chatRepository.toggleArchive(conversation.id, false),
      ),
      onTap: () => context.push('/chat/${conversation.id}'),
    );
  }
}
