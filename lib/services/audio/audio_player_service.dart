import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../../data/models/track_model.dart';

enum AudioRepeatMode {
  off,
  all,
  one,
}

/// Core audio playback engine supporting local audio files, network streams, and demo assets
class AudioPlayerService {
  final AudioPlayer _player;

  // State variables
  List<TrackModel> _queue = [];
  int _currentIndex = -1;
  bool _isShuffle = false;
  AudioRepeatMode _repeatMode = AudioRepeatMode.off;
  Timer? _sleepTimer;
  DateTime? _sleepTimerTarget;

  // Stream controllers
  final _currentTrackController = StreamController<TrackModel?>.broadcast();
  final _queueController = StreamController<List<TrackModel>>.broadcast();
  final _shuffleController = StreamController<bool>.broadcast();
  final _repeatController = StreamController<AudioRepeatMode>.broadcast();
  final _sleepTimerController = StreamController<DateTime?>.broadcast();
  final _trackCompletedController = StreamController<TrackModel>.broadcast();

  AudioPlayerService([AudioPlayer? player])
      : _player = player ?? AudioPlayer() {
    _initAudioSession();
    _listenToPlayerEvents();
  }

  // Exposed Streams
  Stream<TrackModel?> get currentTrackStream => _currentTrackController.stream;
  Stream<List<TrackModel>> get queueStream => _queueController.stream;
  Stream<bool> get isPlayingStream => _player.playingStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<bool> get isBufferingStream => _player.playerStateStream
      .map((s) => s.processingState == ProcessingState.buffering);
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<double> get speedStream => _player.speedStream;
  Stream<double> get volumeStream => _player.volumeStream;
  Stream<bool> get shuffleStream => _shuffleController.stream;
  Stream<AudioRepeatMode> get repeatStream => _repeatController.stream;
  Stream<DateTime?> get sleepTimerStream => _sleepTimerController.stream;
  Stream<TrackModel> get onTrackCompleted => _trackCompletedController.stream;

  // Current State getters
  TrackModel? get currentTrack =>
      (_currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;
  List<TrackModel> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  bool get isPlaying => _player.playing;
  bool get isBuffering =>
      _player.playerState.processingState == ProcessingState.buffering;
  bool get isShuffle => _isShuffle;
  AudioRepeatMode get repeatMode => _repeatMode;
  Duration get currentPosition => _player.position;
  Duration? get duration => _player.duration;
  double get volume => _player.volume;
  DateTime? get sleepTimerTarget => _sleepTimerTarget;

  Future<void> _initAudioSession() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.music());

      // Handle headphone disconnection / noisy event
      session.becomingNoisyEventStream.listen((_) {
        pause();
      });

      // Handle audio interruptions (phone calls, other media)
      session.interruptionEventStream.listen((event) {
        if (event.begin) {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(0.3);
              break;
            case AudioInterruptionType.pause:
            case AudioInterruptionType.unknown:
              pause();
              break;
          }
        } else {
          switch (event.type) {
            case AudioInterruptionType.duck:
              _player.setVolume(1.0);
              break;
            case AudioInterruptionType.pause:
              // Optionally resume
              break;
            case AudioInterruptionType.unknown:
              break;
          }
        }
      });
    } catch (e) {
      debugPrint('AudioSession configuration failed: $e');
    }
  }

  void _listenToPlayerEvents() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        final finishedTrack = currentTrack;
        final pos = _player.position;
        final reason = _repeatMode == AudioRepeatMode.one
            ? 'Repeat One mode active (looping track)'
            : (hasNext
                ? 'Advancing to next track in queue'
                : (_repeatMode == AudioRepeatMode.all
                    ? 'Queue finished, repeating all from beginning'
                    : 'End of queue reached (playback stopped)'));

        debugPrint(
            '⏹️ [AudioPlayerService] Playback Completed for "${finishedTrack?.title}" at position ${pos.inSeconds}s (Total: ${finishedTrack?.duration.inSeconds}s). Reason: $reason');

        if (finishedTrack != null) {
          _trackCompletedController.add(finishedTrack);
        }
        _handleTrackCompletion();
      }
    });

    // Automatically sync real audio stream/file duration with current track model
    _player.durationStream.listen((dur) {
      if (dur != null &&
          dur.inMilliseconds > 0 &&
          _currentIndex >= 0 &&
          _currentIndex < _queue.length) {
        final current = _queue[_currentIndex];
        if (current.durationMs != dur.inMilliseconds) {
          debugPrint(
              '⏱️ [AudioPlayerService] Stream duration updated from server stream headers: ${dur.inSeconds}s (${dur.inMilliseconds}ms) for "${current.title}"');
          final updated = current.copyWith(durationMs: dur.inMilliseconds);
          _queue[_currentIndex] = updated;
          _currentTrackController.add(updated);
          _queueController.add(_queue);
        }
      }
    });
  }

  void _handleTrackCompletion() {
    if (_repeatMode == AudioRepeatMode.one) {
      _player.seek(Duration.zero);
      _player.play();
    } else if (hasNext) {
      next();
    } else if (_repeatMode == AudioRepeatMode.all && _queue.isNotEmpty) {
      playTrackAtIndex(0);
    } else {
      _player.stop();
    }
  }

  // Playback Control Actions
  Future<void> playTrack(TrackModel track,
      {List<TrackModel>? queueContext}) async {
    if (queueContext != null && queueContext.isNotEmpty) {
      _queue = List<TrackModel>.from(queueContext);
      _currentIndex = _queue.indexWhere((t) => t.id == track.id);
      if (_currentIndex == -1) {
        _queue.insert(0, track);
        _currentIndex = 0;
      }
    } else {
      final idx = _queue.indexWhere((t) => t.id == track.id);
      if (idx >= 0) {
        _currentIndex = idx;
      } else {
        _queue.add(track);
        _currentIndex = _queue.length - 1;
      }
    }

    _queueController.add(_queue);
    await _loadAndPlayCurrent();
  }

  Future<void> playTrackAtIndex(int index) async {
    if (index < 0 || index >= _queue.length) return;
    _currentIndex = index;
    await _loadAndPlayCurrent();
  }

  Future<void> _loadAndPlayCurrent() async {
    final track = currentTrack;
    if (track == null) return;

    _currentTrackController.add(track);

    String urlType = 'Network Stream';
    if (track.sourceType == AudioSourceType.localFile) {
      urlType = 'Local File';
    } else if (track.audioSourceUrl.contains('audius.co')) {
      urlType = 'Audius Full-Length Stream';
    } else if (track.audioSourceUrl.contains('itunes.apple.com') ||
        track.title.contains('(Preview)')) {
      urlType = 'iTunes 30-Second Preview Sample';
    } else if (track.sourceType == AudioSourceType.demoAsset) {
      urlType = 'Demo Audio Asset';
    }

    debugPrint(
        '▶️ [AudioPlayerService] Loading track [${track.id}] "${track.title}" by ${track.artistName} | URL Type: $urlType | Expected Duration: ${track.duration.inSeconds}s (${track.durationMs}ms)');

    try {
      Duration? loadedDuration;
      final playableUrl = (track.previewUrl != null && track.previewUrl!.isNotEmpty)
          ? track.previewUrl!
          : track.audioSourceUrl;

      if (track.sourceType == AudioSourceType.localFile) {
        if (kIsWeb) {
          loadedDuration = await _player.setUrl(playableUrl);
        } else {
          loadedDuration = await _player.setFilePath(playableUrl);
        }
      } else if (playableUrl.startsWith('http://') ||
          playableUrl.startsWith('https://')) {
        // Direct stream, Audius stream, or audio preview URL
        loadedDuration = await _player.setUrl(playableUrl);
      } else {
        debugPrint(
            'ℹ️ [AudioPlayerService] Track has non-stream URL ($playableUrl). Playback handoff recommended.');
        return;
      }

      if (loadedDuration != null && loadedDuration.inMilliseconds > 0) {
        debugPrint(
            '✅ [AudioPlayerService] Player stream loaded successfully: actual duration = ${loadedDuration.inSeconds}s (${loadedDuration.inMilliseconds}ms)');
        if (_currentIndex >= 0 && _currentIndex < _queue.length) {
          final updated = _queue[_currentIndex].copyWith(
            durationMs: loadedDuration.inMilliseconds,
          );
          _queue[_currentIndex] = updated;
          _currentTrackController.add(updated);
          _queueController.add(_queue);
        }
      }

      await _player.play();
    } catch (e) {
      debugPrint('❌ [AudioPlayerService] Error playing audio track: $e');
    }
  }

  Future<void> retryCurrentTrack() async {
    await _loadAndPlayCurrent();
  }

  Future<void> play() async => _player.play();
  Future<void> pause() async => _player.pause();
  Future<void> stop() async => _player.stop();

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  bool get hasNext => _currentIndex < _queue.length - 1;
  bool get hasPrevious => _currentIndex > 0;

  Future<void> next() async {
    if (_player.position.inSeconds > 3) {
      // Record partial listening session if appropriate
    }
    if (hasNext) {
      _currentIndex++;
      await _loadAndPlayCurrent();
    } else if (_repeatMode == AudioRepeatMode.all && _queue.isNotEmpty) {
      _currentIndex = 0;
      await _loadAndPlayCurrent();
    }
  }

  Future<void> previous() async {
    if (_player.position.inSeconds > 3) {
      // If played for > 3 seconds, replay track from start
      await seek(Duration.zero);
      return;
    }
    if (hasPrevious) {
      _currentIndex--;
      await _loadAndPlayCurrent();
    } else {
      await seek(Duration.zero);
    }
  }

  void toggleShuffle() {
    _isShuffle = !_isShuffle;
    _shuffleController.add(_isShuffle);
    if (_isShuffle && _queue.isNotEmpty) {
      final current = currentTrack;
      final rest = List<TrackModel>.from(_queue);
      if (current != null) rest.remove(current);
      rest.shuffle();
      if (current != null) rest.insert(0, current);
      _queue = rest;
      _currentIndex = 0;
      _queueController.add(_queue);
    }
  }

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case AudioRepeatMode.off:
        _repeatMode = AudioRepeatMode.all;
        break;
      case AudioRepeatMode.all:
        _repeatMode = AudioRepeatMode.one;
        break;
      case AudioRepeatMode.one:
        _repeatMode = AudioRepeatMode.off;
        break;
    }
    _repeatController.add(_repeatMode);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    await _player.setSpeed(speed);
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  // Queue manipulation
  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 ||
        oldIndex >= _queue.length ||
        newIndex < 0 ||
        newIndex > _queue.length) {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _queue.removeAt(oldIndex);
    _queue.insert(newIndex, item);

    // Update current index
    if (oldIndex == _currentIndex) {
      _currentIndex = newIndex;
    } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
      _currentIndex -= 1;
    } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
      _currentIndex += 1;
    }
    _queueController.add(_queue);
  }

  void removeQueueItem(int index) {
    if (index < 0 || index >= _queue.length) return;
    _queue.removeAt(index);
    if (index < _currentIndex) {
      _currentIndex -= 1;
    } else if (index == _currentIndex) {
      if (_currentIndex >= _queue.length) {
        _currentIndex = _queue.length - 1;
      }
      if (_currentIndex >= 0) {
        _loadAndPlayCurrent();
      } else {
        stop();
        _currentTrackController.add(null);
      }
    }
    _queueController.add(_queue);
  }

  void clearQueue() {
    stop();
    _queue.clear();
    _currentIndex = -1;
    _currentTrackController.add(null);
    _queueController.add(_queue);
  }

  // Sleep Timer
  void setSleepTimer(Duration duration) {
    cancelSleepTimer();
    _sleepTimerTarget = DateTime.now().add(duration);
    _sleepTimerController.add(_sleepTimerTarget);
    _sleepTimer = Timer(duration, () {
      pause();
      cancelSleepTimer();
    });
  }

  void cancelSleepTimer() {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepTimerTarget = null;
    _sleepTimerController.add(null);
  }

  Future<void> dispose() async {
    cancelSleepTimer();
    await _player.dispose();
    await _currentTrackController.close();
    await _queueController.close();
    await _shuffleController.close();
    await _repeatController.close();
    await _sleepTimerController.close();
    await _trackCompletedController.close();
  }
}
