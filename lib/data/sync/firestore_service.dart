import '../models/playlist_model.dart';
import '../models/listening_session_model.dart';
import '../models/user_model.dart';

/// Firestore cloud data service contract & implementation with offline handling
class FirestoreService {
  /// Upload or update a user's playlist in Firestore
  Future<void> syncPlaylist(PlaylistModel playlist) async {
    // In production with Firebase configured, this interacts with:
    // FirebaseFirestore.instance.collection('playlists').doc(playlist.id).set(playlist.toMap(), SetOptions(merge: true))
  }

  /// Delete a playlist from Firestore
  Future<void> deletePlaylist(String playlistId) async {
    // FirebaseFirestore.instance.collection('playlists').doc(playlistId).delete()
  }

  /// Sync listening session event or summary
  Future<void> syncListeningSession(ListeningSessionModel session) async {
    // FirebaseFirestore.instance.collection('users').doc(session.userId).collection('sessions').doc(session.id).set(session.toMap())
  }

  /// Sync user profile & preferences
  Future<void> syncUserProfile(UserModel user) async {
    // FirebaseFirestore.instance.collection('users').doc(user.id).set(user.toMap(), SetOptions(merge: true))
  }
}
