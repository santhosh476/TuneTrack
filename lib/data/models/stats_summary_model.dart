enum StatsTimeRange {
  day,
  week,
  month,
  year,
  allTime,
}

/// Generic container for ranking top tracks, artists, and albums
class TopItemModel {
  final String id;
  final String title;
  final String subtitle;
  final String? artworkUrl;
  final int playCount;
  final int totalDurationSeconds;

  const TopItemModel({
    required this.id,
    required this.title,
    required this.subtitle,
    this.artworkUrl,
    required this.playCount,
    required this.totalDurationSeconds,
  });
}

/// Represents single day activity for charts
class DailyActivityModel {
  final String dayLabel; // e.g. "Mon", "Tue"
  final DateTime date;
  final double listeningMinutes;

  const DailyActivityModel({
    required this.dayLabel,
    required this.date,
    required this.listeningMinutes,
  });
}

/// Summary of listening analytics for a given time range
class StatsSummaryModel {
  final StatsTimeRange timeRange;
  final int totalListeningSeconds;
  final int validPlaysCount;
  final int completedPlaysCount;
  final List<TopItemModel> topTracks;
  final List<TopItemModel> topArtists;
  final List<TopItemModel> topAlbums;
  final Map<String, int> genreDistribution;
  final List<DailyActivityModel> dailyActivity;
  final int currentStreak;
  final int longestStreak;
  final int dailyGoalMinutes;
  final int todayListeningMinutes;

  const StatsSummaryModel({
    required this.timeRange,
    this.totalListeningSeconds = 0,
    this.validPlaysCount = 0,
    this.completedPlaysCount = 0,
    this.topTracks = const [],
    this.topArtists = const [],
    this.topAlbums = const [],
    this.genreDistribution = const {},
    this.dailyActivity = const [],
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.dailyGoalMinutes = 45,
    this.todayListeningMinutes = 0,
  });

  double get goalProgress {
    if (dailyGoalMinutes <= 0) return 1.0;
    return (todayListeningMinutes / dailyGoalMinutes).clamp(0.0, 1.0);
  }

  bool get isGoalMet => todayListeningMinutes >= dailyGoalMinutes;
}
