import 'package:intl/intl.dart';

class DateFormatter {
  static String formatLastSeen(DateTime? lastSeen, bool isOnline) {
    if (isOnline) return 'Online';
    if (lastSeen == null) return 'Offline';

    final now = DateTime.now();
    final localLastSeen = lastSeen.toLocal();
    final difference = now.difference(localLastSeen);

    if (difference.inMinutes < 1) {
      return 'last seen just now';
    }

    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final lastSeenDate = DateTime(localLastSeen.year, localLastSeen.month, localLastSeen.day);

    final timeString = DateFormat('h:mm a').format(localLastSeen);

    if (lastSeenDate == today) {
      return 'last seen today at $timeString';
    } else if (lastSeenDate == yesterday) {
      return 'last seen yesterday at $timeString';
    } else if (difference.inDays < 7) {
      return 'last seen ${DateFormat('E').format(localLastSeen)} at $timeString';
    } else {
      return 'last seen ${DateFormat('d MMM').format(localLastSeen)} at $timeString';
    }
  }

  static String formatChatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == yesterday) {
      return 'Yesterday';
    } else if (now.year == date.year) {
      return DateFormat('d MMMM').format(date);
    } else {
      return DateFormat('d MMMM yyyy').format(date);
    }
  }
}
