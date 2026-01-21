import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Date and time utilities for PutraSportHub
class DateTimeUtils {
  DateTimeUtils._();

  // ═══════════════════════════════════════════════════════════════════════════
  // FORMATTERS
  // ═══════════════════════════════════════════════════════════════════════════

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _timeFormat = DateFormat('hh:mm a');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final DateFormat _dayFormat = DateFormat('EEEE');
  static final DateFormat _shortDateFormat = DateFormat('dd/MM/yyyy');
  static final DateFormat _monthYearFormat = DateFormat('MMMM yyyy');

  /// Format date to "25 Dec 2025"
  static String formatDate(DateTime date) => _dateFormat.format(date);

  /// Format time to "05:00 PM"
  static String formatTime(DateTime time) => _timeFormat.format(time);

  /// Format to "25 Dec 2025, 05:00 PM"
  static String formatDateTime(DateTime dateTime) =>
      _dateTimeFormat.format(dateTime);

  /// Format to day name "Monday"
  static String formatDay(DateTime date) => _dayFormat.format(date);

  /// Format to "25/12/2025"
  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);

  /// Format to "December 2025"
  static String formatMonthYear(DateTime date) => _monthYearFormat.format(date);

  /// Format time slot range "5:00 PM - 7:00 PM"
  static String formatTimeSlot(DateTime start, DateTime end) {
    return '${formatTime(start)} - ${formatTime(end)}';
  }

  /// Format duration in human-readable form
  static String formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      if (minutes > 0) {
        return '$hours hr $minutes min';
      }
      return '$hours ${hours == 1 ? 'hour' : 'hours'}';
    }
    return '${duration.inMinutes} minutes';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIME SLOT GENERATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate hourly time slots for a given date
  static List<TimeSlot> generateHourlySlots(DateTime date) {
    final slots = <TimeSlot>[];

    for (int hour = AppConstants.operatingStartHour;
        hour < AppConstants.operatingEndHour;
        hour++) {
      final startTime = DateTime(date.year, date.month, date.day, hour);
      final endTime = startTime.add(const Duration(hours: 1));

      // Skip Friday prayer time
      if (!_isFridayPrayerSlot(startTime)) {
        slots.add(TimeSlot(
          startTime: startTime,
          endTime: endTime,
          label: formatTimeSlot(startTime, endTime),
        ));
      }
    }

    return slots;
  }

  /// Generate 2-hour session slots (for Football)
  static List<TimeSlot> generateSessionSlots(DateTime date) {
    final slots = <TimeSlot>[];

    for (int hour = AppConstants.operatingStartHour;
        hour < AppConstants.operatingEndHour - 1;
        hour += 2) {
      final startTime = DateTime(date.year, date.month, date.day, hour);
      final endTime = startTime.add(const Duration(hours: 2));

      // Skip if any part falls in Friday prayer time
      if (!_isFridayPrayerSlot(startTime) && !_isFridayPrayerSlot(endTime)) {
        slots.add(TimeSlot(
          startTime: startTime,
          endTime: endTime,
          label: formatTimeSlot(startTime, endTime),
        ));
      }
    }

    return slots;
  }

  /// Check if slot overlaps with Friday prayer time
  static bool _isFridayPrayerSlot(DateTime time) {
    if (time.weekday != DateTime.friday) return false;

    final timeInMinutes = time.hour * 60 + time.minute;
    const blockStart = AppConstants.fridayBlockStartHour * 60 +
        AppConstants.fridayBlockStartMinute;
    const blockEnd =
        AppConstants.fridayBlockEndHour * 60 + AppConstants.fridayBlockEndMinute;

    return timeInMinutes >= blockStart && timeInMinutes < blockEnd;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DATE HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get start of day
  static DateTime startOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Get end of day
  static DateTime endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  /// Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year &&
        date.month == tomorrow.month &&
        date.day == tomorrow.day;
  }

  /// Check if booking can be cancelled (more than 24 hours before)
  static bool canCancel(DateTime bookingTime) {
    final now = DateTime.now();
    final difference = bookingTime.difference(now);
    return difference.inHours >= AppConstants.cancellationHoursThreshold;
  }

  /// Get days remaining until date
  static int daysUntil(DateTime date) {
    final now = DateTime.now();
    return DateTime(date.year, date.month, date.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  /// Get relative time string
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.isNegative) {
      // Future date
      final futureDiff = dateTime.difference(now);
      if (futureDiff.inDays > 0) {
        return 'in ${futureDiff.inDays} ${futureDiff.inDays == 1 ? 'day' : 'days'}';
      }
      if (futureDiff.inHours > 0) {
        return 'in ${futureDiff.inHours} ${futureDiff.inHours == 1 ? 'hour' : 'hours'}';
      }
      return 'in ${futureDiff.inMinutes} minutes';
    }

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    }
    if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    }
    if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    }
    if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    }
    return 'just now';
  }

  /// Get list of next N days for booking calendar
  static List<DateTime> getNextDays(int count) {
    final days = <DateTime>[];
    final today = DateTime.now();

    for (int i = 0; i < count; i++) {
      days.add(DateTime(today.year, today.month, today.day + i));
    }

    return days;
  }

  /// Check if time has passed
  static bool hasPassed(DateTime dateTime) {
    return dateTime.isBefore(DateTime.now());
  }
}

/// Time slot model
class TimeSlot {
  final DateTime startTime;
  final DateTime endTime;
  final String label;
  final bool isAvailable;

  const TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.label,
    this.isAvailable = true,
  });

  Duration get duration => endTime.difference(startTime);

  TimeSlot copyWith({bool? isAvailable}) {
    return TimeSlot(
      startTime: startTime,
      endTime: endTime,
      label: label,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeSlot &&
          runtimeType == other.runtimeType &&
          startTime == other.startTime &&
          endTime == other.endTime;

  @override
  int get hashCode => startTime.hashCode ^ endTime.hashCode;
}

