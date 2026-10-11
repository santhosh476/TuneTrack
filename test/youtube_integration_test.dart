import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/data/models/track_model.dart';
import 'package:flutter_application_1/services/youtube/youtube_api_service.dart';
import 'package:flutter_application_1/core/utils/duration_formatter.dart';

void main() {
  group('YouTube Data API v3 & In-App Playback Integration Tests', () {
    test(
        'YouTube ISO 8601 duration parser correctly parses full track durations (04:31 & 05:33)',
        () {
      // 4 minutes 31 seconds = 271,000 ms
      final durationMs1 = YouTubeApiService.parseIsoDurationMs('PT4M31S');
      expect(durationMs1, 271000);
      expect(DurationFormatter.formatMs(durationMs1), '04:31');

      // 5 minutes 33 seconds = 333,000 ms
      final durationMs2 = YouTubeApiService.parseIsoDurationMs('PT5M33S');
      expect(durationMs2, 333000);
      expect(DurationFormatter.formatMs(durationMs2), '05:33');

      // 1 hour, 15 minutes, 20 seconds = 4,520,000 ms
      final durationMs3 = YouTubeApiService.parseIsoDurationMs('PT1H15M20S');
      expect(durationMs3, 4520000);

      // Short video 45 seconds = 45,000 ms
      final durationMs4 = YouTubeApiService.parseIsoDurationMs('PT45S');
      expect(durationMs4, 45000);
      expect(DurationFormatter.formatMs(durationMs4), '00:45');
    });

    test(
        'searchMusicVideos searches YouTube and fetches verified video details & durations',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.endsWith('/search')) {
          final searchResponse = {
            'items': [
              {
                'id': {'videoId': 'yt_vid_arabic_kuthu_01'},
                'snippet': {
                  'title': 'Arabic Kuthu - Halamithi Habibo (Official Video)',
                  'channelTitle': 'Sun TV',
                }
              }
            ]
          };
          return http.Response(jsonEncode(searchResponse), 200,
              headers: {'content-type': 'application/json'});
        }

        if (request.url.path.endsWith('/videos')) {
          final videosResponse = {
            'items': [
              {
                'id': 'yt_vid_arabic_kuthu_01',
                'snippet': {
                  'title': 'Arabic Kuthu - Halamithi Habibo (Official Video)',
                  'channelTitle': 'Sun TV',
                  'publishedAt': '2022-02-14T12:00:00Z',
                  'thumbnails': {
                    'high': {
                      'url': 'https://i.ytimg.com/vi/arabic_kuthu/hqdefault.jpg'
                    },
                  }
                },
                'contentDetails': {
                  'duration': 'PT4M31S', // 04:31
                }
              }
            ]
          };
          return http.Response(jsonEncode(videosResponse), 200,
              headers: {'content-type': 'application/json'});
        }

        return http.Response('Not Found', 404);
      });

      final service = YouTubeApiService(client: mockClient);
      // Explicitly set key for testing
      await service.setCustomApiKey('mock_test_key_123');

      final results = await service.searchMusicVideos('Arabic Kuthu');

      expect(results.length, 1);
      final track = results.first;

      expect(track.id, 'yt_yt_vid_arabic_kuthu_01');
      expect(track.title, 'Arabic Kuthu - Halamithi Habibo (Official Video)');
      expect(track.artistName, 'Sun TV');
      expect(track.durationMs, 271000);
      expect(DurationFormatter.formatMs(track.durationMs), '04:31');
      expect(track.sourceType, AudioSourceType.youtubeVideo);
      expect(track.youtubeVideoId, 'yt_vid_arabic_kuthu_01');
      expect(track.artworkUrl,
          'https://i.ytimg.com/vi/arabic_kuthu/hqdefault.jpg');
      expect(track.sourceDetailUrl,
          'https://www.youtube.com/watch?v=yt_vid_arabic_kuthu_01');
    });

    test(
        'searchMusicVideos handles 403 quota exceeded error gracefully with YouTubeApiException',
        () async {
      final mockClient = MockClient((request) async {
        final quotaError = {
          'error': {
            'code': 403,
            'message':
                'The request cannot be completed because you have exceeded your quota.',
            'errors': [
              {'reason': 'quotaExceeded'}
            ]
          }
        };
        return http.Response(jsonEncode(quotaError), 403,
            headers: {'content-type': 'application/json'});
      });

      final service = YouTubeApiService(client: mockClient);
      await service.setCustomApiKey('mock_test_key_quota');

      expect(
        () async => await service.searchMusicVideos('Tamil Song'),
        throwsA(isA<YouTubeApiException>()),
      );
    });

    test(
        'TrackModel properly extracts YouTube Video ID for both clean IDs and watch URLs',
        () {
      final trackWithCleanId = TrackModel(
        id: 'yt_abc123xyz',
        title: 'Illuminati',
        artistName: 'Sushin Shyam',
        albumName: 'Aavesham',
        durationMs: 213000,
        sourceType: AudioSourceType.youtubeVideo,
        audioSourceUrl: 'abc123xyz',
        addedAt: DateTime(2026, 1, 1),
      );
      expect(trackWithCleanId.youtubeVideoId, 'abc123xyz');

      final trackWithWatchUrl = TrackModel(
        id: 'yt_def456uvw',
        title: 'Manasilaayo',
        artistName: 'Anirudh',
        albumName: 'Vettaiyan',
        durationMs: 250000,
        sourceType: AudioSourceType.youtubeVideo,
        audioSourceUrl: 'https://www.youtube.com/watch?v=def456uvw',
        addedAt: DateTime.now(),
      );
      expect(trackWithWatchUrl.youtubeVideoId, 'def456uvw');
    });
  });
}
