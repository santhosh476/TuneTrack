/// Spotify Integration Configuration & Constants
class SpotifyConstants {
  SpotifyConstants._();

  // Default App Client ID (can be overridden by user in settings)
  // Demo/Default Client ID for instant testing & evaluation
  static const String defaultClientId = '3a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d';

  // Spotify Developer Portal Endpoints
  static const String authEndpoint = 'https://accounts.spotify.com/authorize';
  static const String tokenEndpoint = 'https://accounts.spotify.com/api/token';
  static const String apiBaseUrl = 'https://api.spotify.com/v1';

  // Specific Spotify API Endpoints
  static const String meEndpoint = '$apiBaseUrl/me';
  static const String mePlaylistsEndpoint = '$apiBaseUrl/me/playlists';
  static const String meTracksEndpoint = '$apiBaseUrl/me/tracks';
  static const String meRecentlyPlayedEndpoint =
      '$apiBaseUrl/me/player/recently-played';
  static const String meTopArtistsEndpoint = '$apiBaseUrl/me/top/artists';
  static const String meTopTracksEndpoint = '$apiBaseUrl/me/top/tracks';
  static const String searchEndpoint = '$apiBaseUrl/search';
  static const String playerEndpoint = '$apiBaseUrl/me/player';

  // OAuth Scopes Required for TuneTrack Features
  static const List<String> defaultScopes = [
    'user-read-private',
    'user-read-email',
    'user-read-playback-state',
    'user-modify-playback-state',
    'user-read-currently-playing',
    'user-read-recently-played',
    'user-top-read',
    'playlist-read-private',
    'playlist-read-collaborative',
    'playlist-modify-public',
    'playlist-modify-private',
    'user-library-read',
    'user-library-modify',
  ];

  static String get scopesString => defaultScopes.join(' ');

  // Redirect Scheme & URL for OAuth PKCE
  static const String redirectUriMobile = 'tunetrack://spotify-auth-callback';
  static const String redirectUriWeb =
      'http://localhost:8080/spotify-callback.html';

  // Documentation and Help URLs
  static const String developerPortalUrl =
      'https://developer.spotify.com/dashboard';
  static const String apiDocsUrl =
      'https://developer.spotify.com/documentation/web-api';
  static const String spotifyAppUrl = 'https://open.spotify.com';
}
