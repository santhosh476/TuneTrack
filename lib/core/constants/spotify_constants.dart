/// Spotify Integration Configuration & Constants
class SpotifyConstants {
  SpotifyConstants._();

  // Spotify Developer Portal Endpoints
  static const String authEndpoint = 'https://accounts.spotify.com/authorize';
  static const String tokenEndpoint = 'https://accounts.spotify.com/api/token';
  static const String apiBaseUrl = 'https://api.spotify.com/v1';

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

  // Documentation and Help URL
  static const String developerPortalUrl =
      'https://developer.spotify.com/dashboard';
  static const String apiDocsUrl =
      'https://developer.spotify.com/documentation/web-api';
}
