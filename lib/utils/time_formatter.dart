import 'package:intl/intl.dart';

/// Utility class for formatting timestamps and dates for UI display
class TimeFormatter {
  // Private constructor to prevent instantiation
  TimeFormatter._();

  /// Format timestamp for display in soil reading cards
  static String formatReadingTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final inputDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeFormat = DateFormat('h:mm a');
    final timeString = timeFormat.format(dateTime);

    if (inputDate == today) {
      return 'Today $timeString';
    } else if (inputDate == yesterday) {
      return 'Yesterday $timeString';
    } else if (now.difference(dateTime).inDays < 7) {
      // Within a week - show day name
      final dayFormat = DateFormat('EEEE');
      return '${dayFormat.format(dateTime)} $timeString';
    } else if (dateTime.year == now.year) {
      // Same year - show month and day
      final dateFormat = DateFormat('MMM d');
      return '${dateFormat.format(dateTime)}, $timeString';
    } else {
      // Different year - show full date
      final dateFormat = DateFormat('MMM d, yyyy');
      return '${dateFormat.format(dateTime)}, $timeString';
    }
  }

  /// Format timestamp for history list
  /// Example: "Jan 15, 2024 at 2:30 PM"
  static String formatHistoryTime(DateTime dateTime) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');
    return '${dateFormat.format(dateTime)} at ${timeFormat.format(dateTime)}';
  }

  /// Format timestamp for detailed view
  /// Example: "Monday, January 15, 2024 at 2:30:45 PM"
  static String formatDetailedTime(DateTime dateTime) {
    final format = DateFormat('EEEE, MMMM d, yyyy \'at\' h:mm:ss a');
    return format.format(dateTime);
  }

  /// Format date only (no time)
  /// Example: "January 15, 2024"
  static String formatDateOnly(DateTime dateTime) {
    final format = DateFormat('MMMM d, yyyy');
    return format.format(dateTime);
  }

  /// Format time only (no date)
  /// Example: "2:30 PM"
  static String formatTimeOnly(DateTime dateTime) {
    final format = DateFormat('h:mm a');
    return format.format(dateTime);
  }

  /// Format relative time (time ago)
  /// Example: "2 minutes ago", "1 hour ago", "3 days ago"
  static String formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '${minutes == 1 ? '1 minute' : '$minutes minutes'} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '${hours == 1 ? '1 hour' : '$hours hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '${days == 1 ? '1 day' : '$days days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks == 1 ? '1 week' : '$weeks weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months == 1 ? '1 month' : '$months months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years == 1 ? '1 year' : '$years years'} ago';
    }
  }

  /// Format duration between two timestamps
  /// Example: "2h 30m", "1d 5h", "3m 45s"
  static String formatDuration(Duration duration) {
    if (duration.inDays > 0) {
      final days = duration.inDays;
      final hours = duration.inHours % 24;
      if (hours > 0) {
        return '${days}d ${hours}h';
      }
      return '${days}d';
    } else if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    } else if (duration.inMinutes > 0) {
      final minutes = duration.inMinutes;
      final seconds = duration.inSeconds % 60;
      if (seconds > 0) {
        return '${minutes}m ${seconds}s';
      }
      return '${minutes}m';
    } else {
      return '${duration.inSeconds}s';
    }
  }

  /// Format for chart axis labels
  /// Example: "12 PM", "6 AM", "Jan 15"
  static String formatChartLabel(DateTime dateTime, ChartTimeScale scale) {
    switch (scale) {
      case ChartTimeScale.hourly:
        return DateFormat('h a').format(dateTime); // 12 PM
      case ChartTimeScale.daily:
        return DateFormat('MMM d').format(dateTime); // Jan 15
      case ChartTimeScale.weekly:
        return DateFormat('MMM d').format(dateTime); // Jan 15
      case ChartTimeScale.monthly:
        return DateFormat('MMM').format(dateTime); // Jan
      case ChartTimeScale.yearly:
        return DateFormat('yyyy').format(dateTime); // 2024
    }
  }

  /// Format time range
  /// Example: "Jan 15 - Jan 22, 2024"
  static String formatTimeRange(DateTime start, DateTime end) {
    final now = DateTime.now();

    if (start.year == end.year && start.year == now.year) {
      if (start.month == end.month) {
        // Same month, same year
        final startFormat = DateFormat('MMM d');
        final endFormat = DateFormat('d, yyyy');
        return '${startFormat.format(start)} - ${endFormat.format(end)}';
      } else {
        // Different months, same year
        final startFormat = DateFormat('MMM d');
        final endFormat = DateFormat('MMM d, yyyy');
        return '${startFormat.format(start)} - ${endFormat.format(end)}';
      }
    } else {
      // Different years or not current year
      final format = DateFormat('MMM d, yyyy');
      return '${format.format(start)} - ${format.format(end)}';
    }
  }

  /// Check if timestamp is recent (within last 5 minutes)
  static bool isRecent(DateTime dateTime) {
    final now = DateTime.now();
    return now.difference(dateTime).inMinutes <= 5;
  }

  /// Check if timestamp is today
  static bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }

  /// Check if timestamp is yesterday
  static bool isYesterday(DateTime dateTime) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day;
  }

  /// Get time of day description
  /// Example: "Morning", "Afternoon", "Evening", "Night"
  static String getTimeOfDay(DateTime dateTime) {
    final hour = dateTime.hour;

    if (hour >= 5 && hour < 12) {
      return 'Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Evening';
    } else {
      return 'Night';
    }
  }

  /// Format ISO 8601 string for API calls
  static String formatISO8601(DateTime dateTime) {
    return dateTime.toUtc().toIso8601String();
  }

  /// Parse ISO 8601 string from API responses
  static DateTime? parseISO8601(String? isoString) {
    if (isoString == null || isoString.isEmpty) {
      return null;
    }

    try {
      return DateTime.parse(isoString).toLocal();
    } catch (e) {
      print('Failed to parse ISO8601 date: $isoString');
      return null;
    }
  }

  /// Format for CSV export
  static String formatForExport(DateTime dateTime) {
    final format = DateFormat('yyyy-MM-dd HH:mm:ss');
    return format.format(dateTime);
  }

  /// Get next reading time estimate (if readings are taken at intervals)
  static String getNextReadingEstimate(DateTime lastReading, Duration interval) {
    final nextReading = lastReading.add(interval);
    final now = DateTime.now();

    if (nextReading.isBefore(now)) {
      return 'Available now';
    }

    final difference = nextReading.difference(now);
    return 'Next in ${formatDuration(difference)}';
  }
}

/// Enum for chart time scales
enum ChartTimeScale {
  hourly,
  daily,
  weekly,
  monthly,
  yearly,
}