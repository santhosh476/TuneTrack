import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/spotify_constants.dart';
import '../../core/errors/app_exceptions.dart';
import '../../data/models/track_model.dart';
import '../../data/models/artist_model.dart';
import '../../data/models/album_model.dart';
import '../../data/models/playlist_model.dart';

/// Interacts with the official Spotify Web API
class SpotifyApiService {
  final http.Client _client;

  SpotifyApiService([http.Client? client]) : _client = client ?? http.Client();

  Map<String, String> _authHeaders(String token) => {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

  /// Fetch user profile details
  Future<Map<String, dynamic>> getCurrentUserProfile(String token) async {
    final response = await _client.get(
      Uri.parse('${SpotifyConstants.apiBaseUrl}/me'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw SpotifyApiException(
      'Failed to fetch Spotify profile',
      statusCode: response.statusCode,
    );
  }

  /// Global Search across Spotify catalogue
  Future<Map<String, dynamic>> search({
    required String token,
    required String query,
    int limit = 20,
  }) async {
    final uri = Uri.parse('${SpotifyConstants.apiBaseUrl}/search').replace(
      queryParameters: {
        'q': query,
        'type': 'track,artist,album,playlist',
        'limit': limit.toString(),
      },
    );

    final response = await _client.get(uri, headers: _authHeaders(token));

    if (response.statusCode != 200) {
      throw SpotifyApiException('Spotify search failed',
          statusCode: response.statusCode);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return _parseSearchResults(data);
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
        final artworkUrl = images != null && images.isNotEmpty
            ? images.first['url'] as String?
            : null;
        final artistsList = item['artists'] as List?;
        final artistName = artistsList != null && artistsList.isNotEmpty
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
          audioSourceUrl:
              item['preview_url'] as String? ?? item['uri'] as String? ?? '',
          genre: 'Spotify',
          addedAt: DateTime.now(),
        ));
      }
    }

    if (json.containsKey('artists') && json['artists']['items'] != null) {
      for (final item in json['artists']['items'] as List) {
        if (item == null) continue;
        final images = item['images'] as List?;
        final imgUrl = images != null && images.isNotEmpty
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

    return {
      'tracks': tracks,
      'artists': artists,
      'albums': albums,
      'playlists': playlists,
    };
  }

  /// Get Current Playback State on connected Spotify devices
  Future<Map<String, dynamic>?> getPlaybackState(String token) async {
    final response = await _client.get(
      Uri.parse('${SpotifyConstants.apiBaseUrl}/me/player'),
      headers: _authHeaders(token),
    );

    if (response.statusCode == 200 && response.body.isNotEmpty) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    return null;
  }

  /// Send Playback commands to active Spotify Connect device
  Future<bool> sendPlaybackCommand({
    required String token,
    required String command, // 'play', 'pause', 'next', 'previous'
  }) async {
    final uri = Uri.parse('${SpotifyConstants.apiBaseUrl}/me/player/$command');
    final response = command == 'play' || command == 'pause'
        ? await _client.put(uri, headers: _authHeaders(token))
        : await _client.post(uri, headers: _authHeaders(token));
    return response.statusCode == 204 || response.statusCode == 200;
  }
}
