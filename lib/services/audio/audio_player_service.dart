import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import '../../data/models/track_model.dart';
import '../../data/local/app_database.dart';

enum AudioRepeatMode {
  off,
  all,
  one,
}

/// Core audio playback engine supporting full-length local audio files, complete network streams, and previews
class AudioPlayerService {
  final AudioPlayer _player;
  final AppDatabase? _db;

  // State variables
  List<TrackModel> _queue = [];
  int _currentIndex = -1;
  bool _isShuffle = false;
  AudioRepeatMode _repeatMode = AudioRepeatMode.off;
  Timer? _sleepTimer;
  DateTime? _sleepTimerTarget;
  bool _isBuffering = false;

  // Stream controllers
  final _currentTrackController = StreamController<TrackModel?>.broadcast();
  final _queueController = StreamController<List<TrackModel>>.broadcast();
  final _shuffleController = StreamController<bool>.broadcast();
  final _repeatController = StreamController<AudioRepeatMode>.broadcast();
  final _sleepTimerController = StreamController<DateTime?>.broadcast();
  final _trackCompletedController = StreamController<TrackModel>.broadcast();
  final _bufferingController = StreamController<bool>.broadcast();

  AudioPlayerService([AudioPlayer? player, this._db])
      : _player = player ?? AudioPlayer() {
    _initAudioSession();
    _listenToPlayerEvents();
  }

  // Exposed Streams
  Stream<TrackModel?> get currentTrackStream => _currentTrackController.stream;
  Stream<List<TrackModel>> get queueStream => _queueController.stream;
  Stream<bool> get isPlayingStream => _player.playingStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;
  Stream<double> get speedStream => _player.speedStream;
  Stream<bool> get shuffleStream => _shuffleController.stream;
  Stream<AudioRepeatMode> get repeatStream => _repeatController.stream;
  Stream<DateTime?> get sleepTimerStream => _sleepTimerController.stream;
  Stream<TrackModel> get onTrackCompleted => _trackCompletedController.stream;
  Stream<bool> get bufferingStream => _bufferingController.stream;

  // Current State getters
  TrackModel? get currentTrack =>
      (_currentIndex >= 0 && _currentIndex < _queue.length)
          ? _queue[_currentIndex]
          : null;
  List<TrackModel> get queue => List.unmodifiable(_queue);
  int get currentIndex => _currentIndex;
  bool get isPlaying => _player.playing;
  bool get isBuffering => _isBuffering;
  bool get isShuffle => _isShuffle;
  AudioRepeatMode get repeatMode => _repeatMode;
  Duration get currentPosition => _player.position;
  Duration? get duration => _player.duration;
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
    // 1. Processing state & completion
    _player.playerStateStream.listen((state) {
      final isBuffering = state.processingState == ProcessingState.buffering ||
          state.processingState == ProcessingState.loading;
      if (isBuffering != _isBuffering) {
        _isBuffering = isBuffering;
        _bufferingController.add(_isBuffering);
      }

      if (state.processingState == ProcessingState.completed) {
        final finishedTrack = currentTrack;
        if (finishedTrack != null) {
          _trackCompletedController.add(finishedTrack);
        }
        _handleTrackCompletion();
      }
    });

    // 2. Real media duration synchronization from audio stream / file headers
    _player.durationStream.listen((realDuration) {
      if (realDuration != null && realDuration > Duration.zero) {
        final track = currentTrack;
        if (track != null && track.durationMs != realDuration.inMilliseconds) {
          final updatedTrack =
              track.copyWith(durationMs: realDuration.inMilliseconds);
          if (_currentIndex >= 0 && _currentIndex < _queue.length) {
            _queue[_currentIndex] = updatedTrack;
            _currentTrackController.add(updatedTrack);
            _queueController.add(_queue);
          }
          if (_db != null) {
            _db.insertOrUpdateTrack(updatedTrack);
          }
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

    try {
      if (track.sourceType == AudioSourceType.localFile) {
        if (kIsWeb) {
          await _player.setUrl(track.audioSourceUrl);
        } else {
          await _player.setFilePath(track.audioSourceUrl);
        }
      } else {
        // Network stream (full song, radio, or open stream)
        await _player.setUrl(track.audioSourceUrl);
      }
      await _player.play();
    } catch (e) {
      debugPrint('Error playing audio track: $e');
    }
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
    await _bufferingController.close();
  }
}
