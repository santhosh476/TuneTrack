import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../data/models/track_model.dart';

/// Public, zero-API-key Online Music Service using legitimate open public music catalogs
/// (iTunes Public Search & Preview Streams + Public Open Audio Feeds).
/// Requires NO tokens, NO credentials, NO paid accounts, and NO authentication.
class OnlineMusicService {
  final http.Client _client;

  OnlineMusicService([http.Client? client]) : _client = client ?? http.Client();

  static const String _itunesSearchUrl = 'https://itunes.apple.com/search';

  /// Search online public catalogue by keyword (supports all languages, Tamil, Indian, International)
  Future<List<TrackModel>> searchTracks(String query, {int limit = 25}) async {
    if (query.trim().isEmpty) return [];

    final uri = Uri.parse(_itunesSearchUrl).replace(
      queryParameters: {
        'term': query.trim(),
        'media': 'music',
        'entity': 'song',
        'limit': limit.toString(),
      },
    );

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List? ?? [];
        final tracks = <TrackModel>[];

        for (final item in results) {
          if (item == null) continue;
          final previewUrl = item['previewUrl'] as String?;
          if (previewUrl == null || previewUrl.isEmpty) continue;

          final rawArtwork = item['artworkUrl100'] as String?;
          final highResArtwork =
              rawArtwork?.replaceAll('100x100bb', '600x600bb');

          final trackId =
              'online_${item['trackId'] ?? item['collectionId'] ?? DateTime.now().millisecondsSinceEpoch}';
          final trackName = item['trackName'] as String? ?? 'Unknown Title';
          final artistName = item['artistName'] as String? ?? 'Unknown Artist';
          final collectionName = item['collectionName'] as String? ?? 'Single';
          final primaryGenre = item['primaryGenreName'] as String? ?? 'Online';
          final durationMs =
              (item['trackTimeMillis'] as num?)?.toInt() ?? 30000;

          tracks.add(TrackModel(
            id: trackId,
            title: trackName,
            artistName: artistName,
            albumName: collectionName,
            durationMs: durationMs,
            artworkUrl: highResArtwork,
            sourceType: AudioSourceType.networkStream,
            audioSourceUrl: previewUrl,
            genre: primaryGenre,
            addedAt: DateTime.now(),
          ));
        }

        return tracks;
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Get curated trending tracks by genre or theme
  Future<List<TrackModel>> getCuratedCategory(String category,
      {int limit = 15}) async {
    String searchTerm = category;
    if (category == 'Tamil Hits') {
      searchTerm = 'Tamil Anirudh AR Rahman';
    } else if (category == 'Trending Pop') {
      searchTerm = 'Top Hits 2025';
    } else if (category == 'Lofi Beats') {
      searchTerm = 'Lofi Hip Hop Chill Beats';
    } else if (category == 'Synthwave') {
      searchTerm = 'Synthwave Retro Electronic';
    } else if (category == 'Acoustic & Chill') {
      searchTerm = 'Acoustic Guitar Chill';
    } else if (category == 'Classical Focus') {
      searchTerm = 'Classical Piano Focus';
    }

    return searchTracks(searchTerm, limit: limit);
  }

  /// Get standard featured online tracks for home screen & explore
  Future<List<TrackModel>> getFeaturedOnlineTracks() async {
    return searchTracks('Top Chill Acoustic Electronic Synthwave', limit: 20);
  }
}
