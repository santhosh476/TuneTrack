import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/data/local/app_database.dart';
import 'package:flutter_application_1/data/models/listening_session_model.dart';
import 'package:flutter_application_1/data/models/stats_summary_model.dart';

void main() {
  group('Stats Summary & Analytics Engine Tests', () {
    late SharedPreferences prefs;
    late AppDatabase db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase(prefs);
    });

    test(
        'Aggregates total listening duration, valid plays, and top tracks accurately',
        () async {
      final now = DateTime.now().toUtc();

      final s1 = ListeningSessionModel(
        id: 's_1',
        userId: 'user_a',
        trackId: 'track_1',
        trackTitle: 'Midnight Echoes',
        artistName: 'Luna Horizon',
        albumName: 'Neon Dreams',
        genre: 'Synthwave',
        playbackSource: 'demo',
        startedAt: now.subtract(const Duration(minutes: 5)),
        endedAt: now.subtract(const Duration(minutes: 2)),
        audibleDurationSeconds: 180,
        isCompleted: true,
      );

      final s2 = ListeningSessionModel(
        id: 's_2',
        userId: 'user_a',
        trackId: 'track_1',
        trackTitle: 'Midnight Echoes',
        artistName: 'Luna Horizon',
        albumName: 'Neon Dreams',
        genre: 'Synthwave',
        playbackSource: 'demo',
        startedAt: now.subtract(const Duration(minutes: 2)),
        endedAt: now,
        audibleDurationSeconds: 120,
        isCompleted: false,
      );

      final s3 = ListeningSessionModel(
        id: 's_3',
        userId: 'user_a',
        trackId: 'track_2',
        trackTitle: 'Cascade of Stars',
        artistName: 'Solaris Wave',
        albumName: 'Cosmic Journey',
        genre: 'Ambient',
        playbackSource: 'demo',
        startedAt: now.subtract(const Duration(minutes: 1)),
        endedAt: now,
        audibleDurationSeconds: 60,
        isCompleted: true,
      );

      await db.recordListeningSession(s1);
      await db.recordListeningSession(s2);
      await db.recordListeningSession(s3);

      final stats = db.getStatsSummary(
        timeRange: StatsTimeRange.week,
        userId: 'user_a',
        dailyGoalMinutes: 30,
      );

      expect(stats.totalListeningSeconds, equals(360)); // 180 + 120 + 60
      expect(stats.validPlaysCount, equals(3));
      expect(stats.completedPlaysCount, equals(2));

      // Top track should be track_1 with 2 plays
      expect(stats.topTracks.isNotEmpty, isTrue);
      expect(stats.topTracks.first.id, equals('track_1'));
      expect(stats.topTracks.first.playCount, equals(2));
      expect(stats.topTracks.first.totalDurationSeconds, equals(300));

      // Top artist should be Luna Horizon
      expect(stats.topArtists.first.title, equals('Luna Horizon'));
    });

    test('User data isolation keeps private listening sessions isolated',
        () async {
      final now = DateTime.now().toUtc();

      final sUserA = ListeningSessionModel(
        id: 's_a',
        userId: 'user_isolated_a',
        trackId: 'track_1',
        trackTitle: 'Track A',
        artistName: 'Artist A',
        albumName: 'Album A',
        genre: 'Pop',
        playbackSource: 'demo',
        startedAt: now,
        endedAt: now,
        audibleDurationSeconds: 100,
      );

      final sUserB = ListeningSessionModel(
        id: 's_b',
        userId: 'user_isolated_b',
        trackId: 'track_2',
        trackTitle: 'Track B',
        artistName: 'Artist B',
        albumName: 'Album B',
        genre: 'Rock',
        playbackSource: 'demo',
        startedAt: now,
        endedAt: now,
        audibleDurationSeconds: 200,
      );

      await db.recordListeningSession(sUserA);
      await db.recordListeningSession(sUserB);

      final sessionsA = db.getAllSessions(userId: 'user_isolated_a');
      final sessionsB = db.getAllSessions(userId: 'user_isolated_b');

      expect(sessionsA.any((s) => s.userId == 'user_isolated_b'), isFalse);
      expect(sessionsB.any((s) => s.userId == 'user_isolated_a'), isFalse);
    });
  });
}
