import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/core/utils/id_generator.dart';
import 'package:flutter_application_1/data/local/app_database.dart';
import 'package:flutter_application_1/data/models/listening_session_model.dart';
import 'package:flutter_application_1/features/tracker/listening_tracker_service.dart';

void main() {
  group('Listening Tracker & Qualification Tests', () {
    late SharedPreferences prefs;
    late AppDatabase db;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      db = AppDatabase(prefs);
    });

    test('30-second minimum threshold qualifies valid play', () {
      // Plays < 30 seconds without finishing are invalid
      expect(ListeningTrackerService.calculateIsValidPlay(10, false), isFalse);
      expect(ListeningTrackerService.calculateIsValidPlay(29, false), isFalse);

      // Plays >= 30 seconds are valid plays
      expect(ListeningTrackerService.calculateIsValidPlay(30, false), isTrue);
      expect(ListeningTrackerService.calculateIsValidPlay(120, false), isTrue);
    });

    test('Completed short track qualifies as valid play regardless of duration',
        () {
      // Even if played for only 15 seconds, completing the track counts
      expect(ListeningTrackerService.calculateIsValidPlay(15, true), isTrue);
    });

    test('Listening sessions are recorded idempotently without duplicates',
        () async {
      final now = DateTime.now().toUtc();
      final sessionId = IdGenerator.generateSessionId();

      final session = ListeningSessionModel(
        id: sessionId,
        userId: 'test_user_1',
        trackId: 'demo_trk_1',
        trackTitle: 'Midnight Echoes',
        artistName: 'Luna Horizon',
        albumName: 'Neon Dreams',
        genre: 'Synthwave',
        playbackSource: 'demo',
        startedAt: now.subtract(const Duration(seconds: 45)),
        endedAt: now,
        audibleDurationSeconds: 45,
        isCompleted: true,
        isSynced: false,
      );

      // Record session once
      await db.recordListeningSession(session);
      var sessions = db.getAllSessions(userId: 'test_user_1');
      expect(sessions.length, equals(1));
      expect(sessions.first.id, equals(sessionId));

      // Record duplicate session with same event ID (idempotency check)
      await db.recordListeningSession(session);
      sessions = db.getAllSessions(userId: 'test_user_1');
      expect(sessions.length, equals(1),
          reason: 'Duplicate event IDs must not create duplicate records');
    });
  });
}
