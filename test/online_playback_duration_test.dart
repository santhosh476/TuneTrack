import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_application_1/data/models/track_model.dart';
import 'package:flutter_application_1/services/online/online_music_service.dart';
import 'package:flutter_application_1/core/utils/duration_formatter.dart';

void main() {
  group('OnlineMusicService & Duration Synchronization Tests', () {
    test(
        'Audius full-length track returns exact duration and full stream URL (04:31 & 05:33)',
        () async {
      // Mock Audius returning 04:31 (271s) and 05:33 (333s) full tracks
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/tracks/search')) {
          final responseData = {
            'data': [
              {
                'id': 'track_04_31',
                'title': 'Full Length Arabic Kuthu Remix',
                'duration': 271, // 4 minutes 31 seconds
                'is_streamable': true,
                'is_delete': false,
                'genre': 'Pop',
                'user': {'name': 'Anirudh Fan'},
                'artwork': {
                  '480x480': 'https://example.com/artwork1.jpg',
                },
              },
              {
                'id': 'track_05_33',
                'title': 'Full Length Extended Symphony',
                'duration': 333, // 5 minutes 33 seconds
                'is_streamable': true,
                'is_delete': false,
                'genre': 'Classical',
                'user': {'name': 'Maestro'},
                'artwork': {
                  '480x480': 'https://example.com/artwork2.jpg',
                },
              }
            ]
          };
          return http.Response(jsonEncode(responseData), 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final service = OnlineMusicService(mockClient);
      final results = await service.searchTracks('Arabic Kuthu');

      expect(results.length, 2);

      // Track 1: 04:31 (271 seconds)
      final track1 = results[0];
      expect(track1.id, 'audius_track_04_31');
      expect(track1.title, 'Full Length Arabic Kuthu Remix');
      expect(track1.durationMs, 271000);
      expect(DurationFormatter.formatMs(track1.durationMs), '04:31');
      expect(track1.duration.inSeconds, 271);
      expect(track1.duration.inSeconds > 30, isTrue);
      expect(track1.audioSourceUrl,
          'https://api.audius.co/v1/tracks/track_04_31/stream?app_name=tunetrack');
      expect(track1.sourceType, AudioSourceType.networkStream);

      // Track 2: 05:33 (333 seconds)
      final track2 = results[1];
      expect(track2.id, 'audius_track_05_33');
      expect(track2.title, 'Full Length Extended Symphony');
      expect(track2.durationMs, 333000);
      expect(DurationFormatter.formatMs(track2.durationMs), '05:33');
      expect(track2.duration.inSeconds, 333);
      expect(track2.duration.inSeconds > 30, isTrue);
      expect(track2.audioSourceUrl,
          'https://api.audius.co/v1/tracks/track_05_33/stream?app_name=tunetrack');
      expect(track2.sourceType, AudioSourceType.networkStream);
    });

    test(
        'OnlineMusicService strictly returns 100% full-length streamable tracks',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('/tracks/search')) {
          final responseData = {
            'data': [
              {
                'id': 'full_track_99',
                'title': 'Full Tamil Cinema Song',
                'duration': 285, // 4 mins 45 secs
                'is_streamable': true,
                'is_delete': false,
                'genre': 'Soundtrack',
                'user': {'name': 'Composer Official'},
                'artwork': {
                  '480x480': 'https://example.com/artwork99.jpg',
                },
              }
            ]
          };
          return http.Response(jsonEncode(responseData), 200,
              headers: {'content-type': 'application/json'});
        }
        return http.Response('Not Found', 404);
      });

      final service = OnlineMusicService(mockClient);
      final results = await service.searchTracks('Full Tamil Song');

      expect(results.length, 1);
      final track = results[0];

      // Must NOT contain Preview
      expect(track.title.contains('(Preview)'), isFalse);
      // Duration MUST be full 285000ms (04:45)
      expect(track.durationMs, 285000);
      expect(DurationFormatter.formatMs(track.durationMs), '04:45');
      expect(track.audioSourceUrl,
          'https://api.audius.co/v1/tracks/full_track_99/stream?app_name=tunetrack');
      expect(track.sourceType, AudioSourceType.networkStream);
    });

    test(
        'Internet Archive public audio catalog returns full-length verified audio files with license & source metadata',
        () async {
      final mockClient = MockClient((request) async {
        if (request.url.path.contains('advancedsearch.php')) {
          final searchResponse = {
            'response': {
              'docs': [
                {
                  'identifier': 'tamil_public_record_01',
                  'title': 'Tamil Public Melody Collection',
                  'creator': 'Maestro Archives',
                  'licenseurl': 'https://creativecommons.org/licenses/by/4.0/',
                  'description': 'Public audio collection',
                }
              ]
            }
          };
          return http.Response(jsonEncode(searchResponse), 200,
              headers: {'content-type': 'application/json'});
        }

        if (request.url.path.contains('/metadata/tamil_public_record_01')) {
          final metadataResponse = {
            'files': [
              {
                'name': 'poove_sempoove.mp3',
                'format': 'VBR MP3',
                'length': '329.74', // 5 minutes 29.74 seconds (329740ms)
                'title': 'Poove Sempoove Full Song',
              },
              {
                'name': 'track_info.txt',
                'format': 'Text',
                // Non-audio file, should be ignored
              }
            ]
          };
          return http.Response(jsonEncode(metadataResponse), 200,
              headers: {'content-type': 'application/json'});
        }

        return http.Response('Not Found', 404);
      });

      final service = OnlineMusicService(mockClient);
      final results = await service.searchTracks('Poove Sempoove');

      expect(results.length, 1);
      final track = results[0];

      expect(track.id.startsWith('ia_tamil_public_record_01'), isTrue);
      expect(track.title, 'Poove Sempoove Full Song');
      expect(track.artistName, 'Maestro Archives');
      expect(track.durationMs, 329740);
      expect(DurationFormatter.formatMs(track.durationMs), '05:29');
      expect(track.duration.inSeconds, 329);
      expect(track.duration.inSeconds > 30, isTrue);
      expect(track.audioSourceUrl,
          'https://archive.org/download/tamil_public_record_01/poove_sempoove.mp3');
      expect(track.sourceDetailUrl,
          'https://archive.org/details/tamil_public_record_01');
      expect(track.license, 'https://creativecommons.org/licenses/by/4.0/');
      expect(track.artworkUrl,
          'https://archive.org/services/img/tamil_public_record_01');
    });

    test('DurationFormatter correctly formats 04:31 and 05:33 durations', () {
      expect(DurationFormatter.formatMs(271000), '04:31');
      expect(DurationFormatter.formatMs(333000), '05:33');
      expect(DurationFormatter.format(const Duration(seconds: 271)), '04:31');
      expect(DurationFormatter.format(const Duration(seconds: 333)), '05:33');
    });
  });
}
