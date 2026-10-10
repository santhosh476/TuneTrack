import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/id_generator.dart';

/// Wrapper service for SharedPreferences persistence
class SharedPreferencesService {
  final SharedPreferences _prefs;

  SharedPreferencesService(this._prefs);

  static Future<SharedPreferencesService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return SharedPreferencesService(prefs);
  }

  /// Get or initialize stable anonymous Guest ID
  String getOrCreateGuestId() {
    var guestId = _prefs.getString(AppConstants.keyGuestId);
    if (guestId == null || guestId.isEmpty) {
      guestId = IdGenerator.generateGuestId();
      _prefs.setString(AppConstants.keyGuestId, guestId);
    }
    return guestId;
  }

  /// Get current active user ID (or guest ID if unauthenticated)
  String getActiveUserId() {
    final userId = _prefs.getString(AppConstants.keyUserId);
    if (userId != null && userId.isNotEmpty) {
      return userId;
    }
    return getOrCreateGuestId();
  }

  Future<bool> setActiveUserId(String? userId) async {
    if (userId == null || userId.isEmpty) {
      return _prefs.remove(AppConstants.keyUserId);
    }
    return _prefs.setString(AppConstants.keyUserId, userId);
  }

  int getDailyGoalMinutes() {
    return _prefs.getInt(AppConstants.keyDailyGoalMinutes) ??
        AppConstants.defaultDailyGoalMinutes;
  }

  Future<bool> setDailyGoalMinutes(int minutes) {
    return _prefs.setInt(AppConstants.keyDailyGoalMinutes, minutes);
  }

  bool isDarkMode() {
    return _prefs.getBool(AppConstants.keyThemeMode) ?? true;
  }

  Future<bool> setDarkMode(bool isDark) {
    return _prefs.setBool(AppConstants.keyThemeMode, isDark);
  }

  DateTime? getLastSyncTime() {
    final iso = _prefs.getString(AppConstants.keyLastSyncTime);
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  Future<bool> setLastSyncTime(DateTime time) {
    return _prefs.setString(
        AppConstants.keyLastSyncTime, time.toUtc().toIso8601String());
  }

  // ==========================================
  // ONBOARDING & AUTHENTICATION STATE
  // ==========================================

  bool isOnboardingCompleted() {
    return _prefs.getBool('is_onboarding_completed') ?? false;
  }

  Future<bool> setOnboardingCompleted(bool completed) {
    return _prefs.setBool('is_onboarding_completed', completed);
  }

  bool isLanguageOnboardingCompleted() {
    return _prefs.getBool('is_language_onboarding_completed') ?? false;
  }

  Future<bool> setLanguageOnboardingCompleted(bool completed) {
    return _prefs.setBool('is_language_onboarding_completed', completed);
  }

  String getAuthProvider() {
    return _prefs.getString('auth_provider') ?? 'guest';
  }

  Future<bool> setAuthProvider(String provider) {
    return _prefs.setString('auth_provider', provider);
  }

  // ==========================================
  // LANGUAGE PERSONALIZATION
  // ==========================================

  List<String> getPreferredLanguages() {
    return _prefs.getStringList('preferred_music_languages') ??
        ['Tamil', 'English'];
  }

  Future<bool> setPreferredLanguages(List<String> languages) {
    return _prefs.setStringList('preferred_music_languages', languages);
  }

  String getPrimaryLanguage() {
    final list = getPreferredLanguages();
    if (list.isNotEmpty) {
      return _prefs.getString('primary_music_language') ?? list.first;
    }
    return 'Tamil';
  }

  Future<bool> setPrimaryLanguage(String language) {
    return _prefs.setString('primary_music_language', language);
  }

  List<String> getRecentSearches() {
    return _prefs.getStringList('recent_searches') ?? [];
  }

  Future<bool> addRecentSearch(String query) async {
    final list = getRecentSearches();
    list.remove(query);
    list.insert(0, query);
    if (list.length > 10) list.removeLast();
    return _prefs.setStringList('recent_searches', list);
  }

  Future<bool> clearRecentSearches() {
    return _prefs.remove('recent_searches');
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
