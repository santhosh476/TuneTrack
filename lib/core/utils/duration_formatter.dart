/// Utilities for formatting Durations into readable text
class DurationFormatter {
  DurationFormatter._();

  /// Format duration to mm:ss or hh:mm:ss
  static String format(Duration? duration) {
    if (duration == null || duration.isNegative) return '00:00';
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final minutesStr = minutes.toString().padLeft(2, '0');
    final secondsStr = seconds.toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutesStr:$secondsStr';
    }
    return '$minutesStr:$secondsStr';
  }

  /// Format milliseconds into mm:ss
  static String formatMs(int? milliseconds) {
    if (milliseconds == null) return '0:00';
    return format(Duration(milliseconds: milliseconds));
  }

  /// Format total listening duration into descriptive string: e.g. "2h 45m" or "48m"
  static String formatListeningTime(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      if (minutes > 0) {
        return '${hours}h ${minutes}m';
      }
      return '${hours}h';
    }
    return '${minutes}m';
  }

  /// Format listening seconds into descriptive string
  static String formatListeningSeconds(int totalSeconds) {
    return formatListeningTime(Duration(seconds: totalSeconds));
  }
}
