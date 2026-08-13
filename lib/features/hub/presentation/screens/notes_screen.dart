import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/hub_models.dart';
import '../../data/repositories/hub_repository.dart';

class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  final _hubRepository = HubRepository();
  final _noteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Notes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Note>>(
        stream: _hubRepository.subscribeToNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final notes = snapshot.data ?? [];
          if (notes.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return GridView.builder(
            padding: const EdgeInsets.all(24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: notes.length,
            itemBuilder: (context, index) => _buildNoteItem(notes[index], isDark),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddNoteDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.note_add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildNoteItem(Note note, bool isDark) {
    final dateStr = DateFormat('MMM d').format(note.updatedAt);

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _showEditNoteDialog(context, note),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              note.content,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 18),
                onPressed: () => _hubRepository.deleteNote(note.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.note_alt_rounded, size: 48, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text(
            'No notes yet',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Capture your thoughts and ideas.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          AppButton(
            text: 'Write First Note',
            type: AppButtonType.gradient,
            width: 200,
            onPressed: () => _showAddNoteDialog(context),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context) {
    _noteController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Note'),
        content: TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            hintText: 'Start typing...',
            border: OutlineInputBorder(),
          ),
          maxLines: 8,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_noteController.text.isNotEmpty) {
                _hubRepository.createNote(_noteController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditNoteDialog(BuildContext context, Note note) {
    _noteController.text = note.content;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Note'),
        content: TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            hintText: 'Start typing...',
            border: OutlineInputBorder(),
          ),
          maxLines: 8,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (_noteController.text.isNotEmpty) {
                _hubRepository.updateNote(note.id, _noteController.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}
