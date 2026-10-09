import '../local/app_database.dart';
import '../local/shared_preferences_service.dart';
import '../models/user_model.dart';

class UserRepository {
  final AppDatabase _db;
  final SharedPreferencesService _prefs;

  UserRepository(this._db, this._prefs);

  String getActiveUserId() => _prefs.getActiveUserId();

  UserModel getActiveUser() {
    final id = getActiveUserId();
    final stored = _db.getUser(id);
    if (stored != null) return stored;

    final isGuest = id.startsWith('gst_') || id == 'guest';
    return UserModel(
      id: id,
      displayName: isGuest ? 'Guest Listener' : 'TuneTrack Listener',
      isGuest: isGuest,
      dailyGoalMinutes: _prefs.getDailyGoalMinutes(),
      createdAt: DateTime.now(),
    );
  }

  Future<void> saveUser(UserModel user) async {
    await _db.saveUser(user);
    await _prefs.setActiveUserId(user.id);
  }

  Future<void> updateDailyGoal(int minutes) async {
    await _prefs.setDailyGoalMinutes(minutes);
    final current = getActiveUser();
    await saveUser(current.copyWith(dailyGoalMinutes: minutes));
  }

  Future<void> mergeGuestIntoUser(String userId) async {
    await _db.mergeGuestDataIntoUser(userId);
  }

  Future<void> logout() async {
    final newGuestId = _prefs.getOrCreateGuestId();
    await _prefs.setActiveUserId(newGuestId);
  }
}
