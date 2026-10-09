import 'dart:async';
import '../../core/errors/app_exceptions.dart';
import '../../data/local/app_database.dart';
import '../../data/local/shared_preferences_service.dart';
import '../../data/models/user_model.dart';
import 'auth_interface.dart';

/// Firebase Auth Service with local-first offline fallback
class FirebaseAuthService implements AuthInterface {
  final AppDatabase _db;
  final SharedPreferencesService _prefs;
  final _authController = StreamController<UserModel?>.broadcast();
  UserModel? _currentUser;

  FirebaseAuthService(this._db, this._prefs) {
    _initUser();
  }

  void _initUser() {
    final activeId = _prefs.getActiveUserId();
    final stored = _db.getUser(activeId);
    if (stored != null) {
      _currentUser = stored;
    } else {
      _currentUser = UserModel(
        id: activeId,
        displayName: activeId.startsWith('gst_')
            ? 'Guest Listener'
            : 'TuneTrack Listener',
        isGuest: true,
        dailyGoalMinutes: _prefs.getDailyGoalMinutes(),
        createdAt: DateTime.now(),
      );
    }
    _authController.add(_currentUser);
  }

  @override
  Stream<UserModel?> get authStateChanges => _authController.stream;

  @override
  UserModel? get currentUser => _currentUser;

  @override
  Future<UserModel> signInAsGuest() async {
    final guestId = _prefs.getOrCreateGuestId();
    await _prefs.setActiveUserId(guestId);
    _currentUser = UserModel(
      id: guestId,
      displayName: 'Guest Listener',
      isGuest: true,
      dailyGoalMinutes: _prefs.getDailyGoalMinutes(),
      createdAt: DateTime.now(),
    );
    await _db.saveUser(_currentUser!);
    _authController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserModel> signInWithEmailAndPassword(
      String email, String password) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      throw const AuthException('Please enter a valid email address');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters');
    }

    final userId = 'usr_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    final existingUser = _db.getUser(userId);

    _currentUser = existingUser ??
        UserModel(
          id: userId,
          email: email.trim(),
          displayName: email.split('@').first,
          isGuest: false,
          dailyGoalMinutes: _prefs.getDailyGoalMinutes(),
          createdAt: DateTime.now(),
        );

    await _db.saveUser(_currentUser!);
    await _prefs.setActiveUserId(_currentUser!.id);

    // Merge guest history into user
    await _db.mergeGuestDataIntoUser(_currentUser!.id);

    _authController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<UserModel> registerWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      throw const AuthException('Please enter a valid email address');
    }
    if (password.length < 6) {
      throw const AuthException('Password must be at least 6 characters');
    }

    final userId = 'usr_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}';
    _currentUser = UserModel(
      id: userId,
      email: email.trim(),
      displayName: displayName.trim().isEmpty
          ? email.split('@').first
          : displayName.trim(),
      isGuest: false,
      dailyGoalMinutes: _prefs.getDailyGoalMinutes(),
      createdAt: DateTime.now(),
    );

    await _db.saveUser(_currentUser!);
    await _prefs.setActiveUserId(_currentUser!.id);

    // Merge guest data into the newly created account
    await _db.mergeGuestDataIntoUser(_currentUser!.id);

    _authController.add(_currentUser);
    return _currentUser!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (email.trim().isEmpty || !email.contains('@')) {
      throw const AuthException('Please provide a valid registered email');
    }
    // Simulates sending reset email safely
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<void> signOut() async {
    final guestId = _prefs.getOrCreateGuestId();
    await _prefs.setActiveUserId(guestId);
    _currentUser = UserModel(
      id: guestId,
      displayName: 'Guest Listener',
      isGuest: true,
      dailyGoalMinutes: _prefs.getDailyGoalMinutes(),
      createdAt: DateTime.now(),
    );
    _authController.add(_currentUser);
  }

  @override
  Future<void> deleteAccount() async {
    if (_currentUser != null) {
      await _db.clearListeningHistory(userId: _currentUser!.id);
      await signOut();
    }
  }
}
