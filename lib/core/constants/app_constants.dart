/// Core constants for TuneTrack
class AppConstants {
  AppConstants._();

  static const String appName = 'TuneTrack';
  static const String appTagline = 'Your Music, Your Stats, Everywhere';
  static const String appVersion = '1.0.0';

  // Listening Tracker Rules
  static const int minListeningThresholdSeconds = 30;
  static const double minListeningFraction =
      0.5; // Or 50% of track length if short
  static const int defaultDailyGoalMinutes = 45;
  static const int defaultWeeklyGoalHours = 8;

  // Storage Keys
  static const String keyGuestId = 'tunetrack_guest_id';
  static const String keyUserId = 'tunetrack_user_id';
  static const String keyUserPreferences = 'tunetrack_preferences';
  static const String keySpotifyAccessToken = 'tunetrack_spotify_access_token';
  static const String keySpotifyRefreshToken =
      'tunetrack_spotify_refresh_token';
  static const String keySpotifyExpiresAt = 'tunetrack_spotify_expires_at';
  static const String keyDailyGoalMinutes = 'tunetrack_daily_goal_mins';
  static const String keyThemeMode = 'tunetrack_theme_mode';
  static const String keyLastSyncTime = 'tunetrack_last_sync_time';

  // Route Names
  static const String routeSplash = '/splash';
  static const String routeHome = '/';
  static const String routeSearch = '/search';
  static const String routeLibrary = '/library';
  static const String routeStats = '/stats';
  static const String routeProfile = '/profile';
  static const String routePlayer = '/player';
  static const String routeQueue = '/queue';
  static const String routePlaylistDetail = '/playlist/:id';
  static const String routeArtistDetail = '/artist/:id';
  static const String routeAlbumDetail = '/album/:id';
  static const String routeGenreDetail = '/genre/:genre';
  static const String routeLocalMusic = '/local-music';
  static const String routeLikedSongs = '/liked-songs';
  static const String routeYearlyRecap = '/recap';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeSpotifyConnect = '/spotify-connect';
  static const String routeSettings = '/settings';
  static const String routeExportData = '/export-data';
}
