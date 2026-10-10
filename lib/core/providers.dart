import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/local/app_database.dart';
import '../data/local/shared_preferences_service.dart';
import '../data/local/secure_storage_service.dart';
import '../data/repositories/track_repository.dart';
import '../data/repositories/playlist_repository.dart';
import '../data/repositories/listening_session_repository.dart';
import '../data/repositories/user_repository.dart';
import '../data/repositories/spotify_repository.dart';
import '../data/repositories/online_music_repository.dart';
import '../services/online/online_music_service.dart';
import '../data/sync/firestore_service.dart';
import '../data/sync/cloud_sync_service.dart';
import '../data/models/track_model.dart';
import '../data/models/playlist_model.dart';
import '../data/models/user_model.dart';
import '../data/models/stats_summary_model.dart';
import '../data/models/music_insight_model.dart';
import '../features/stats/music_intelligence_service.dart';
import '../services/audio/audio_player_service.dart';
import '../services/spotify/spotify_auth_service.dart';
import '../services/spotify/spotify_api_service.dart';
import '../services/authentication/firebase_auth_service.dart';
import '../features/tracker/listening_tracker_service.dart';

// 1. Storage & Services Providers
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

final sharedPreferencesServiceProvider =
    Provider<SharedPreferencesService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SharedPreferencesService(prefs);
});

final secureStorageServiceProvider = Provider<SecureStorageService>((ref) {
  return SecureStorageService();
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return AppDatabase(prefs);
});

// 2. Repositories
final trackRepositoryProvider = Provider<TrackRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TrackRepository(db);
});

final playlistRepositoryProvider = Provider<PlaylistRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PlaylistRepository(db);
});

final sessionRepositoryProvider = Provider<ListeningSessionRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ListeningSessionRepository(db);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final prefs = ref.watch(sharedPreferencesServiceProvider);
  return UserRepository(db, prefs);
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final cloudSyncServiceProvider = Provider<CloudSyncService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final prefs = ref.watch(sharedPreferencesServiceProvider);
  final firestore = ref.watch(firestoreServiceProvider);
  return CloudSyncService(db, prefs, firestore);
});

// 3. Online Music Service & Repository (Public zero-auth music catalog)
final onlineMusicServiceProvider = Provider<OnlineMusicService>((ref) {
  return OnlineMusicService();
});

final onlineMusicRepositoryProvider = Provider<OnlineMusicRepository>((ref) {
  final service = ref.watch(onlineMusicServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  return OnlineMusicRepository(service, db);
});

final featuredOnlineTracksFutureProvider =
    FutureProvider<List<TrackModel>>((ref) async {
  final repo = ref.watch(onlineMusicRepositoryProvider);
  return repo.getFeaturedOnlineTracks();
});

final recommendedTracksFutureProvider =
    FutureProvider<List<TrackModel>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final repo = ref.watch(onlineMusicRepositoryProvider);
  final primaryLang = user.primaryLanguage;
  return repo.getCategoryTracks('$primaryLang Trending Hits');
});

final languageTracksFutureProvider =
    FutureProvider.family<List<TrackModel>, String>((ref, language) async {
  final repo = ref.watch(onlineMusicRepositoryProvider);
  return repo.getCategoryTracks('$language Songs Beats');
});

// Legacy/Compatibility Spotify Services
final spotifyAuthServiceProvider = Provider<SpotifyAuthService>((ref) {
  final secure = ref.watch(secureStorageServiceProvider);
  return SpotifyAuthService(secure);
});

final spotifyApiServiceProvider = Provider<SpotifyApiService>((ref) {
  return SpotifyApiService();
});

final spotifyRepositoryProvider = Provider<SpotifyRepository>((ref) {
  final auth = ref.watch(spotifyAuthServiceProvider);
  final api = ref.watch(spotifyApiServiceProvider);
  final db = ref.watch(appDatabaseProvider);
  return SpotifyRepository(auth, api, db);
});

final spotifyConnectionStateProvider = StreamProvider<bool>((ref) {
  final repo = ref.watch(spotifyRepositoryProvider);
  return repo.connectionStream;
});

final isSpotifyConnectedProvider = FutureProvider<bool>((ref) async {
  final repo = ref.watch(spotifyRepositoryProvider);
  return repo.isConnected();
});

// 4. Audio Engine & Tracker
final audioPlayerServiceProvider = Provider<AudioPlayerService>((ref) {
  final service = AudioPlayerService();
  ref.onDispose(() => service.dispose());
  return service;
});

final listeningTrackerServiceProvider =
    Provider<ListeningTrackerService>((ref) {
  final audio = ref.watch(audioPlayerServiceProvider);
  final sessions = ref.watch(sessionRepositoryProvider);
  final users = ref.watch(userRepositoryProvider);
  final tracker = ListeningTrackerService(audio, sessions, users);
  ref.onDispose(() => tracker.dispose());
  return tracker;
});

final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final prefs = ref.watch(sharedPreferencesServiceProvider);
  return FirebaseAuthService(db, prefs);
});

// 5. Reactive Data Streams
final allTracksStreamProvider = StreamProvider<List<TrackModel>>((ref) {
  final repo = ref.watch(trackRepositoryProvider);
  return repo.watchTracks();
});

final allTracksProvider = Provider<List<TrackModel>>((ref) {
  final repo = ref.watch(trackRepositoryProvider);
  final asyncVal = ref.watch(allTracksStreamProvider);
  return asyncVal.value ?? repo.getAllTracks();
});

final playlistsStreamProvider = StreamProvider<List<PlaylistModel>>((ref) {
  final repo = ref.watch(playlistRepositoryProvider);
  return repo.watchPlaylists();
});

final playlistsProvider = Provider<List<PlaylistModel>>((ref) {
  final repo = ref.watch(playlistRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  final asyncVal = ref.watch(playlistsStreamProvider);
  return asyncVal.value ?? repo.getAllPlaylists(userId: user.id);
});

final favouriteTrackIdsStreamProvider = StreamProvider<List<String>>((ref) {
  final repo = ref.watch(trackRepositoryProvider);
  return repo.watchFavourites();
});

final favouriteTracksProvider = Provider<List<TrackModel>>((ref) {
  final repo = ref.watch(trackRepositoryProvider);
  ref.watch(favouriteTrackIdsStreamProvider);
  return repo.getFavouriteTracks();
});

final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(authServiceProvider);
  return auth.authStateChanges;
});

final currentUserProvider = Provider<UserModel>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  final asyncVal = ref.watch(currentUserStreamProvider);
  return asyncVal.value ?? userRepo.getActiveUser();
});

// Stats Summary Provider
final statsSummaryProvider =
    Provider.family<StatsSummaryModel, StatsTimeRange>((ref, range) {
  final repo = ref.watch(sessionRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  // Re-run stats calculation when sessions stream emits
  ref.watch(sessionRepositoryProvider).watchSessions();
  return repo.getStats(
    timeRange: range,
    userId: user.id,
    dailyGoalMinutes: user.dailyGoalMinutes,
  );
});

// Music Intelligence Insights Provider
final musicIntelligenceProvider = Provider<MusicIntelligenceSummary>((ref) {
  final repo = ref.watch(sessionRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  final sessions = repo.getAllSessions(userId: user.id);
  final stats = ref.watch(statsSummaryProvider(StatsTimeRange.allTime));

  return MusicIntelligenceService.generateInsights(
    sessions: sessions,
    currentStreak: stats.currentStreak,
    longestStreak: stats.longestStreak,
  );
});

// Current audio player state streams
final currentTrackStreamProvider = StreamProvider<TrackModel?>((ref) {
  final audio = ref.watch(audioPlayerServiceProvider);
  return audio.currentTrackStream;
});

final isPlayingStreamProvider = StreamProvider<bool>((ref) {
  final audio = ref.watch(audioPlayerServiceProvider);
  return audio.isPlayingStream;
});

final playbackPositionStreamProvider = StreamProvider<Duration>((ref) {
  final audio = ref.watch(audioPlayerServiceProvider);
  return audio.positionStream;
});

final playbackDurationStreamProvider = StreamProvider<Duration?>((ref) {
  final audio = ref.watch(audioPlayerServiceProvider);
  return audio.durationStream;
});

final playerQueueStreamProvider = StreamProvider<List<TrackModel>>((ref) {
  final audio = ref.watch(audioPlayerServiceProvider);
  return audio.queueStream;
});

final shuffleStreamProvider = StreamProvider<bool>((ref) {
  final audio = ref.watch(audioPlayerServiceProvider);
  return audio.shuffleStream;
});

final repeatStreamProvider = StreamProvider<AudioRepeatMode>((ref) {
  final audio = ref.watch(audioPlayerServiceProvider);
  return audio.repeatStream;
});

final sleepTimerStreamProvider = StreamProvider<DateTime?>((ref) {
  final audio = ref.watch(audioPlayerServiceProvider);
  return audio.sleepTimerStream;
});
