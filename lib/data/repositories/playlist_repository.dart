import 'dart:convert';
import '../local/app_database.dart';
import '../models/playlist_model.dart';
import '../models/track_model.dart';
import '../../core/utils/id_generator.dart';

class PlaylistRepository {
  final AppDatabase _db;

  PlaylistRepository(this._db);

  Stream<List<PlaylistModel>> watchPlaylists() => _db.watchPlaylists;

  List<PlaylistModel> getAllPlaylists({String? userId}) =>
      _db.getAllPlaylists(userId: userId);

  PlaylistModel? getPlaylistById(String id) => _db.getPlaylistById(id);

  Future<PlaylistModel> createPlaylist({
    required String title,
    String description = '',
    String? coverUrl,
    required String userId,
    bool isPublic = false,
  }) async {
    final now = DateTime.now();
    final playlist = PlaylistModel(
      id: IdGenerator.generatePlaylistId(),
      title: title.trim().isEmpty ? 'My Playlist' : title.trim(),
      description: description.trim(),
      coverUrl: coverUrl,
      userId: userId,
      isPublic: isPublic,
      trackIds: [],
      createdAt: now,
      updatedAt: now,
      isSynced: false,
    );
    await _db.insertOrUpdatePlaylist(playlist);
    return playlist;
  }

  Future<void> updatePlaylist(PlaylistModel playlist) async {
    final updated = playlist.copyWith(updatedAt: DateTime.now());
    await _db.insertOrUpdatePlaylist(updated);
  }

  Future<void> deletePlaylist(String id) => _db.deletePlaylist(id);

  Future<void> addTrackToPlaylist(String playlistId, String trackId) async {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) return;
    if (!playlist.trackIds.contains(trackId)) {
      final updatedTrackIds = List<String>.from(playlist.trackIds)
        ..add(trackId);
      await updatePlaylist(playlist.copyWith(trackIds: updatedTrackIds));
    }
  }

  Future<void> removeTrackFromPlaylist(
      String playlistId, String trackId) async {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) return;
    final updatedTrackIds = List<String>.from(playlist.trackIds)
      ..remove(trackId);
    await updatePlaylist(playlist.copyWith(trackIds: updatedTrackIds));
  }

  Future<void> reorderTracksInPlaylist(
      String playlistId, int oldIndex, int newIndex) async {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) {
      return;
    }
    final list = List<String>.from(playlist.trackIds);
    if (oldIndex < 0 ||
        oldIndex >= list.length ||
        newIndex < 0 ||
        newIndex > list.length) {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await updatePlaylist(playlist.copyWith(trackIds: list));
  }

  List<TrackModel> getTracksForPlaylist(String playlistId) {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) return [];
    final allTracks = _db.getAllTracks();
    final trackMap = {for (final t in allTracks) t.id: t};
    return playlist.trackIds
        .map((id) => trackMap[id])
        .whereType<TrackModel>()
        .toList();
  }

  // ===========================================================================
  // SMART PLAYLISTS & INTELLIGENCE
  // ===========================================================================

  /// Generates a dynamic playlist of recently played tracks from session history
  List<TrackModel> getRecentlyPlayedTracks({int limit = 20}) {
    final sessions = _db.getAllSessions();
    final allTracks = _db.getAllTracks();
    final trackMap = {for (final t in allTracks) t.id: t};

    final seenTrackIds = <String>{};
    final recentTracks = <TrackModel>[];

    for (final s in sessions) {
      if (!seenTrackIds.contains(s.trackId) && trackMap.containsKey(s.trackId)) {
        seenTrackIds.add(s.trackId);
        recentTracks.add(trackMap[s.trackId]!);
        if (recentTracks.length >= limit) break;
      }
    }
    return recentTracks;
  }

  /// Generates a dynamic playlist of top-played tracks by play count
  List<TrackModel> getMostPlayedTracks({int limit = 20}) {
    final sessions = _db.getAllSessions();
    final allTracks = _db.getAllTracks();
    final trackMap = {for (final t in allTracks) t.id: t};

    final Map<String, int> playCounts = {};
    for (final s in sessions) {
      playCounts[s.trackId] = (playCounts[s.trackId] ?? 0) + 1;
    }

    final sortedTrackIds = playCounts.keys.toList()
      ..sort((a, b) => (playCounts[b] ?? 0).compareTo(playCounts[a] ?? 0));

    return sortedTrackIds
        .map((id) => trackMap[id])
        .whereType<TrackModel>()
        .take(limit)
        .toList();
  }

  /// Generates a genre-specific smart playlist
  List<TrackModel> getSmartPlaylistByGenre(String genre, {int limit = 25}) {
    final allTracks = _db.getAllTracks();
    final q = genre.toLowerCase();
    return allTracks
        .where((t) => t.genre.toLowerCase().contains(q))
        .take(limit)
        .toList();
  }

  /// Exports playlist metadata as standard JSON
  String exportPlaylistAsJson(String playlistId) {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) return '{}';
    final tracks = getTracksForPlaylist(playlistId);

    final data = {
      'app': 'TuneTrack',
      'playlist': playlist.toMap(),
      'tracks': tracks.map((t) => t.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Exports playlist as standard M3U audio playlist format
  String exportPlaylistAsM3u(String playlistId) {
    final playlist = getPlaylistById(playlistId);
    if (playlist == null) return '';
    final tracks = getTracksForPlaylist(playlistId);

    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');
    buffer.writeln('#PLAYLIST:${playlist.title}');

    for (final track in tracks) {
      final durationSecs = (track.durationMs / 1000).round();
      buffer.writeln('#EXTINF:$durationSecs,${track.artistName} - ${track.title}');
      buffer.writeln(track.audioSourceUrl);
    }
    return buffer.toString();
  }
}
