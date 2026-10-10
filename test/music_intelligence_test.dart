import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/models/listening_session_model.dart';
import 'package:flutter_application_1/features/stats/music_intelligence_service.dart';

void main() {
  group('MusicIntelligenceService Tests', () {
    test(
        'generateInsights produces default summary when session history is empty',
        () {
      final summary = MusicIntelligenceService.generateInsights(
        sessions: [],
        currentStreak: 0,
        longestStreak: 0,
      );
      expect(summary.uniqueArtistsCount, equals(0));
      expect(summary.uniqueTracksCount, equals(0));
      expect(summary.insightsList.isEmpty, isTrue);
    });

    test(
        'generateInsights correctly identifies peak listening day, top artist, and habits',
        () {
      final now = DateTime.now();
      final sessions = [
        ListeningSessionModel(
          id: 's1',
          userId: 'test_user',
          trackId: 't1',
          trackTitle: 'Midnight City',
          artistName: 'M83',
          albumName: 'Hurry Up, We\'re Dreaming',
          genre: 'Electronic',
          playbackSource: 'local',
          startedAt: now.subtract(const Duration(days: 1)),
          endedAt: now
              .subtract(const Duration(days: 1))
              .add(const Duration(seconds: 120)),
          audibleDurationSeconds: 120,
          isCompleted: true,
        ),
        ListeningSessionModel(
          id: 's2',
          userId: 'test_user',
          trackId: 't2',
          trackTitle: 'Wait',
          artistName: 'M83',
          albumName: 'Hurry Up, We\'re Dreaming',
          genre: 'Electronic',
          playbackSource: 'local',
          startedAt: now.subtract(const Duration(days: 1)),
          endedAt: now
              .subtract(const Duration(days: 1))
              .add(const Duration(seconds: 180)),
          audibleDurationSeconds: 180,
          isCompleted: true,
        ),
        ListeningSessionModel(
          id: 's3',
          userId: 'test_user',
          trackId: 't3',
          trackTitle: 'Starboy',
          artistName: 'The Weeknd',
          albumName: 'Starboy',
          genre: 'R&B',
          playbackSource: 'local',
          startedAt: now.subtract(const Duration(days: 2)),
          endedAt: now
              .subtract(const Duration(days: 2))
              .add(const Duration(seconds: 200)),
          audibleDurationSeconds: 200,
          isCompleted: true,
        ),
      ];

      final summary = MusicIntelligenceService.generateInsights(
        sessions: sessions,
        currentStreak: 5,
        longestStreak: 10,
      );

      expect(summary.uniqueArtistsCount, equals(2));
      expect(summary.uniqueTracksCount, equals(3));
      expect(summary.topArtistThisMonth, equals('M83'));
      expect(summary.topArtistMinutes, equals(5)); // (120 + 180) / 60 = 5
      expect(summary.currentStreak, equals(5));
      expect(summary.nextMilestoneStreak, equals(7));
      expect(summary.insightsList.isNotEmpty, isTrue);

      final topArtistInsight =
          summary.insightsList.firstWhere((i) => i.id == 'ins_top_artist');
      expect(topArtistInsight.subtitle, equals('M83'));

      final peakDayInsight =
          summary.insightsList.firstWhere((i) => i.id == 'ins_active_day');
      expect(peakDayInsight.metricValue, isNotEmpty);
    });
  });
}
