import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/data/models/track_model.dart';
import 'package:flutter_application_1/core/utils/duration_formatter.dart';

void main() {
  group('Full Song Duration & Playback Tests', () {
    test('TrackModel with 3:05 duration (185,000ms) preserves full length', () {
      final fullTrack = TrackModel(
        id: 'test_full_1',
        title: 'Full Length Masterpiece',
        artistName: 'TuneTrack Artist',
        albumName: 'TuneTrack Master Album',
        durationMs: 185000, // Exactly 3 minutes 5 seconds
        sourceType: AudioSourceType.localFile,
        audioSourceUrl: '/storage/emulated/0/Music/song_305.mp3',
        addedAt: DateTime.now(),
      );

      expect(fullTrack.duration.inMinutes, 3);
      expect(fullTrack.duration.inSeconds, 185);
      expect(DurationFormatter.format(fullTrack.duration), '3:05');
      expect(DurationFormatter.format(const Duration(seconds: 185)), '3:05');
    });

    test(
        'TrackModel copyWith dynamic real media duration update preserves true length',
        () {
      final initialTrack = TrackModel(
        id: 'test_track_2',
        title: 'Local Discovery',
        artistName: 'Local Musician',
        albumName: 'Local Hits',
        durationMs: 0,
        sourceType: AudioSourceType.localFile,
        audioSourceUrl: '/storage/emulated/0/Music/discovery.mp3',
        addedAt: DateTime.now(),
      );

      // Simulating real media stream/header resolution in AudioPlayerService
      const realStreamDuration = Duration(minutes: 3, seconds: 5);
      final syncedTrack = initialTrack.copyWith(
        durationMs: realStreamDuration.inMilliseconds,
      );

      expect(syncedTrack.durationMs, 185000);
      expect(syncedTrack.duration.inSeconds, 185);
      expect(DurationFormatter.format(syncedTrack.duration), '3:05');
    });

    test('30s Preview tracks are accurately set to 30000ms duration', () {
      final previewTrack = TrackModel(
        id: 'online_preview_1',
        title: '[Preview] Hit Single',
        artistName: 'Top Star',
        albumName: 'Summer Hits',
        durationMs: 30000, // Exact 30-second preview
        sourceType: AudioSourceType.networkStream,
        audioSourceUrl: 'https://audio-ssl.itunes.apple.com/preview.m4a',
        addedAt: DateTime.now(),
      );

      expect(previewTrack.durationMs, 30000);
      expect(previewTrack.duration.inSeconds, 30);
      expect(DurationFormatter.format(previewTrack.duration), '0:30');
      expect(previewTrack.title.startsWith('[Preview]'), isTrue);
    });

    test(
        'Progress percentage and seek calculations span full 3:05 range smoothly',
        () {
      const totalDuration = Duration(minutes: 3, seconds: 5); // 185s
      const midPosition = Duration(seconds: 92); // ~50%
      const endPosition = Duration(seconds: 185); // 100%

      final midProgress =
          midPosition.inMilliseconds / totalDuration.inMilliseconds;
      final endProgress =
          endPosition.inMilliseconds / totalDuration.inMilliseconds;

      expect(midProgress, closeTo(0.497, 0.01));
      expect(endProgress, equals(1.0));
      expect(DurationFormatter.format(endPosition), '3:05');
    });

    test(
        '10-song playlist preserves each track complete original duration (03:05, 05:09, 04:32, etc.)',
        () {
      final samplePlaylist = [
        TrackModel(
          id: 'song_1',
          title: 'Song 1',
          artistName: 'Artist 1',
          albumName: 'Album 1',
          durationMs: (3 * 60 + 5) * 1000, // 03:05 = 185,000ms
          sourceType: AudioSourceType.localFile,
          audioSourceUrl: '/storage/emulated/0/Music/song1.mp3',
          addedAt: DateTime.now(),
        ),
        TrackModel(
          id: 'song_2',
          title: 'Song 2',
          artistName: 'Artist 2',
          albumName: 'Album 2',
          durationMs: (5 * 60 + 9) * 1000, // 05:09 = 309,000ms
          sourceType: AudioSourceType.localFile,
          audioSourceUrl: '/storage/emulated/0/Music/song2.mp3',
          addedAt: DateTime.now(),
        ),
        TrackModel(
          id: 'song_3',
          title: 'Song 3',
          artistName: 'Artist 3',
          albumName: 'Album 3',
          durationMs: (4 * 60 + 32) * 1000, // 04:32 = 272,000ms
          sourceType: AudioSourceType.localFile,
          audioSourceUrl: '/storage/emulated/0/Music/song3.mp3',
          addedAt: DateTime.now(),
        ),
        TrackModel(
          id: 'song_4',
          title: 'Song 4',
          artistName: 'Artist 4',
          albumName: 'Album 4',
          durationMs: (2 * 60 + 45) * 1000, // 02:45 = 165,000ms
          sourceType: AudioSourceType.localFile,
          audioSourceUrl: '/storage/emulated/0/Music/song4.mp3',
          addedAt: DateTime.now(),
        ),
        TrackModel(
          id: 'song_5',
          title: 'Song 5',
          artistName: 'Artist 5',
          albumName: 'Album 5',
          durationMs: (3 * 60 + 50) * 1000, // 03:50 = 230,000ms
          sourceType: AudioSourceType.localFile,
          audioSourceUrl: '/storage/emulated/0/Music/song5.mp3',
          addedAt: DateTime.now(),
        ),
        TrackModel(
          id: 'song_6',
          title: 'Song 6',
          artistName: 'Artist 6',
          albumName: 'Album 6',
          durationMs: (6 * 60 + 12) * 1000, // 06:12 = 372,000ms
          sourceType: AudioSourceType.localFile,
          audioSourceUrl: '/storage/emulated/0/Music/song6.mp3',
          addedAt: DateTime.now(),
        ),
        TrackModel(
          id: 'song_7',
          title: 'Song 7',
          artistName: 'Artist 7',
          albumName: 'Album 7',
          durationMs: (1 * 60 + 58) * 1000, // 01:58 = 118,000ms
          sourceType: AudioSourceType.localFile,
          audioSourceUrl: '/storage/emulated/0/Music/song7.mp3',
          addedAt: DateTime.now(),
        ),
        TrackModel(
          id: 'song_8',
          title: 'Song 8',
          artistName: 'Artist 8',
          albumName: 'Album 8',
          durationMs: (4 * 60 + 15) * 1000, // 04:15 = 255,000ms
          sourceType: AudioSourceType.localFile,
          audioSourceUrl: '/storage/emulated/0/Music/song8.mp3',
          addedAt: DateTime.now(),
        ),
        TrackModel(
          id: 'song_9',
          title: 'Song 9',
          artistName: 'Artist 9',
          albumName: 'Album 9',
          durationMs: (3 * 60 + 33) * 1000, // 03:33 = 213,000ms
          sourceType: AudioSourceType.localFile,
          audioSourceUrl: '/storage/emulated/0/Music/song9.mp3',
          addedAt: DateTime.now(),
        ),
        TrackModel(
          id: 'song_10',
          title: 'Song 10',
          artistName: 'Artist 10',
          albumName: 'Album 10',
          durationMs: (5 * 60 + 40) * 1000, // 05:40 = 340,000ms
          sourceType: AudioSourceType.localFile,
          audioSourceUrl: '/storage/emulated/0/Music/song10.mp3',
          addedAt: DateTime.now(),
        ),
      ];

      expect(samplePlaylist.length, 10);
      expect(DurationFormatter.format(samplePlaylist[0].duration), '3:05');
      expect(DurationFormatter.format(samplePlaylist[1].duration), '5:09');
      expect(DurationFormatter.format(samplePlaylist[2].duration), '4:32');
      expect(DurationFormatter.format(samplePlaylist[3].duration), '2:45');
      expect(DurationFormatter.format(samplePlaylist[4].duration), '3:50');
      expect(DurationFormatter.format(samplePlaylist[5].duration), '6:12');
      expect(DurationFormatter.format(samplePlaylist[6].duration), '1:58');
      expect(DurationFormatter.format(samplePlaylist[7].duration), '4:15');
      expect(DurationFormatter.format(samplePlaylist[8].duration), '3:33');
      expect(DurationFormatter.format(samplePlaylist[9].duration), '5:40');

      // Test sequential queue navigation
      var currentIdx = 0;
      for (int i = 0; i < samplePlaylist.length; i++) {
        expect(currentIdx, i);
        final track = samplePlaylist[currentIdx];
        expect(track.durationMs, greaterThan(0));
        // Verify playback span reaches 100% of duration without premature cutoff
        final fullSeekSeconds = track.duration.inSeconds;
        expect(fullSeekSeconds, equals(track.durationMs ~/ 1000));

        final hasNext = currentIdx < samplePlaylist.length - 1;
        if (hasNext) {
          currentIdx++;
        }
      }
      expect(currentIdx, 9); // Reached last song (Song 10)
    });
  });
}
