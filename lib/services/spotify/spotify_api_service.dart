import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/spotify_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../data/models/track_model.dart';
import '../../data/models/artist_model.dart';
import '../../data/models/album_model.dart';
import '../../data/models/playlist_model.dart';

/// Interacts with the official Spotify Web API with robust error and status code handling
class SpotifyApiService {
  final http.Client _client;

  SpotifyApiService([http.Client? client]) : _client = client ?? http.Client();

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// Fetch user profile details (display name, email, avatar image, product tier)
  Future<Map<String, dynamic>> getCurrentUserProfile(String token) async {
    final response = await _client.get(
      Uri.parse(SpotifyConstants.meEndpoint),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final images = json['images'] as List?;
      final avatarUrl = (images != null && images.isNotEmpty)
          ? images.first['url'] as String?
          : null;

      return {
        'id': json['id'] as String? ?? '',
        'displayName': json['display_name'] as String? ?? 'Spotify User',
        'email': json['email'] as String? ?? '',
        'avatarUrl': avatarUrl,
        'product': json['product'] as String? ?? 'free', // 'premium' or 'free'
        'followers': (json['followers']?['total'] as num?)?.toInt() ?? 0,
        'country': json['country'] as String? ?? '',
      };
    }

    _handleErrorStatus(response);
    throw SpotifyApiException(
      'Failed to fetch Spotify profile',
      statusCode: response.statusCode,
    );
  }

  /// Fetch user's Spotify playlists with pagination
  Future<List<PlaylistModel>> getUserPlaylists(
    String token, {
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse(SpotifyConstants.mePlaylistsEndpoint).replace(
      queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    final response = await _client.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];
      final playlists = <PlaylistModel>[];

      for (final item in items) {
        if (item == null) continue;
        final images = item['images'] as List?;
        final coverUrl = (images != null && images.isNotEmpty)
            ? images.first['url'] as String?
            : null;

        playlists.add(PlaylistModel(
          id: 'spotify_ply_${item['id']}',
          title: item['name'] as String? ?? 'Spotify Playlist',
          description: item['description'] as String? ?? '',
          coverUrl: coverUrl,
          userId: item['owner']?['id'] as String? ?? 'spotify',
          isPublic: item['public'] as bool? ?? false,
          trackIds: [], // Tracks fetched on detail view
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        ));
      }

      return playlists;
    }

    _handleErrorStatus(response);
    return [];
  }

  /// Fetch tracks inside a specific Spotify playlist
  Future<List<TrackModel>> getPlaylistTracks(
    String token,
    String spotifyPlaylistId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final cleanId = spotifyPlaylistId.replaceFirst('spotify_ply_', '');
    final uri =
        Uri.parse('${SpotifyConstants.apiBaseUrl}/playlists/$cleanId/tracks')
            .replace(
      queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    final response = await _client.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];
      final tracks = <TrackModel>[];

      for (final item in items) {
        final trackObj = item?['track'] as Map<String, dynamic>?;
        if (trackObj == null || trackObj['id'] == null) continue;

        final album = trackObj['album'] as Map<String, dynamic>?;
        final images = album?['images'] as List?;
        final artworkUrl = (images != null && images.isNotEmpty)
            ? images.first['url'] as String?
            : null;

        final artistsList = trackObj['artists'] as List?;
        final artistName = (artistsList != null && artistsList.isNotEmpty)
            ? artistsList.map((a) => a['name']).join(', ')
            : 'Spotify Artist';

        tracks.add(TrackModel(
          id: 'spotify_${trackObj['id']}',
          title: trackObj['name'] as String? ?? 'Track',
          artistName: artistName,
          albumName: album?['name'] as String? ?? 'Single',
          durationMs: (trackObj['duration_ms'] as num?)?.toInt() ?? 0,
          artworkUrl: artworkUrl,
          sourceType: AudioSourceType.spotifyStream,
          audioSourceUrl: trackObj['uri'] as String? ??
              trackObj['external_urls']?['spotify'] as String? ??
              '',
          genre: 'Spotify',
          addedAt: DateTime.now(),
        ));
      }

      return tracks;
    }

    _handleErrorStatus(response);
    return [];
  }

  /// Fetch user's saved/liked tracks from Spotify library
  Future<List<TrackModel>> getSavedTracks(
    String token, {
    int limit = 50,
    int offset = 0,
  }) async {
    final uri = Uri.parse(SpotifyConstants.meTracksEndpoint).replace(
      queryParameters: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    final response = await _client.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];
      final tracks = <TrackModel>[];

      for (final item in items) {
        final trackObj = item?['track'] as Map<String, dynamic>?;
        if (trackObj == null || trackObj['id'] == null) continue;

        final album = trackObj['album'] as Map<String, dynamic>?;
        final images = album?['images'] as List?;
        final artworkUrl = (images != null && images.isNotEmpty)
            ? images.first['url'] as String?
            : null;

        final artistsList = trackObj['artists'] as List?;
        final artistName = (artistsList != null && artistsList.isNotEmpty)
            ? artistsList.map((a) => a['name']).join(', ')
            : 'Spotify Artist';

        tracks.add(TrackModel(
          id: 'spotify_${trackObj['id']}',
          title: trackObj['name'] as String? ?? 'Track',
          artistName: artistName,
          albumName: album?['name'] as String? ?? 'Single',
          durationMs: (trackObj['duration_ms'] as num?)?.toInt() ?? 0,
          artworkUrl: artworkUrl,
          sourceType: AudioSourceType.spotifyStream,
          audioSourceUrl: trackObj['uri'] as String? ??
              trackObj['external_urls']?['spotify'] as String? ??
              '',
          isFavourite: true,
          genre: 'Spotify',
          addedAt: DateTime.now(),
        ));
      }

      return tracks;
    }

    _handleErrorStatus(response);
    return [];
  }

  /// Fetch user's recently played tracks from Spotify
  Future<List<TrackModel>> getRecentlyPlayed(
    String token, {
    int limit = 30,
  }) async {
    final uri = Uri.parse(SpotifyConstants.meRecentlyPlayedEndpoint).replace(
      queryParameters: {'limit': limit.toString()},
    );

    final response = await _client.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];
      final tracks = <TrackModel>[];

      for (final item in items) {
        final trackObj = item?['track'] as Map<String, dynamic>?;
        if (trackObj == null || trackObj['id'] == null) continue;

        final album = trackObj['album'] as Map<String, dynamic>?;
        final images = album?['images'] as List?;
        final artworkUrl = (images != null && images.isNotEmpty)
            ? images.first['url'] as String?
            : null;

        final artistsList = trackObj['artists'] as List?;
        final artistName = (artistsList != null && artistsList.isNotEmpty)
            ? artistsList.map((a) => a['name']).join(', ')
            : 'Spotify Artist';

        tracks.add(TrackModel(
          id: 'spotify_${trackObj['id']}',
          title: trackObj['name'] as String? ?? 'Track',
          artistName: artistName,
          albumName: album?['name'] as String? ?? 'Single',
          durationMs: (trackObj['duration_ms'] as num?)?.toInt() ?? 0,
          artworkUrl: artworkUrl,
          sourceType: AudioSourceType.spotifyStream,
          audioSourceUrl: trackObj['uri'] as String? ??
              trackObj['external_urls']?['spotify'] as String? ??
              '',
          genre: 'Spotify',
          addedAt: DateTime.now(),
        ));
      }

      return tracks;
    }

    _handleErrorStatus(response);
    return [];
  }

  /// Fetch user's top tracks
  Future<List<TrackModel>> getTopTracks(
    String token, {
    int limit = 20,
    String timeRange = 'medium_term',
  }) async {
    final uri = Uri.parse(SpotifyConstants.meTopTracksEndpoint).replace(
      queryParameters: {
        'limit': limit.toString(),
        'time_range': timeRange,
      },
    );

    final response = await _client.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];
      final tracks = <TrackModel>[];

      for (final trackObj in items) {
        if (trackObj == null || trackObj['id'] == null) continue;

        final album = trackObj['album'] as Map<String, dynamic>?;
        final images = album?['images'] as List?;
        final artworkUrl = (images != null && images.isNotEmpty)
            ? images.first['url'] as String?
            : null;

        final artistsList = trackObj['artists'] as List?;
        final artistName = (artistsList != null && artistsList.isNotEmpty)
            ? artistsList.map((a) => a['name']).join(', ')
            : 'Spotify Artist';

        tracks.add(TrackModel(
          id: 'spotify_${trackObj['id']}',
          title: trackObj['name'] as String? ?? 'Track',
          artistName: artistName,
          albumName: album?['name'] as String? ?? 'Single',
          durationMs: (trackObj['duration_ms'] as num?)?.toInt() ?? 0,
          artworkUrl: artworkUrl,
          sourceType: AudioSourceType.spotifyStream,
          audioSourceUrl: trackObj['uri'] as String? ??
              trackObj['external_urls']?['spotify'] as String? ??
              '',
          genre: 'Spotify Top',
          addedAt: DateTime.now(),
        ));
      }

      return tracks;
    }

    _handleErrorStatus(response);
    return [];
  }

  /// Global Search across Spotify catalogue
  Future<Map<String, dynamic>> search({
    required String token,
    required String query,
    int limit = 20,
    int offset = 0,
  }) async {
    if (query.trim().isEmpty) {
      return {
        'tracks': <TrackModel>[],
        'artists': <ArtistModel>[],
        'albums': <AlbumModel>[],
        'playlists': <PlaylistModel>[],
      };
    }

    final uri = Uri.parse(SpotifyConstants.searchEndpoint).replace(
      queryParameters: {
        'q': query.trim(),
        'type': 'track,artist,album,playlist',
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    final response = await _client.get(uri, headers: _authHeaders(token));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return _parseSearchResults(data);
    }

    _handleErrorStatus(response);
    return {
      'tracks': <TrackModel>[],
      'artists': <ArtistModel>[],
      'albums': <AlbumModel>[],
      'playlists': <PlaylistModel>[],
    };
  }

  Map<String, dynamic> _parseSearchResults(Map<String, dynamic> json) {
    final tracks = <TrackModel>[];
    final artists = <ArtistModel>[];
    final albums = <AlbumModel>[];
    final playlists = <PlaylistModel>[];

    if (json.containsKey('tracks') && json['tracks']['items'] != null) {
      for (final item in json['tracks']['items'] as List) {
        if (item == null) continue;
        final album = item['album'] as Map<String, dynamic>?;
        final images = album?['images'] as List?;
        final artworkUrl = (images != null && images.isNotEmpty)
            ? images.first['url'] as String?
            : null;
        final artistsList = item['artists'] as List?;
        final artistName = (artistsList != null && artistsList.isNotEmpty)
            ? artistsList.map((a) => a['name']).join(', ')
            : 'Spotify Artist';

        tracks.add(TrackModel(
          id: 'spotify_${item['id']}',
          title: item['name'] as String? ?? 'Track',
          artistName: artistName,
          albumName: album?['name'] as String? ?? 'Single',
          durationMs: (item['duration_ms'] as num?)?.toInt() ?? 0,
          artworkUrl: artworkUrl,
          sourceType: AudioSourceType.spotifyStream,
          audioSourceUrl: item['uri'] as String? ??
              item['external_urls']?['spotify'] as String? ??
              '',
          genre: 'Spotify',
          addedAt: DateTime.now(),
        ));
      }
    }

    if (json.containsKey('artists') && json['artists']['items'] != null) {
      for (final item in json['artists']['items'] as List) {
        if (item == null) continue;
        final images = item['images'] as List?;
        final imgUrl = (images != null && images.isNotEmpty)
            ? images.first['url'] as String?
            : null;
        final genres =
            (item['genres'] as List?)?.map((g) => g.toString()).toList() ?? [];

        artists.add(ArtistModel(
          id: 'spotify_art_${item['id']}',
          name: item['name'] as String? ?? 'Artist',
          imageUrl: imgUrl,
          genres: genres,
          monthlyListeners: (item['followers']?['total'] as num?)?.toInt() ?? 0,
        ));
      }
    }

    if (json.containsKey('playlists') && json['playlists']['items'] != null) {
      for (final item in json['playlists']['items'] as List) {
        if (item == null) continue;
        final images = item['images'] as List?;
        final imgUrl = (images != null && images.isNotEmpty)
            ? images.first['url'] as String?
            : null;

        playlists.add(PlaylistModel(
          id: 'spotify_ply_${item['id']}',
          title: item['name'] as String? ?? 'Playlist',
          description: item['description'] as String? ?? '',
          coverUrl: imgUrl,
          userId: item['owner']?['id'] as String? ?? 'spotify',
          isPublic: item['public'] as bool? ?? true,
          trackIds: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          isSynced: true,
        ));
      }
    }

    return {
      'tracks': tracks,
      'artists': artists,
      'albums': albums,
      'playlists': playlists,
    };
  }

  /// Get Current Playback State on connected Spotify devices
  Future<Map<String, dynamic>?> getPlaybackState(String token) async {
    try {
      final response = await _client.get(
        Uri.parse(SpotifyConstants.playerEndpoint),
        headers: _authHeaders(token),
      );

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final device = json['device'] as Map<String, dynamic>?;
        final item = json['item'] as Map<String, dynamic>?;

        return {
          'deviceName': device?['name'] as String? ?? 'Connected Device',
          'deviceType': device?['type'] as String? ?? 'Smartphone',
          'isPlaying': json['is_playing'] as bool? ?? false,
          'progressMs': (json['progress_ms'] as num?)?.toInt() ?? 0,
          'trackTitle': item?['name'] as String? ?? 'No Track Playing',
          'artistName': ((item?['artists'] as List?) != null &&
                  (item!['artists'] as List).isNotEmpty)
              ? (item['artists'] as List).map((a) => a['name']).join(', ')
              : '',
          'albumArt': ((item?['album']?['images'] as List?) != null &&
                  (item!['album']['images'] as List).isNotEmpty)
              ? item['album']['images'][0]['url'] as String?
              : null,
          'spotifyUri': item?['uri'] as String? ?? '',
        };
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  /// Send Playback commands to active Spotify Connect device
  Future<bool> sendPlaybackCommand({
    required String token,
    required String command, // 'play', 'pause', 'next', 'previous'
  }) async {
    try {
      final uri = Uri.parse('${SpotifyConstants.playerEndpoint}/$command');
      final response = (command == 'play' || command == 'pause')
          ? await _client.put(uri, headers: _authHeaders(token))
          : await _client.post(uri, headers: _authHeaders(token));
      return response.statusCode == 204 || response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  void _handleErrorStatus(http.Response response) {
    if (response.statusCode == 401) {
      throw const SpotifyApiException(
          'Spotify session expired. Please re-authenticate.',
          statusCode: 401);
    } else if (response.statusCode == 403) {
      throw const SpotifyApiException(
          'Spotify Premium account or developer user whitelisting is required for this action.',
          statusCode: 403);
    } else if (response.statusCode == 429) {
      throw const SpotifyApiException(
          'Spotify API rate limit exceeded. Please wait a moment.',
          statusCode: 429);
    }
  }
}
