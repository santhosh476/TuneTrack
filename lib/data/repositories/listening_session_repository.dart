import '../local/app_database.dart';
import '../models/listening_session_model.dart';
import '../models/stats_summary_model.dart';

class ListeningSessionRepository {
  final AppDatabase _db;

  ListeningSessionRepository(this._db);

  Stream<List<ListeningSessionModel>> watchSessions() => _db.watchSessions;

  List<ListeningSessionModel> getAllSessions({String? userId}) =>
      _db.getAllSessions(userId: userId);

  Future<void> recordSession(ListeningSessionModel session) =>
      _db.recordListeningSession(session);

  StatsSummaryModel getStats({
    required StatsTimeRange timeRange,
    String? userId,
    int dailyGoalMinutes = 45,
  }) {
    return _db.getStatsSummary(
      timeRange: timeRange,
      userId: userId,
      dailyGoalMinutes: dailyGoalMinutes,
    );
  }

  Future<void> clearHistory({String? userId}) =>
      _db.clearListeningHistory(userId: userId);

  String exportJson(String userId) => _db.exportAllUserDataAsJson(userId);
}
