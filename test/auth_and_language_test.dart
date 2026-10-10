import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/data/local/app_database.dart';
import 'package:flutter_application_1/data/local/shared_preferences_service.dart';
import 'package:flutter_application_1/services/authentication/firebase_auth_service.dart';

void main() {
  group('Authentication & Language Personalization Tests', () {
    late SharedPreferences rawPrefs;
    late SharedPreferencesService prefs;
    late AppDatabase db;
    late FirebaseAuthService authService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      rawPrefs = await SharedPreferences.getInstance();
      prefs = SharedPreferencesService(rawPrefs);
      db = AppDatabase(rawPrefs);
      authService = FirebaseAuthService(db, prefs);
    });

    test('Guest Sign-In creates persistent guest user with default languages',
        () async {
      final guest = await authService.signInAsGuest();
      expect(guest.isGuest, isTrue);
      expect(guest.authProvider, 'guest');
      expect(guest.preferredLanguages, contains('Tamil'));
      expect(guest.preferredLanguages, contains('English'));
      expect(guest.primaryLanguage, 'Tamil');

      final activeId = prefs.getActiveUserId();
      expect(activeId.startsWith('gst_'), isTrue);
      expect(authService.currentUser?.id, guest.id);
    });

    test('Google Sign-In creates authenticated user and saves profile details',
        () async {
      final googleUser = await authService.signInWithGoogle(
        displayName: 'Santhosh Tech',
        email: 'santhosh@gmail.com',
        photoUrl: 'https://example.com/avatar.jpg',
      );

      expect(googleUser.isGuest, isFalse);
      expect(googleUser.authProvider, 'google');
      expect(googleUser.displayName, 'Santhosh Tech');
      expect(googleUser.email, 'santhosh@gmail.com');
      expect(googleUser.photoUrl, 'https://example.com/avatar.jpg');

      final savedUser = db.getUser(googleUser.id);
      expect(savedUser, isNotNull);
      expect(savedUser?.displayName, 'Santhosh Tech');
    });

    test(
        'Phone Auth OTP sends verificationId and verifies 6-digit code correctly',
        () async {
      String? generatedVerId;
      await authService.sendPhoneOtp(
        '+919876543210',
        onCodeSent: (verId, token) {
          generatedVerId = verId;
        },
        onError: (err) {
          fail('Should not produce error on valid phone: $err');
        },
      );

      expect(generatedVerId, isNotNull);
      expect(generatedVerId!.startsWith('ver_'), isTrue);

      // Verify with invalid OTP (< 6 digits) fails
      expect(
        () => authService.verifyPhoneOtp(
          verificationId: generatedVerId!,
          smsCode: '123',
        ),
        throwsException,
      );

      // Verify with valid 6-digit OTP succeeds
      final phoneUser = await authService.verifyPhoneOtp(
        verificationId: generatedVerId!,
        smsCode: '582910',
        displayName: 'Tamil Dev',
      );

      expect(phoneUser.isGuest, isFalse);
      expect(phoneUser.authProvider, 'phone');
      expect(phoneUser.phoneNumber, '+919876543210');
      expect(phoneUser.displayName, 'Tamil Dev');
    });

    test(
        'Language personalization persists multiple languages and updates primary',
        () async {
      final newLanguages = ['Tamil', 'Telugu', 'Malayalam', 'Hindi'];
      const newPrimary = 'Telugu';

      await authService.updateUserLanguages(newLanguages, newPrimary);

      final savedLangs = prefs.getPreferredLanguages();
      final savedPrimary = prefs.getPrimaryLanguage();

      expect(savedLangs, newLanguages);
      expect(savedPrimary, newPrimary);
      expect(authService.currentUser?.preferredLanguages, newLanguages);
      expect(authService.currentUser?.primaryLanguage, newPrimary);
    });

    test('Sign out resets user state safely to guest mode', () async {
      await authService.signInWithGoogle(
        displayName: 'Test User',
        email: 'test@example.com',
      );
      expect(authService.currentUser?.isGuest, isFalse);

      await authService.signOut();
      expect(authService.currentUser?.isGuest, isTrue);
      expect(authService.currentUser?.authProvider, 'guest');
    });
  });
}
