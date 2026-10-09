import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/id_generator.dart';
import '../../data/models/track_model.dart';
import '../../data/models/listening_session_model.dart';
import '../../data/repositories/listening_session_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../services/audio/audio_player_service.dart';

/// Accurate, idempotent listening tracker that measures audible playback duration
/// strictly excluding paused, buffering, and seeking intervals
class ListeningTrackerService {
  final AudioPlayerService _audioService;
  final ListeningSessionRepository _sessionRepo;
  final UserRepository _userRepo;

  // Active tracking state
  TrackModel? _currentTrackingTrack;
  DateTime? _sessionStartUtc;
  int _audibleSecondsAccrued = 0;
  Timer? _tickerTimer;
  bool _isAudiblePlaying = false;

  StreamSubscription? _trackSub;
  StreamSubscription? _playerStateSub;
  StreamSubscription? _completedSub;

  ListeningTrackerService(
    this._audioService,
    this._sessionRepo,
    this._userRepo,
  ) {
    _startListening();
  }

  void _startListening() {
    // 1. Track changes
    _trackSub = _audioService.currentTrackStream.listen((track) {
      if (_currentTrackingTrack?.id != track?.id) {
        _finalizeCurrentSession(isCompleted: false);
        _startNewSession(track);
      }
    });

    // 2. Audible state changes (Playing vs Paused/Buffering)
    _playerStateSub = _audioService.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      final isReady = state.processingState == ProcessingState.ready;
      final isAudible = isPlaying && isReady;

      if (isAudible != _isAudiblePlaying) {
        _isAudiblePlaying = isAudible;
        if (_isAudiblePlaying) {
          _startAudibleTicker();
        } else {
          _stopAudibleTicker();
        }
      }
    });

    // 3. Track completion
    _completedSub = _audioService.onTrackCompleted.listen((track) {
      if (_currentTrackingTrack?.id == track.id) {
        _finalizeCurrentSession(isCompleted: true);
      }
    });
  }

  void _startNewSession(TrackModel? track) {
    if (track == null) {
      _currentTrackingTrack = null;
      _sessionStartUtc = null;
      _audibleSecondsAccrued = 0;
      return;
    }

    _currentTrackingTrack = track;
    _sessionStartUtc = DateTime.now().toUtc();
    _audibleSecondsAccrued = 0;

    if (_audioService.isPlaying) {
      _isAudiblePlaying = true;
      _startAudibleTicker();
    }
  }

  void _startAudibleTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isAudiblePlaying && _currentTrackingTrack != null) {
        _audibleSecondsAccrued++;
      }
    });
  }

  void _stopAudibleTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
  }

  /// Finalize and persist listening session if it meets qualification criteria
  void _finalizeCurrentSession({required bool isCompleted}) {
    _stopAudibleTicker();

    final track = _currentTrackingTrack;
    final startTime = _sessionStartUtc;
    final accrued = _audibleSecondsAccrued;

    // Reset current accumulator
    _audibleSecondsAccrued = 0;
    _sessionStartUtc = null;

    if (track == null || startTime == null || accrued <= 0) {
      return;
    }

    final endTime = DateTime.now().toUtc();
    final userId = _userRepo.getActiveUserId();

    // Check minimum qualification: 30 seconds OR completion of track
    final meetsThreshold =
        accrued >= AppConstants.minListeningThresholdSeconds || isCompleted;

    if (meetsThreshold) {
      final session = ListeningSessionModel(
        id: IdGenerator.generateSessionId(),
        userId: userId,
        trackId: track.id,
        trackTitle: track.title,
        artistName: track.artistName,
        albumName: track.albumName,
        artworkUrl: track.artworkUrl,
        genre: track.genre,
        playbackSource: track.sourceType.name,
        startedAt: startTime,
        endedAt: endTime,
        audibleDurationSeconds: accrued,
        isCompleted: isCompleted,
        isSynced: false,
      );

      _sessionRepo.recordSession(session);
      debugPrint(
          'Recorded valid listening session: ${track.title} for ${accrued}s (completed: $isCompleted)');
    }
  }

  /// Method for unit testing session calculation logic
  static bool calculateIsValidPlay(
      int audibleDurationSeconds, bool isCompleted) {
    return audibleDurationSeconds >=
            AppConstants.minListeningThresholdSeconds ||
        isCompleted;
  }

  void dispose() {
    _finalizeCurrentSession(isCompleted: false);
    _trackSub?.cancel();
    _playerStateSub?.cancel();
    _completedSub?.cancel();
    _stopAudibleTicker();
  }
}
