import 'package:url_launcher/url_launcher.dart';
import '../../services/spotify/spotify_auth_service.dart';
import '../../services/spotify/spotify_api_service.dart';
import '../local/app_database.dart';
import '../models/track_model.dart';
import '../models/artist_model.dart';
import '../models/album_model.dart';
import '../models/playlist_model.dart';
import '../../core/constants/spotify_constants.dart';

class SpotifyRepository {
  final SpotifyAuthService _authService;
  final SpotifyApiService _apiService;
  final AppDatabase? _db;
  String _clientId = '';

  SpotifyRepository(this._authService, this._apiService, [this._db]);

  void configureClientId(String clientId) {
    _clientId = clientId.trim().isEmpty
        ? SpotifyConstants.defaultClientId
        : clientId.trim();
  }

  String get clientId =>
      _clientId.isEmpty ? SpotifyConstants.defaultClientId : _clientId;
  bool get hasClientId => _clientId.isNotEmpty;

  Stream<bool> get connectionStream => _authService.connectionStream;

  Future<bool> isConnected() => _authService.isConnected();

  String getAuthorizationUrl(String redirectUri) {
    return _authService.buildAuthorizationUrl(
      clientId: clientId,
      redirectUri: redirectUri,
    );
  }

  Future<String> handleAuthCode(String codeOrUrl, String redirectUri) {
    final code = _authService.extractCodeFromUrl(codeOrUrl) ?? codeOrUrl;
    return _authService.exchangeCodeForToken(
      code: code,
      clientId: clientId,
      redirectUri: redirectUri,
    );
  }

  Future<void> disconnect() => _authService.disconnect();

  Future<String?> getValidAccessToken() {
    return _authService.getValidAccessToken(clientId);
  }

  /// Get Current User Profile from Spotify
  Future<Map<String, dynamic>?> getCurrentUserProfile() async {
    final token = await getValidAccessToken();
    if (token == null) return null;
    try {
      return await _apiService.getCurrentUserProfile(token);
    } catch (_) {
      return null;
    }
  }

  /// Synchronize Spotify playlists, saved tracks, top items into local DB cache
  Future<Map<String, dynamic>> syncSpotifyData() async {
    final token = await getValidAccessToken();
    if (token == null) {
      return {
        'success': false,
        'message': 'Not authenticated with Spotify',
        'playlistsCount': 0,
        'tracksCount': 0,
      };
    }

    try {
      List<PlaylistModel> playlists = [];
      try {
        playlists = await _apiService.getUserPlaylists(token);
      } catch (_) {}

      List<TrackModel> savedTracks = [];
      try {
        savedTracks = await _apiService.getSavedTracks(token);
      } catch (_) {}

      List<TrackModel> recentTracks = [];
      try {
        recentTracks = await _apiService.getRecentlyPlayed(token);
      } catch (_) {}

      List<TrackModel> topTracks = [];
      try {
        topTracks = await _apiService.getTopTracks(token);
      } catch (_) {}

      final db = _db;
      if (db != null) {
        // Cache tracks in local database
        final allTracks = <TrackModel>[
          ...savedTracks,
          ...recentTracks,
          ...topTracks
        ];
        for (final t in allTracks) {
          await db.insertOrUpdateTrack(t);
        }
        for (final p in playlists) {
          await db.insertOrUpdatePlaylist(p);
        }
      }

      return {
        'success': true,
        'playlists': playlists,
        'savedTracks': savedTracks,
        'recentTracks': recentTracks,
        'topTracks': topTracks,
        'playlistsCount': playlists.length,
        'tracksCount':
            savedTracks.length + recentTracks.length + topTracks.length,
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
        'playlistsCount': 0,
        'tracksCount': 0,
      };
    }
  }

  /// Fetch user playlists from network or local cache
  Future<List<PlaylistModel>> getUserPlaylists(
      {int limit = 50, int offset = 0}) async {
    final token = await getValidAccessToken();
    final db = _db;
    if (token != null) {
      try {
        final networkPlaylists = await _apiService.getUserPlaylists(token,
            limit: limit, offset: offset);
        if (db != null && networkPlaylists.isNotEmpty) {
          for (final p in networkPlaylists) {
            await db.insertOrUpdatePlaylist(p);
          }
        }
        return networkPlaylists;
      } catch (_) {
        // Fallback to cached Spotify playlists
      }
    }

    // Cache fallback
    if (db != null) {
      return db
          .getAllPlaylists()
          .where((p) => p.id.startsWith('spotify_ply_'))
          .toList();
    }
    return [];
  }

  /// Fetch playlist tracks
  Future<List<TrackModel>> getPlaylistTracks(String playlistId,
      {int limit = 50, int offset = 0}) async {
    final token = await getValidAccessToken();
    final db = _db;
    if (token != null) {
      try {
        final tracks = await _apiService.getPlaylistTracks(token, playlistId,
            limit: limit, offset: offset);
        if (db != null && tracks.isNotEmpty) {
          for (final t in tracks) {
            await db.insertOrUpdateTrack(t);
          }
        }
        return tracks;
      } catch (_) {}
    }

    return [];
  }

  /// Fetch user's saved tracks
  Future<List<TrackModel>> getSavedTracks(
      {int limit = 50, int offset = 0}) async {
    final token = await getValidAccessToken();
    final db = _db;
    if (token != null) {
      try {
        final tracks = await _apiService.getSavedTracks(token,
            limit: limit, offset: offset);
        if (db != null && tracks.isNotEmpty) {
          for (final t in tracks) {
            await db.insertOrUpdateTrack(t);
          }
        }
        return tracks;
      } catch (_) {}
    }

    if (db != null) {
      return db
          .getAllTracks()
          .where((t) =>
              t.sourceType == AudioSourceType.spotifyStream && t.isFavourite)
          .toList();
    }
    return [];
  }

  /// Fetch recently played
  Future<List<TrackModel>> getRecentlyPlayed({int limit = 30}) async {
    final token = await getValidAccessToken();
    final db = _db;
    if (token != null) {
      try {
        final tracks = await _apiService.getRecentlyPlayed(token, limit: limit);
        if (db != null && tracks.isNotEmpty) {
          for (final t in tracks) {
            await db.insertOrUpdateTrack(t);
          }
        }
        return tracks;
      } catch (_) {}
    }
    return [];
  }

  /// Search Spotify catalogue
  Future<Map<String, dynamic>> searchSpotify(String query,
      {int limit = 20}) async {
    final token = await getValidAccessToken();
    if (token == null) {
      return {
        'tracks': <TrackModel>[],
        'artists': <ArtistModel>[],
        'albums': <AlbumModel>[],
        'playlists': <PlaylistModel>[],
      };
    }
    try {
      return await _apiService.search(token: token, query: query, limit: limit);
    } catch (_) {
      return {
        'tracks': <TrackModel>[],
        'artists': <ArtistModel>[],
        'albums': <AlbumModel>[],
        'playlists': <PlaylistModel>[],
      };
    }
  }

  /// Get Remote Playback State
  Future<Map<String, dynamic>?> getPlaybackState() async {
    final token = await getValidAccessToken();
    if (token == null) return null;
    return _apiService.getPlaybackState(token);
  }

  /// Send Playback Command
  Future<bool> sendPlaybackCommand(String command) async {
    final token = await getValidAccessToken();
    if (token == null) return false;
    return _apiService.sendPlaybackCommand(token: token, command: command);
  }

  /// Open Track/Album/Artist/Playlist in official Spotify App or Web
  Future<bool> openInSpotify(String spotifyUriOrUrl) async {
    if (spotifyUriOrUrl.isEmpty) return false;

    // Convert spotify URI (spotify:track:xxx) to web URL if needed
    Uri? targetUri;
    if (spotifyUriOrUrl.startsWith('spotify:')) {
      targetUri = Uri.parse(spotifyUriOrUrl);
    } else if (spotifyUriOrUrl.startsWith('http')) {
      targetUri = Uri.parse(spotifyUriOrUrl);
    } else {
      targetUri = Uri.parse('spotify:track:$spotifyUriOrUrl');
    }

    try {
      final launched = await launchUrl(
        targetUri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        // Fallback to web player URL
        final webUrl = spotifyUriOrUrl
            .replaceAll('spotify:track:', 'https://open.spotify.com/track/')
            .replaceAll(
                'spotify:playlist:', 'https://open.spotify.com/playlist/')
            .replaceAll('spotify:album:', 'https://open.spotify.com/album/')
            .replaceAll('spotify:artist:', 'https://open.spotify.com/artist/');
        return await launchUrl(
          Uri.parse(webUrl),
          mode: LaunchMode.externalApplication,
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}
