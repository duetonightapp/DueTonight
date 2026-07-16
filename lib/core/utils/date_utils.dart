import 'package:intl/intl.dart';

class DateUtils {
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('MMM dd, yyyy - hh:mm a').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('hh:mm a').format(date);
  }

  static String getRelativeTime(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      final absDiff = difference.abs();
      if (absDiff.inDays > 0) return '${absDiff.inDays}d overdue';
      if (absDiff.inHours > 0) return '${absDiff.inHours}h overdue';
      return 'Overdue';
    }

    if (difference.inDays > 0) return '${difference.inDays}d left';
    if (difference.inHours > 0) return '${difference.inHours}h left';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m left';
    return 'Due now';
  }

  static bool isOverdue(DateTime deadline) {
    return deadline.isBefore(DateTime.now());
  }

  static bool isDueSoon(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now);
    return difference.inHours <= 24 && !difference.isNegative;
  }
}