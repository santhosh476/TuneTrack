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
  });
}
