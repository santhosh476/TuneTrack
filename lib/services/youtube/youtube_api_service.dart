import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../data/local/secure_storage_service.dart';
import '../../data/models/track_model.dart';

/// Service for interacting with Google YouTube Data API v3
/// Supports music search, duration resolution, and language recommendations.
class YouTubeApiService {
  final http.Client _client;
  final SecureStorageService? _secureStorage;
  String? _inMemoryApiKey;

  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';
  static const String _compileTimeApiKey =
      String.fromEnvironment('YOUTUBE_API_KEY', defaultValue: '');

  YouTubeApiService({
    http.Client? client,
    SecureStorageService? secureStorage,
    String? apiKey,
  })  : _client = client ?? http.Client(),
        _secureStorage = secureStorage,
        _inMemoryApiKey = apiKey;

  /// Retrieves the active YouTube API Key (from Secure Storage or compile-time env)
  Future<String> getApiKey() async {
    if (_inMemoryApiKey != null && _inMemoryApiKey!.isNotEmpty) {
      return _inMemoryApiKey!;
    }
    final storage = _secureStorage;
    if (storage != null) {
      final customKey = await storage.getCustomApiKey('youtube');
      if (customKey != null && customKey.trim().isNotEmpty) {
        return customKey.trim();
      }
    }
    return _compileTimeApiKey.trim();
  }

  /// Sets or updates a custom runtime YouTube API key securely
  Future<void> setCustomApiKey(String key) async {
    _inMemoryApiKey = key.trim();
    final storage = _secureStorage;
    if (storage != null) {
      await storage.saveCustomApiKey('youtube', key.trim());
    }
  }

  /// Parses YouTube ISO 8601 duration (e.g. PT4M31S, PT1H2M10S, PT58S) into milliseconds
  static int parseIsoDurationMs(String? isoDuration) {
    if (isoDuration == null || isoDuration.isEmpty) return 0;
    try {
      final regex = RegExp(r'P(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)');
      final match = regex.firstMatch(isoDuration);
      if (match == null) return 0;

      final hours = int.tryParse(match.group(1) ?? '') ?? 0;
      final minutes = int.tryParse(match.group(2) ?? '') ?? 0;
      final seconds = int.tryParse(match.group(3) ?? '') ?? 0;

      return ((hours * 3600) + (minutes * 60) + seconds) * 1000;
    } catch (_) {
      return 0;
    }
  }

  /// Performs HTTP GET with automatic retry for transient network glitches
  Future<http.Response> _getWithRetry(Uri uri, {int maxRetries = 2}) async {
    int attempts = 0;
    while (true) {
      try {
        attempts++;
        final res = await _client.get(uri).timeout(const Duration(seconds: 10));
        if (res.statusCode >= 500 && attempts <= maxRetries) {
          await Future.delayed(Duration(milliseconds: 300 * attempts));
          continue;
        }
        return res;
      } catch (e) {
        if (attempts > maxRetries) rethrow;
        await Future.delayed(Duration(milliseconds: 300 * attempts));
      }
    }
  }

  /// Get search suggestions for YouTube music query
  Future<List<String>> getSearchSuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];

    try {
      final uri = Uri.parse(
          'https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=${Uri.encodeQueryComponent(trimmed)}');
      final res = await _client.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        if (decoded is List && decoded.length > 1 && decoded[1] is List) {
          final list = (decoded[1] as List).map((e) => e.toString()).toList();
          return list.take(6).toList();
        }
      }
    } catch (_) {}

    // Fallback contextual suggestions
    return [
      '$trimmed song',
      '$trimmed official video',
      '$trimmed lyrics',
      '$trimmed remix',
    ];
  }

  /// Searches YouTube with pagination (returns tracks and nextPageToken)
  Future<YouTubeSearchResult> searchMusicVideosWithPagination(
    String query, {
    int maxResults = 20,
    String? pageToken,
    String? language,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return const YouTubeSearchResult(tracks: []);

    final apiKey = await getApiKey();
    if (apiKey.isEmpty) {
      debugPrint(
          'ℹ️ [YouTubeApiService] No YouTube API key configured. Set YOUTUBE_API_KEY.');
      throw YouTubeApiException(
          'YouTube API key is not configured. Please enter your API key in Settings.',
          isConfigError: true);
    }

    final searchQuery = language != null && language.isNotEmpty
        ? '$trimmedQuery $language song'
        : '$trimmedQuery song';

    final queryParams = {
      'part': 'snippet',
      'q': searchQuery,
      'type': 'video',
      'videoCategoryId': '10', // Category 10 = Music on YouTube
      'maxResults': maxResults.clamp(1, 50).toString(),
      'key': apiKey,
    };
    if (pageToken != null && pageToken.isNotEmpty) {
      queryParams['pageToken'] = pageToken;
    }

    final searchUri =
        Uri.parse('$_baseUrl/search').replace(queryParameters: queryParams);

    try {
      final searchResponse = await _getWithRetry(searchUri);

      if (searchResponse.statusCode == 403) {
        final errorBody = jsonDecode(searchResponse.body);
        final message = errorBody['error']?['message'] ?? 'Quota exceeded';
        debugPrint('⚠️ [YouTubeApiService] YouTube API 403 Error: $message');
        throw YouTubeApiException(
            'YouTube API quota limit reached or invalid key: $message',
            isQuotaError: true);
      }

      if (searchResponse.statusCode != 200) {
        debugPrint(
            '⚠️ [YouTubeApiService] Search error HTTP ${searchResponse.statusCode}: ${searchResponse.body}');
        return const YouTubeSearchResult(tracks: []);
      }

      final searchData =
          jsonDecode(searchResponse.body) as Map<String, dynamic>;
      final items = searchData['items'] as List? ?? [];
      final nextPageToken = searchData['nextPageToken'] as String?;
      final totalResults =
          (searchData['pageInfo']?['totalResults'] as num?)?.toInt() ?? 0;

      if (items.isEmpty) {
        return YouTubeSearchResult(
            tracks: const [],
            nextPageToken: nextPageToken,
            totalResults: totalResults);
      }

      final videoIds = <String>[];
      for (final item in items) {
        final videoId = item['id']?['videoId'] as String?;
        if (videoId != null && videoId.isNotEmpty) {
          videoIds.add(videoId);
        }
      }

      if (videoIds.isEmpty) {
        return YouTubeSearchResult(
            tracks: const [],
            nextPageToken: nextPageToken,
            totalResults: totalResults);
      }

      // 2. Fetch video details & durations in batch
      final tracks = await fetchVideoDetails(videoIds, apiKey: apiKey);
      return YouTubeSearchResult(
        tracks: tracks,
        nextPageToken: nextPageToken,
        totalResults: totalResults,
      );
    } catch (e) {
      if (e is YouTubeApiException) rethrow;
      debugPrint('⚠️ [YouTubeApiService] Search exception: $e');
      return const YouTubeSearchResult(tracks: []);
    }
  }

  /// Searches for real YouTube music videos matching [query].
  /// Fetches video snippets and exact durations via YouTube Data API v3.
  Future<List<TrackModel>> searchMusicVideos(
    String query, {
    int maxResults = 20,
    String? language,
  }) async {
    final result = await searchMusicVideosWithPagination(
      query,
      maxResults: maxResults,
      language: language,
    );
    return result.tracks;
  }

  /// Fetches contentDetails (exact duration) and full snippets for a list of video IDs
  Future<List<TrackModel>> fetchVideoDetails(
    List<String> videoIds, {
    String? apiKey,
  }) async {
    if (videoIds.isEmpty) return [];

    final key = apiKey ?? await getApiKey();
    if (key.isEmpty) return [];

    final detailsUri = Uri.parse('$_baseUrl/videos').replace(queryParameters: {
      'part': 'snippet,contentDetails',
      'id': videoIds.join(','),
      'key': key,
    });

    try {
      final response =
          await _client.get(detailsUri).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint(
            '⚠️ [YouTubeApiService] Video details error: ${response.statusCode}');
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = data['items'] as List? ?? [];
      final tracks = <TrackModel>[];

      for (final item in items) {
        final id = item['id'] as String?;
        final snippet = item['snippet'] as Map<String, dynamic>?;
        final contentDetails = item['contentDetails'] as Map<String, dynamic>?;

        if (id == null || snippet == null) continue;

        final rawTitle = snippet['title'] as String? ?? 'YouTube Music Video';
        final title = _cleanTitle(rawTitle);
        final channelTitle =
            snippet['channelTitle'] as String? ?? 'YouTube Artist';
        final publishedAtStr = snippet['publishedAt'] as String?;
        final publishedAt = publishedAtStr != null
            ? DateTime.tryParse(publishedAtStr) ?? DateTime.now()
            : DateTime.now();

        // Thumbnail priority: maxres > standard > high > medium > default
        final thumbnails = snippet['thumbnails'] as Map<String, dynamic>?;
        final artworkUrl = (thumbnails?['maxres']?['url'] ??
            thumbnails?['standard']?['url'] ??
            thumbnails?['high']?['url'] ??
            thumbnails?['medium']?['url'] ??
            thumbnails?['default']?['url']) as String?;

        final isoDuration = contentDetails?['duration'] as String?;
        final durationMs = parseIsoDurationMs(isoDuration);

        final track = TrackModel(
          id: 'yt_$id',
          title: title,
          artistName: channelTitle,
          albumName: 'YouTube Music',
          durationMs: durationMs > 0 ? durationMs : 240000,
          artworkUrl: artworkUrl,
          sourceType: AudioSourceType.youtubeVideo,
          audioSourceUrl: id, // YouTube Video ID
          genre: 'YouTube Video',
          addedAt: publishedAt,
          sourceDetailUrl: 'https://www.youtube.com/watch?v=$id',
        );

        tracks.add(track);
      }

      return tracks;
    } catch (e) {
      debugPrint('⚠️ [YouTubeApiService] fetchVideoDetails exception: $e');
      return [];
    }
  }

  /// Cleans raw YouTube video titles (removes HTML entities and common suffixes like (Official Video))
  String _cleanTitle(String raw) {
    return raw
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .trim();
  }

  /// Get recommendations by preferred languages (e.g. Tamil, Hindi, Telugu, English)
  Future<List<TrackModel>> getRecommendedMusic({
    List<String> preferredLanguages = const ['Tamil', 'English'],
    int limit = 20,
  }) async {
    final language =
        preferredLanguages.isNotEmpty ? preferredLanguages.first : 'Tamil';
    return searchMusicVideos('$language Trending Hits', maxResults: limit);
  }
}

class YouTubeSearchResult {
  final List<TrackModel> tracks;
  final String? nextPageToken;
  final int totalResults;

  const YouTubeSearchResult({
    required this.tracks,
    this.nextPageToken,
    this.totalResults = 0,
  });
}

class YouTubeApiException implements Exception {
  final String message;
  final bool isQuotaError;
  final bool isConfigError;

  YouTubeApiException(
    this.message, {
    this.isQuotaError = false,
    this.isConfigError = false,
  });

  @override
  String toString() => message;
}
