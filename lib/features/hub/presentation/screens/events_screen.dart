import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/hub_models.dart';
import '../../data/repositories/hub_repository.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  final _hubRepository = HubRepository();
  final _titleController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Events', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<Event>>(
        stream: _hubRepository.subscribeToEvents(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final events = snapshot.data ?? [];
          if (events.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: events.length,
            separatorBuilder: (_, _) => const SizedBox(height: 16),
            itemBuilder: (context, index) => _buildEventItem(events[index], isDark),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEventDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.event_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEventItem(Event event, bool isDark) {
    final dateStr = DateFormat('MMM d, yyyy').format(event.eventDate);
    final timeStr = DateFormat('h:mm a').format(event.eventDate);

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (event.description != null && event.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    event.description!,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 14, color: AppColors.primary.withValues(alpha: 0.7)),
                    const SizedBox(width: 4),
                    Text(
                      '$dateStr • $timeStr',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.primary.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey, size: 20),
            onPressed: () => _hubRepository.deleteEvent(event.id),
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
            child: const Icon(Icons.calendar_month_rounded, size: 48, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          const Text(
            'No upcoming events',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Schedule and keep track of your events.',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          AppButton(
            text: 'Schedule Event',
            type: AppButtonType.gradient,
            width: 200,
            onPressed: () => _showAddEventDialog(context),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddEventDialog(BuildContext context) async {
    final descriptionController = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(days: 1));
    TimeOfDay selectedTime = const TimeOfDay(hour: 12, minute: 0);

    final result = await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('New Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Event Title',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  hintText: 'Description (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) setState(() => selectedDate = picked);
                      },
                      icon: const Icon(Icons.date_range_rounded, size: 18),
                      label: Text(DateFormat('MMM d').format(selectedDate)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime,
                        );
                        if (picked != null) setState(() => selectedTime = picked);
                      },
                      icon: const Icon(Icons.access_time_rounded, size: 18),
                      label: Text(selectedTime.format(context)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  final finalDateTime = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                  Navigator.pop(context, {'title': _titleController.text, 'description': descriptionController.text, 'date': finalDateTime});
                }
              },
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      await _hubRepository.createEvent(result['title'], result['description'], result['date']);
      _titleController.clear();
    }
  }
}
