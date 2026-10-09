import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/id_generator.dart';
import '../models/track_model.dart';
import '../models/playlist_model.dart';
import '../models/listening_session_model.dart';
import '../models/user_model.dart';
import '../models/sync_queue_model.dart';
import '../models/stats_summary_model.dart';

/// Local-first persistence engine for TuneTrack
/// Provides atomic operations, offline querying, analytics aggregation, and data isolation
class AppDatabase {
  final SharedPreferences _prefs;

  // In-memory reactive state streams
  final _tracksStreamController =
      StreamController<List<TrackModel>>.broadcast();
  final _playlistsStreamController =
      StreamController<List<PlaylistModel>>.broadcast();
  final _favouritesStreamController =
      StreamController<List<String>>.broadcast();
  final _sessionsStreamController =
      StreamController<List<ListeningSessionModel>>.broadcast();

  // Storage Keys
  static const String _keyTracks = 'tunetrack_db_tracks';
  static const String _keyPlaylists = 'tunetrack_db_playlists';
  static const String _keyFavourites = 'tunetrack_db_favourites';
  static const String _keySessions = 'tunetrack_db_sessions';
  static const String _keyUsers = 'tunetrack_db_users';
  static const String _keySyncQueue = 'tunetrack_db_sync_queue';
  static const String _keySeeded = 'tunetrack_db_seeded_v1';

  AppDatabase(this._prefs) {
    _initDefaults();
  }

  Stream<List<TrackModel>> get watchTracks => _tracksStreamController.stream;
  Stream<List<PlaylistModel>> get watchPlaylists =>
      _playlistsStreamController.stream;
  Stream<List<String>> get watchFavourites =>
      _favouritesStreamController.stream;
  Stream<List<ListeningSessionModel>> get watchSessions =>
      _sessionsStreamController.stream;

  void _initDefaults() {
    if (!_prefs.containsKey(_keySeeded)) {
      _seedDemoData();
      _prefs.setBool(_keySeeded, true);
    }
  }

  /// Initial sample catalog with reliable, royalty-free audio streams for instant testing
  void _seedDemoData() {
    final now = DateTime.now();
    final demoTracks = [
      TrackModel(
        id: 'demo_trk_1',
        title: 'Midnight Echoes',
        artistName: 'Luna Horizon',
        albumName: 'Neon Dreams',
        durationMs: 198000,
        artworkUrl:
            'https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=500&q=80',
        sourceType: AudioSourceType.demoAsset,
        audioSourceUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        isFavourite: true,
        genre: 'Synthwave',
        addedAt: now.subtract(const Duration(days: 3)),
      ),
      TrackModel(
        id: 'demo_trk_2',
        title: 'Cascade of Stars',
        artistName: 'Solaris Wave',
        albumName: 'Cosmic Journey',
        durationMs: 245000,
        artworkUrl:
            'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=500&q=80',
        sourceType: AudioSourceType.demoAsset,
        audioSourceUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
        isFavourite: true,
        genre: 'Ambient',
        addedAt: now.subtract(const Duration(days: 2)),
      ),
      TrackModel(
        id: 'demo_trk_3',
        title: 'Urban Sunset Groove',
        artistName: 'Velvet Rhythm',
        albumName: 'Downtown Sessions',
        durationMs: 210000,
        artworkUrl:
            'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80',
        sourceType: AudioSourceType.demoAsset,
        audioSourceUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
        isFavourite: false,
        genre: 'Lofi / Jazz',
        addedAt: now.subtract(const Duration(days: 1)),
      ),
      TrackModel(
        id: 'demo_trk_4',
        title: 'Emerald Forest',
        artistName: 'Komorebi Sound',
        albumName: 'Nature Reverie',
        durationMs: 184000,
        artworkUrl:
            'https://images.unsplash.com/photo-1448375240586-882707db888b?w=500&q=80',
        sourceType: AudioSourceType.demoAsset,
        audioSourceUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3',
        isFavourite: false,
        genre: 'Acoustic',
        addedAt: now,
      ),
      TrackModel(
        id: 'demo_trk_5',
        title: 'Cyberpunk Drive',
        artistName: 'Luna Horizon',
        albumName: 'Neon Dreams',
        durationMs: 220000,
        artworkUrl:
            'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=500&q=80',
        sourceType: AudioSourceType.demoAsset,
        audioSourceUrl:
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3',
        isFavourite: true,
        genre: 'Electronic',
        addedAt: now,
      ),
    ];

    saveTracks(demoTracks);

    final demoPlaylists = [
      PlaylistModel(
        id: 'demo_ply_1',
        title: 'Deep Focus & Flow',
        description:
            'Atmospheric electronic & ambient beats for deep coding sessions',
        coverUrl:
            'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=500&q=80',
        userId: 'guest',
        isPublic: true,
        isFavourite: true,
        trackIds: ['demo_trk_1', 'demo_trk_2', 'demo_trk_5'],
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now,
      ),
      PlaylistModel(
        id: 'demo_ply_2',
        title: 'Night Shift Lofi',
        description:
            'Smooth melodies and chill vibes for late evening relaxation',
        coverUrl:
            'https://images.unsplash.com/photo-1511671782779-c97d3d27a1d4?w=500&q=80',
        userId: 'guest',
        isPublic: true,
        isFavourite: false,
        trackIds: ['demo_trk_3', 'demo_trk_4'],
        createdAt: now.subtract(const Duration(days: 4)),
        updatedAt: now,
      ),
    ];

    savePlaylists(demoPlaylists);
  }

  // ==========================================
  // TRACKS
  // ==========================================

  List<TrackModel> getAllTracks() {
    final rawList = _prefs.getStringList(_keyTracks) ?? [];
    return rawList
        .map((str) =>
            TrackModel.fromMap(jsonDecode(str) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveTracks(List<TrackModel> tracks) async {
    final rawList = tracks.map((t) => jsonEncode(t.toMap())).toList();
    await _prefs.setStringList(_keyTracks, rawList);
    _tracksStreamController.add(tracks);
  }

  Future<void> insertOrUpdateTrack(TrackModel track) async {
    final tracks = getAllTracks();
    final index = tracks.indexWhere((t) => t.id == track.id);
    if (index >= 0) {
      tracks[index] = track;
    } else {
      tracks.insert(0, track);
    }
    await saveTracks(tracks);
  }

  Future<void> deleteTrack(String trackId) async {
    final tracks = getAllTracks();
    tracks.removeWhere((t) => t.id == trackId);
    await saveTracks(tracks);
  }

  TrackModel? getTrackById(String trackId) {
    final tracks = getAllTracks();
    try {
      return tracks.firstWhere((t) => t.id == trackId);
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // PLAYLISTS
  // ==========================================

  List<PlaylistModel> getAllPlaylists({String? userId}) {
    final rawList = _prefs.getStringList(_keyPlaylists) ?? [];
    final all = rawList
        .map((str) =>
            PlaylistModel.fromMap(jsonDecode(str) as Map<String, dynamic>))
        .toList();
    if (userId != null && userId.isNotEmpty) {
      return all
          .where((p) => p.userId == userId || p.userId == 'guest' || p.isPublic)
          .toList();
    }
    return all;
  }

  Future<void> savePlaylists(List<PlaylistModel> playlists) async {
    final rawList = playlists.map((p) => jsonEncode(p.toMap())).toList();
    await _prefs.setStringList(_keyPlaylists, rawList);
    _playlistsStreamController.add(playlists);
  }

  Future<void> insertOrUpdatePlaylist(PlaylistModel playlist) async {
    final playlists = getAllPlaylists();
    final index = playlists.indexWhere((p) => p.id == playlist.id);
    if (index >= 0) {
      playlists[index] = playlist;
    } else {
      playlists.insert(0, playlist);
    }
    await savePlaylists(playlists);
  }

  Future<void> deletePlaylist(String playlistId) async {
    final playlists = getAllPlaylists();
    playlists.removeWhere((p) => p.id == playlistId);
    await savePlaylists(playlists);
  }

  PlaylistModel? getPlaylistById(String playlistId) {
    final playlists = getAllPlaylists();
    try {
      return playlists.firstWhere((p) => p.id == playlistId);
    } catch (_) {
      return null;
    }
  }

  // ==========================================
  // FAVOURITES
  // ==========================================

  List<String> getFavouriteTrackIds() {
    return _prefs.getStringList(_keyFavourites) ??
        ['demo_trk_1', 'demo_trk_2', 'demo_trk_5'];
  }

  Future<bool> toggleFavourite(String trackId) async {
    final favs = getFavouriteTrackIds();
    bool isNowFav;
    if (favs.contains(trackId)) {
      favs.remove(trackId);
      isNowFav = false;
    } else {
      favs.add(trackId);
      isNowFav = true;
    }
    await _prefs.setStringList(_keyFavourites, favs);
    _favouritesStreamController.add(favs);

    // Update track model state if present
    final track = getTrackById(trackId);
    if (track != null) {
      await insertOrUpdateTrack(track.copyWith(isFavourite: isNowFav));
    }
    return isNowFav;
  }

  bool isTrackFavourite(String trackId) {
    return getFavouriteTrackIds().contains(trackId);
  }

  // ==========================================
  // LISTENING SESSIONS (Core Tracker & Stats)
  // ==========================================

  List<ListeningSessionModel> getAllSessions({String? userId}) {
    final rawList = _prefs.getStringList(_keySessions) ?? [];
    final all = rawList
        .map((str) => ListeningSessionModel.fromMap(
            jsonDecode(str) as Map<String, dynamic>))
        .toList();
    if (userId != null && userId.isNotEmpty) {
      return all
          .where((s) => s.userId == userId || s.userId == 'guest')
          .toList();
    }
    return all;
  }

  Future<void> recordListeningSession(ListeningSessionModel session) async {
    final sessions = getAllSessions();
    // Idempotent write: ensure no duplicate event ID
    final existingIndex = sessions.indexWhere((s) => s.id == session.id);
    if (existingIndex >= 0) {
      sessions[existingIndex] = session;
    } else {
      sessions.insert(0, session);
    }
    final rawList = sessions.map((s) => jsonEncode(s.toMap())).toList();
    await _prefs.setStringList(_keySessions, rawList);
    _sessionsStreamController.add(sessions);

    // Also queue for cloud sync
    await enqueueSync(
      action: SyncAction.recordListeningSession,
      payload: session.toMap(),
    );
  }

  /// Calculates real-time analytics for any timeframe with timezone awareness
  StatsSummaryModel getStatsSummary({
    required StatsTimeRange timeRange,
    String? userId,
    int dailyGoalMinutes = 45,
  }) {
    final allSessions = getAllSessions(userId: userId);
    final now = DateTime.now();

    DateTime cutoff;
    switch (timeRange) {
      case StatsTimeRange.day:
        cutoff = DateTime(now.year, now.month, now.day);
        break;
      case StatsTimeRange.week:
        cutoff = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        break;
      case StatsTimeRange.month:
        cutoff = DateTime(now.year, now.month, 1);
        break;
      case StatsTimeRange.year:
        cutoff = DateTime(now.year, 1, 1);
        break;
      case StatsTimeRange.allTime:
        cutoff = DateTime(2000, 1, 1);
        break;
    }

    // Filter sessions strictly within local timeframe
    final filteredSessions = allSessions
        .where((s) => s.startedAt.toLocal().isAfter(cutoff))
        .toList();

    int totalDurationSeconds = 0;
    int validPlays = 0;
    int completedPlays = 0;

    final Map<String, _TrackAggregator> trackAgg = {};
    final Map<String, _ArtistAggregator> artistAgg = {};
    final Map<String, _AlbumAggregator> albumAgg = {};
    final Map<String, int> genreMap = {};

    for (final s in filteredSessions) {
      totalDurationSeconds += s.audibleDurationSeconds;
      if (s.isValidPlay) validPlays++;
      if (s.isCompleted) completedPlays++;

      // Track aggregation
      trackAgg.putIfAbsent(
          s.trackId,
          () => _TrackAggregator(
              s.trackId, s.trackTitle, s.artistName, s.artworkUrl));
      trackAgg[s.trackId]!.plays++;
      trackAgg[s.trackId]!.durationSeconds += s.audibleDurationSeconds;

      // Artist aggregation
      artistAgg.putIfAbsent(
          s.artistName, () => _ArtistAggregator(s.artistName, s.artworkUrl));
      artistAgg[s.artistName]!.plays++;
      artistAgg[s.artistName]!.durationSeconds += s.audibleDurationSeconds;

      // Album aggregation
      if (s.albumName.isNotEmpty && s.albumName != 'Unknown Album') {
        albumAgg.putIfAbsent(s.albumName,
            () => _AlbumAggregator(s.albumName, s.artistName, s.artworkUrl));
        albumAgg[s.albumName]!.plays++;
        albumAgg[s.albumName]!.durationSeconds += s.audibleDurationSeconds;
      }

      // Genre aggregation
      if (s.genre.isNotEmpty) {
        genreMap[s.genre] = (genreMap[s.genre] ?? 0) + s.audibleDurationSeconds;
      }
    }

    // Sort Top items
    final topTracks = trackAgg.values
        .map((a) => TopItemModel(
              id: a.id,
              title: a.title,
              subtitle: a.artistName,
              artworkUrl: a.artworkUrl,
              playCount: a.plays,
              totalDurationSeconds: a.durationSeconds,
            ))
        .toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));

    final topArtists = artistAgg.values
        .map((a) => TopItemModel(
              id: a.name,
              title: a.name,
              subtitle: '${a.plays} plays',
              artworkUrl: a.artworkUrl,
              playCount: a.plays,
              totalDurationSeconds: a.durationSeconds,
            ))
        .toList()
      ..sort(
          (a, b) => b.totalDurationSeconds.compareTo(a.totalDurationSeconds));

    final topAlbums = albumAgg.values
        .map((a) => TopItemModel(
              id: a.title,
              title: a.title,
              subtitle: a.artistName,
              artworkUrl: a.artworkUrl,
              playCount: a.plays,
              totalDurationSeconds: a.durationSeconds,
            ))
        .toList()
      ..sort((a, b) => b.playCount.compareTo(a.playCount));

    // Daily activity for the last 7 days
    final List<DailyActivityModel> dailyActivity = [];
    final todayStart = DateTime(now.year, now.month, now.day);
    int todayListeningMinutes = 0;

    for (int i = 6; i >= 0; i--) {
      final date = todayStart.subtract(Duration(days: i));
      final nextDate = date.add(const Duration(days: 1));
      final daySessions = allSessions.where((s) {
        final localStart = s.startedAt.toLocal();
        return localStart.isAfter(date) && localStart.isBefore(nextDate);
      });
      final daySeconds =
          daySessions.fold<int>(0, (sum, s) => sum + s.audibleDurationSeconds);
      final minutes = daySeconds / 60.0;
      final dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      dailyActivity.add(DailyActivityModel(
        dayLabel: dayLabels[date.weekday - 1],
        date: date,
        listeningMinutes: minutes,
      ));

      if (i == 0) {
        todayListeningMinutes = minutes.round();
      }
    }

    // Streak calculation
    int currentStreak = 0;
    int longestStreak = 0;
    int tempStreak = 0;

    // Check consecutive active days going backwards
    for (int d = 0; d < 365; d++) {
      final day = todayStart.subtract(Duration(days: d));
      final nextDay = day.add(const Duration(days: 1));
      final hasListened = allSessions.any((s) {
        final local = s.startedAt.toLocal();
        return local.isAfter(day) &&
            local.isBefore(nextDay) &&
            s.audibleDurationSeconds >= 30;
      });

      if (hasListened) {
        tempStreak++;
        if (d == 0 || tempStreak == d + 1) {
          currentStreak = tempStreak;
        }
        if (tempStreak > longestStreak) {
          longestStreak = tempStreak;
        }
      } else {
        if (d == 0) {
          // If haven't listened today yet, check yesterday
          continue;
        }
        tempStreak = 0;
      }
    }

    return StatsSummaryModel(
      timeRange: timeRange,
      totalListeningSeconds: totalDurationSeconds,
      validPlaysCount: validPlays,
      completedPlaysCount: completedPlays,
      topTracks: topTracks.take(10).toList(),
      topArtists: topArtists.take(10).toList(),
      topAlbums: topAlbums.take(10).toList(),
      genreDistribution: genreMap,
      dailyActivity: dailyActivity,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      dailyGoalMinutes: dailyGoalMinutes,
      todayListeningMinutes: todayListeningMinutes,
    );
  }

  // ==========================================
  // USERS & DATA ISOLATION
  // ==========================================

  UserModel? getUser(String userId) {
    final raw = _prefs.getString('$_keyUsers$userId');
    if (raw == null) return null;
    return UserModel.fromMap(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> saveUser(UserModel user) async {
    await _prefs.setString('$_keyUsers${user.id}', jsonEncode(user.toMap()));
  }

  /// Migrates guest listening history, favourites, and custom playlists into the authenticated user
  Future<void> mergeGuestDataIntoUser(String newUserId) async {
    // 1. Playlists
    final playlists = getAllPlaylists();
    final updatedPlaylists = playlists.map((p) {
      if (p.userId == 'guest') {
        return p.copyWith(userId: newUserId, isSynced: false);
      }
      return p;
    }).toList();
    await savePlaylists(updatedPlaylists);

    // 2. Listening sessions
    final sessions = getAllSessions();
    final updatedSessions = sessions.map((s) {
      if (s.userId == 'guest') {
        return s.copyWith(userId: newUserId, isSynced: false);
      }
      return s;
    }).toList();
    final rawList = updatedSessions.map((s) => jsonEncode(s.toMap())).toList();
    await _prefs.setStringList(_keySessions, rawList);
    _sessionsStreamController.add(updatedSessions);
  }

  // ==========================================
  // OFFLINE SYNC QUEUE
  // ==========================================

  List<SyncQueueModel> getSyncQueue() {
    final rawList = _prefs.getStringList(_keySyncQueue) ?? [];
    return rawList
        .map((str) =>
            SyncQueueModel.fromMap(jsonDecode(str) as Map<String, dynamic>))
        .toList();
  }

  Future<void> enqueueSync({
    required SyncAction action,
    required Map<String, dynamic> payload,
  }) async {
    final item = SyncQueueModel(
      id: IdGenerator.generateUuid(),
      action: action,
      payloadJson: jsonEncode(payload),
      createdAt: DateTime.now().toUtc(),
    );
    final queue = getSyncQueue();
    queue.add(item);
    final rawList = queue.map((q) => jsonEncode(q.toMap())).toList();
    await _prefs.setStringList(_keySyncQueue, rawList);
  }

  Future<void> removeSyncItem(String itemId) async {
    final queue = getSyncQueue();
    queue.removeWhere((q) => q.id == itemId);
    final rawList = queue.map((q) => jsonEncode(q.toMap())).toList();
    await _prefs.setStringList(_keySyncQueue, rawList);
  }

  // ==========================================
  // DATA MANAGEMENT & PRIVACY
  // ==========================================

  Future<void> clearListeningHistory({String? userId}) async {
    if (userId != null && userId.isNotEmpty) {
      final sessions = getAllSessions();
      sessions.removeWhere((s) => s.userId == userId || s.userId == 'guest');
      final rawList = sessions.map((s) => jsonEncode(s.toMap())).toList();
      await _prefs.setStringList(_keySessions, rawList);
      _sessionsStreamController.add(sessions);
    } else {
      await _prefs.remove(_keySessions);
      _sessionsStreamController.add([]);
    }
  }

  String exportAllUserDataAsJson(String userId) {
    final userPlaylists = getAllPlaylists(userId: userId);
    final userSessions = getAllSessions(userId: userId);
    final favIds = getFavouriteTrackIds();
    final user = getUser(userId);

    final data = {
      'app': 'TuneTrack',
      'version': '1.0.0',
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'user': user?.toMap(),
      'favourites': favIds,
      'playlists': userPlaylists.map((p) => p.toMap()).toList(),
      'listeningHistory': userSessions.map((s) => s.toMap()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}

class _TrackAggregator {
  final String id;
  final String title;
  final String artistName;
  final String? artworkUrl;
  int plays = 0;
  int durationSeconds = 0;

  _TrackAggregator(this.id, this.title, this.artistName, this.artworkUrl);
}

class _ArtistAggregator {
  final String name;
  final String? artworkUrl;
  int plays = 0;
  int durationSeconds = 0;

  _ArtistAggregator(this.name, this.artworkUrl);
}

class _AlbumAggregator {
  final String title;
  final String artistName;
  final String? artworkUrl;
  int plays = 0;
  int durationSeconds = 0;

  _AlbumAggregator(this.title, this.artistName, this.artworkUrl);
}
