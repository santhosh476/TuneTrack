import '../../services/online/online_music_service.dart';
import '../local/app_database.dart';
import '../models/track_model.dart';

class OnlineMusicRepository {
  final OnlineMusicService _service;
  final AppDatabase _db;

  OnlineMusicRepository(this._service, this._db);

  /// Search online catalogue and cache results for offline browsing
  Future<List<TrackModel>> searchOnlineTracks(String query) async {
    final tracks = await _service.searchTracks(query);
    if (tracks.isNotEmpty) {
      for (final t in tracks) {
        await _db.insertOrUpdateTrack(t);
      }
    }
    return tracks;
  }

  /// Get curated category tracks
  Future<List<TrackModel>> getCategoryTracks(String category) async {
    final tracks = await _service.getCuratedCategory(category);
    if (tracks.isNotEmpty) {
      for (final t in tracks) {
        await _db.insertOrUpdateTrack(t);
      }
    }
    return tracks;
  }

  /// Get featured online tracks
  Future<List<TrackModel>> getFeaturedOnlineTracks() async {
    final tracks = await _service.getFeaturedOnlineTracks();
    if (tracks.isNotEmpty) {
      for (final t in tracks) {
        await _db.insertOrUpdateTrack(t);
      }
    }
    return tracks;
  }

  /// Get all cached online tracks from local database
  List<TrackModel> getCachedOnlineTracks() {
    return _db
        .getAllTracks()
        .where((t) => t.sourceType == AudioSourceType.networkStream)
        .toList();
  }
}
