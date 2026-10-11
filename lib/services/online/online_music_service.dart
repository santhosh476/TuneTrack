import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/models/track_model.dart';

/// Legitimate, zero-API-key Online Music Service providing complete full-length audio playback
/// via open decentralized music catalogs (Audius Open API) and public domain/preview catalogs.
/// Requires NO tokens, NO credentials, NO paid accounts, and NO authentication.
class OnlineMusicService {
  final http.Client _client;

  OnlineMusicService([http.Client? client]) : _client = client ?? http.Client();

  static const String _audiusBaseUrl = 'https://api.audius.co/v1';

  /// Search online catalogue via Audius Open Catalog.
  /// Strictly returns 100% full-length streamable tracks with real durations.
  Future<List<TrackModel>> searchTracks(String query, {int limit = 25}) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    debugPrint(
        '🔍 [OnlineMusicService] Searching Audius Open Catalog for: "$trimmed" (limit: $limit)');

    final audiusTracks = await _searchAudiusTracks(trimmed, limit: limit);

    debugPrint(
        '✅ [OnlineMusicService] Found ${audiusTracks.length} full-length verified tracks from Audius');

    return audiusTracks.take(limit).toList();
  }

  /// Search Audius open catalog for 100% full-length tracks with full audio streams
  Future<List<TrackModel>> _searchAudiusTracks(String query,
      {int limit = 25}) async {
    final uri = Uri.parse('$_audiusBaseUrl/tracks/search').replace(
      queryParameters: {
        'query': query,
        'app_name': 'tunetrack',
        'limit': limit.toString(),
      },
    );

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['data'] as List? ?? [];
        final tracks = <TrackModel>[];

        for (final item in items) {
          if (item == null) continue;

          // Verify streamability and delete status
          final isStreamable = item['is_streamable'] as bool? ?? true;
          final isDelete = item['is_delete'] as bool? ?? false;
          if (!isStreamable || isDelete) continue;

          final trackId = item['id'] as String?;
          if (trackId == null || trackId.isEmpty) continue;

          final title = item['title'] as String? ?? 'Untitled Track';
          final user = item['user'] as Map<String, dynamic>?;
          final artistName = user?['name'] as String? ??
              user?['handle'] as String? ??
              'Artist';
          final genre = item['genre'] as String? ?? 'Online';

          // Duration in seconds -> convert to full milliseconds
          final durationSeconds = (item['duration'] as num?)?.toInt() ?? 0;
          if (durationSeconds <= 0) continue;
          final durationMs = durationSeconds * 1000;

          // High-resolution artwork
          final artworkMap = item['artwork'] as Map<String, dynamic>?;
          final artworkUrl = artworkMap?['480x480'] as String? ??
              artworkMap?['150x150'] as String? ??
              artworkMap?['1000x1000'] as String?;

          // Full-length direct audio stream URL with 302 redirect support
          final streamUrl =
              '$_audiusBaseUrl/tracks/$trackId/stream?app_name=tunetrack';

          debugPrint(
              '🎵 [OnlineMusicService] Audius Track: "$title" by $artistName | Full Duration: ${durationSeconds}s (${durationMs}ms) | Stream: $streamUrl');

          tracks.add(TrackModel(
            id: 'audius_$trackId',
            title: title,
            artistName: artistName,
            albumName: genre,
            durationMs: durationMs,
            artworkUrl: artworkUrl,
            sourceType: AudioSourceType.networkStream,
            audioSourceUrl: streamUrl,
            genre: genre,
            addedAt: DateTime.now(),
          ));
        }

        return tracks;
      } else {
        debugPrint(
            '⚠️ [OnlineMusicService] Audius search returned status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ [OnlineMusicService] Audius search exception: $e');
    }
    return [];
  }

  Future<List<TrackModel>> getFeaturedOnlineTracks({int limit = 20}) async {
    final uri = Uri.parse('$_audiusBaseUrl/tracks/trending').replace(
      queryParameters: {
        'app_name': 'tunetrack',
        'limit': limit.toString(),
      },
    );

    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final items = data['data'] as List? ?? [];
        final tracks = <TrackModel>[];

        for (final item in items) {
          if (item == null) continue;

          final isStreamable = item['is_streamable'] as bool? ?? true;
          final isDelete = item['is_delete'] as bool? ?? false;
          if (!isStreamable || isDelete) continue;

          final trackId = item['id'] as String?;
          if (trackId == null || trackId.isEmpty) continue;

          final title = item['title'] as String? ?? 'Trending Track';
          final user = item['user'] as Map<String, dynamic>?;
          final artistName = user?['name'] as String? ??
              user?['handle'] as String? ??
              'Artist';
          final genre = item['genre'] as String? ?? 'Trending';

          final durationSeconds = (item['duration'] as num?)?.toInt() ?? 0;
          if (durationSeconds <= 0) continue;
          final durationMs = durationSeconds * 1000;

          final artworkMap = item['artwork'] as Map<String, dynamic>?;
          final artworkUrl = artworkMap?['480x480'] as String? ??
              artworkMap?['150x150'] as String? ??
              artworkMap?['1000x1000'] as String?;

          final streamUrl =
              '$_audiusBaseUrl/tracks/$trackId/stream?app_name=tunetrack';

          tracks.add(TrackModel(
            id: 'audius_$trackId',
            title: title,
            artistName: artistName,
            albumName: genre,
            durationMs: durationMs,
            artworkUrl: artworkUrl,
            sourceType: AudioSourceType.networkStream,
            audioSourceUrl: streamUrl,
            genre: genre,
            addedAt: DateTime.now(),
          ));
        }

        if (tracks.isNotEmpty) return tracks;
      }
    } catch (_) {}

    return searchTracks('Electronic Chill Lofi Beats Pop', limit: limit);
  }

  /// Get curated category tracks
  Future<List<TrackModel>> getCuratedCategory(String category,
      {int limit = 15}) async {
    return searchTracks(category, limit: limit);
  }
}
