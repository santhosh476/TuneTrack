import '../../data/models/listening_session_model.dart';
import '../../data/models/music_insight_model.dart';

/// Deterministic Music Intelligence engine that extracts insights from listening history
class MusicIntelligenceService {
  MusicIntelligenceService._();

  static MusicIntelligenceSummary generateInsights({
    required List<ListeningSessionModel> sessions,
    required int currentStreak,
    required int longestStreak,
  }) {
    if (sessions.isEmpty) {
      return const MusicIntelligenceSummary();
    }

    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisWeekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final prevWeekStart = thisWeekStart.subtract(const Duration(days: 7));

    // 1. Top Artist This Month
    final thisMonthSessions = sessions
        .where((s) => s.startedAt.toLocal().isAfter(thisMonthStart))
        .toList();
    final Map<String, int> artistSecondsMonth = {};
    for (final s in thisMonthSessions) {
      artistSecondsMonth[s.artistName] =
          (artistSecondsMonth[s.artistName] ?? 0) + s.audibleDurationSeconds;
    }

    String? topArtistMonth;
    int topArtistSecs = 0;
    if (artistSecondsMonth.isNotEmpty) {
      final sortedArtists = artistSecondsMonth.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      topArtistMonth = sortedArtists.first.key;
      topArtistSecs = sortedArtists.first.value;
    }

    // 2. Most Active Day of Week
    final Map<int, int> dayOfWeekSeconds = {
      1: 0,
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
      7: 0
    };
    for (final s in sessions) {
      final weekday = s.startedAt.toLocal().weekday;
      dayOfWeekSeconds[weekday] =
          (dayOfWeekSeconds[weekday] ?? 0) + s.audibleDurationSeconds;
    }
    final mostActiveWeekdayNum = dayOfWeekSeconds.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
    const weekdayNames = [
      '',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    final mostActiveDayName = weekdayNames[mostActiveWeekdayNum];

    // 3. Favourite Listening Period / Time of Day
    // Morning: 5 - 11, Afternoon: 12 - 16, Evening: 17 - 21, Night: 22 - 4
    final Map<String, int> periodSeconds = {
      'Morning (5 AM - 12 PM)': 0,
      'Afternoon (12 PM - 5 PM)': 0,
      'Evening (5 PM - 10 PM)': 0,
      'Late Night (10 PM - 5 AM)': 0,
    };

    for (final s in sessions) {
      final hour = s.startedAt.toLocal().hour;
      if (hour >= 5 && hour < 12) {
        periodSeconds['Morning (5 AM - 12 PM)'] =
            periodSeconds['Morning (5 AM - 12 PM)']! + s.audibleDurationSeconds;
      } else if (hour >= 12 && hour < 17) {
        periodSeconds['Afternoon (12 PM - 5 PM)'] =
            periodSeconds['Afternoon (12 PM - 5 PM)']! +
                s.audibleDurationSeconds;
      } else if (hour >= 17 && hour < 22) {
        periodSeconds['Evening (5 PM - 10 PM)'] =
            periodSeconds['Evening (5 PM - 10 PM)']! + s.audibleDurationSeconds;
      } else {
        periodSeconds['Late Night (10 PM - 5 AM)'] =
            periodSeconds['Late Night (10 PM - 5 AM)']! +
                s.audibleDurationSeconds;
      }
    }
    final favouritePeriod =
        periodSeconds.entries.reduce((a, b) => a.value >= b.value ? a : b).key;

    // 4. Period Change Percentage (This Week vs Previous Week)
    final thisWeekSecs = sessions
        .where((s) => s.startedAt.toLocal().isAfter(thisWeekStart))
        .fold<int>(0, (sum, s) => sum + s.audibleDurationSeconds);
    final prevWeekSecs = sessions.where((s) {
      final local = s.startedAt.toLocal();
      return local.isAfter(prevWeekStart) && local.isBefore(thisWeekStart);
    }).fold<int>(0, (sum, s) => sum + s.audibleDurationSeconds);

    double changePct = 0.0;
    if (prevWeekSecs > 0) {
      changePct = ((thisWeekSecs - prevWeekSecs) / prevWeekSecs) * 100.0;
    } else if (thisWeekSecs > 0) {
      changePct = 100.0;
    }

    // 5. Unique Artists & Tracks
    final uniqueArtists = sessions.map((s) => s.artistName).toSet();
    final uniqueTracks = sessions.map((s) => s.trackId).toSet();

    // 6. Average Session Duration
    final validSessions =
        sessions.where((s) => s.audibleDurationSeconds > 0).toList();
    final avgSessionMins = validSessions.isNotEmpty
        ? (validSessions.fold<int>(
                    0, (sum, s) => sum + s.audibleDurationSeconds) /
                validSessions.length) /
            60.0
        : 0.0;

    // 7. Streak Milestones
    final milestones = [3, 7, 14, 30, 60, 100, 365];
    int nextMilestone = 7;
    for (final m in milestones) {
      if (currentStreak < m) {
        nextMilestone = m;
        break;
      }
    }

    // 8. Recently Discovered Artists (first listened in last 14 days)
    final fourteenDaysAgo = now.subtract(const Duration(days: 14));
    final recentlyDiscovered = <String>[];
    for (final artist in uniqueArtists) {
      final firstListen = sessions
          .where((s) => s.artistName == artist)
          .map((s) => s.startedAt.toLocal())
          .reduce((a, b) => a.isBefore(b) ? a : b);
      if (firstListen.isAfter(fourteenDaysAgo)) {
        recentlyDiscovered.add(artist);
      }
    }

    // 9. Build List of Insight Items
    final List<MusicInsightItem> insightItems = [];

    if (topArtistMonth != null) {
      insightItems.add(MusicInsightItem(
        id: 'ins_top_artist',
        title: 'Monthly Favorite',
        description: 'You\'ve listened to $topArtistMonth the most this month.',
        metricValue: '${(topArtistSecs / 60).round()}m',
        subtitle: topArtistMonth,
        category: 'artist',
        iconName: 'person_rounded',
      ));
    }

    insightItems.add(MusicInsightItem(
      id: 'ins_active_day',
      title: 'Peak Listening Day',
      description: 'Your music listening peaks on $mostActiveDayName.',
      metricValue: mostActiveDayName,
      category: 'time',
      iconName: 'calendar_today_rounded',
    ));

    insightItems.add(MusicInsightItem(
      id: 'ins_period',
      title: 'Preferred Listening Time',
      description: 'You are most tuned in during the $favouritePeriod.',
      metricValue: favouritePeriod.split(' (').first,
      subtitle: favouritePeriod,
      category: 'habit',
      iconName: 'schedule_rounded',
    ));

    if (changePct != 0.0) {
      final sign = changePct >= 0 ? '+' : '';
      insightItems.add(MusicInsightItem(
        id: 'ins_change',
        title: 'Weekly Listening Trend',
        description: changePct >= 0
            ? 'Your listening time increased by ${changePct.toStringAsFixed(0)}% this week!'
            : 'Your listening time decreased by ${changePct.abs().toStringAsFixed(0)}% this week.',
        metricValue: '$sign${changePct.toStringAsFixed(0)}%',
        category: 'habit',
        iconName:
            changePct >= 0 ? 'trending_up_rounded' : 'trending_down_rounded',
      ));
    }

    if (currentStreak > 0) {
      insightItems.add(MusicInsightItem(
        id: 'ins_streak',
        title: 'Streak Milestone',
        description:
            '$currentStreak day streak active. Next milestone: $nextMilestone days!',
        metricValue: '$currentStreak Days',
        subtitle: 'Target: $nextMilestone days',
        category: 'streak',
        iconName: 'local_fire_department_rounded',
      ));
    }

    return MusicIntelligenceSummary(
      topArtistThisMonth: topArtistMonth,
      topArtistMinutes: (topArtistSecs / 60).round(),
      mostActiveDayOfWeek: mostActiveDayName,
      favouriteListeningPeriod: favouritePeriod,
      periodChangePercentage: changePct,
      uniqueArtistsCount: uniqueArtists.length,
      uniqueTracksCount: uniqueTracks.length,
      averageSessionDurationMinutes: avgSessionMins,
      currentStreak: currentStreak,
      nextMilestoneStreak: nextMilestone,
      recentlyDiscoveredArtists: recentlyDiscovered,
      insightsList: insightItems,
    );
  }
}
