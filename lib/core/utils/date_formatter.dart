import 'package:intl/intl.dart';

/// Utilities for Date and Time formatting with local timezone awareness
class DateFormatter {
  DateFormatter._();

  static final DateFormat _dayNameFormat = DateFormat('EEE');
  static final DateFormat _monthDayFormat = DateFormat('MMM d');
  static final DateFormat _fullDateFormat = DateFormat('MMMM d, yyyy');
  static final DateFormat _isoDayFormat = DateFormat('yyyy-MM-dd');
  static final DateFormat _timeFormat = DateFormat('h:mm a');

  /// Formats UTC DateTime to local short day name (e.g. "Mon")
  static String formatShortDay(DateTime dateTime) {
    return _dayNameFormat.format(dateTime.toLocal());
  }

  /// Formats UTC DateTime to local month and day (e.g. "Oct 9")
  static String formatMonthDay(DateTime dateTime) {
    return _monthDayFormat.format(dateTime.toLocal());
  }

  /// Formats UTC DateTime to full date (e.g. "October 9, 2026")
  static String formatFullDate(DateTime dateTime) {
    return _fullDateFormat.format(dateTime.toLocal());
  }

  /// Formats DateTime to local ISO date string "YYYY-MM-DD"
  static String formatIsoDate(DateTime dateTime) {
    return _isoDayFormat.format(dateTime.toLocal());
  }

  /// Formats DateTime to time of day "3:45 PM"
  static String formatTime(DateTime dateTime) {
    return _timeFormat.format(dateTime.toLocal());
  }

  /// Returns greeting string based on current local hour
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  /// Checks if two dates fall on the same local calendar day
  static bool isSameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }
}
