import '../../data/models/user_model.dart';

abstract class AuthInterface {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
  Future<UserModel> signInAsGuest();
  Future<UserModel> signInWithGoogle({
    String? idToken,
    String? accessToken,
    String? displayName,
    String? email,
    String? photoUrl,
  });
  Future<void> sendPhoneOtp(
    String phoneNumber, {
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String error) onError,
  });
  Future<UserModel> verifyPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? displayName,
  });
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> registerWithEmailAndPassword(
      String email, String password, String displayName);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> updateUserLanguages(
      List<String> languages, String primaryLanguage);
  Future<void> signOut();
  Future<void> deleteAccount();
}
