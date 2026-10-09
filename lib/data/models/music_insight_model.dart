/// Represents a computed music intelligence insight item
class MusicInsightItem {
  final String id;
  final String title;
  final String description;
  final String metricValue;
  final String? subtitle;
  final String category; // 'artist', 'time', 'streak', 'habit', 'discovery'
  final String iconName;

  const MusicInsightItem({
    required this.id,
    required this.title,
    required this.description,
    required this.metricValue,
    this.subtitle,
    required this.category,
    required this.iconName,
  });
}

/// Aggregated Music Intelligence summary generated from local listening history
class MusicIntelligenceSummary {
  final String? topArtistThisMonth;
  final int topArtistMinutes;
  final String mostActiveDayOfWeek;
  final String favouriteListeningPeriod;
  final double periodChangePercentage; // vs previous week/month
  final int uniqueArtistsCount;
  final int uniqueTracksCount;
  final double averageSessionDurationMinutes;
  final int currentStreak;
  final int nextMilestoneStreak;
  final List<String> recentlyDiscoveredArtists;
  final List<MusicInsightItem> insightsList;

  const MusicIntelligenceSummary({
    this.topArtistThisMonth,
    this.topArtistMinutes = 0,
    this.mostActiveDayOfWeek = 'Saturday',
    this.favouriteListeningPeriod = 'Evening (5 PM - 10 PM)',
    this.periodChangePercentage = 0.0,
    this.uniqueArtistsCount = 0,
    this.uniqueTracksCount = 0,
    this.averageSessionDurationMinutes = 0.0,
    this.currentStreak = 0,
    this.nextMilestoneStreak = 7,
    this.recentlyDiscoveredArtists = const [],
    this.insightsList = const [],
  });
}
