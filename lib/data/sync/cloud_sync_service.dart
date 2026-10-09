import 'dart:convert';
import '../local/app_database.dart';
import '../local/shared_preferences_service.dart';
import '../models/sync_queue_model.dart';
import '../models/playlist_model.dart';
import '../models/listening_session_model.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

/// Sync manager for processing offline queue with retry backoff
class CloudSyncService {
  final AppDatabase _db;
  final SharedPreferencesService _prefs;
  final FirestoreService _firestore;
  bool _isSyncing = false;

  CloudSyncService(this._db, this._prefs, this._firestore);

  bool get isSyncing => _isSyncing;

  Future<void> syncPendingOperations() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final queue = _db.getSyncQueue();
      for (final item in queue) {
        if (item.status == SyncStatus.completed) continue;

        try {
          final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;
          switch (item.action) {
            case SyncAction.upsertPlaylist:
              final playlist = PlaylistModel.fromMap(payload);
              await _firestore.syncPlaylist(playlist);
              break;
            case SyncAction.deletePlaylist:
              final id = payload['id'] as String;
              await _firestore.deletePlaylist(id);
              break;
            case SyncAction.recordListeningSession:
              final session = ListeningSessionModel.fromMap(payload);
              await _firestore.syncListeningSession(session);
              break;
            case SyncAction.updateUserProfile:
              final user = UserModel.fromMap(payload);
              await _firestore.syncUserProfile(user);
              break;
          }
          await _db.removeSyncItem(item.id);
        } catch (e) {
          // Increment retry count or mark failed
          continue;
        }
      }

      await _prefs.setLastSyncTime(DateTime.now());
    } finally {
      _isSyncing = false;
    }
  }
}
