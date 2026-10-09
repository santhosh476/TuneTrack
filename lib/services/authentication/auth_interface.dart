import '../../data/models/user_model.dart';

abstract class AuthInterface {
  Stream<UserModel?> get authStateChanges;
  UserModel? get currentUser;
  Future<UserModel> signInAsGuest();
  Future<UserModel> signInWithEmailAndPassword(String email, String password);
  Future<UserModel> registerWithEmailAndPassword(
      String email, String password, String displayName);
  Future<void> sendPasswordResetEmail(String email);
  Future<void> signOut();
  Future<void> deleteAccount();
}
