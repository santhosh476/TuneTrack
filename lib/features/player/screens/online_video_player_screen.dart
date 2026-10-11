import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/track_model.dart';

/// Full-featured, responsive Online Video Player Screen for authorized HTTPS video streams
class OnlineVideoPlayerScreen extends StatefulWidget {
  final TrackModel track;

  const OnlineVideoPlayerScreen({
    super.key,
    required this.track,
  });

  @override
  State<OnlineVideoPlayerScreen> createState() =>
      _OnlineVideoPlayerScreenState();
}

class _OnlineVideoPlayerScreenState extends State<OnlineVideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _showControls = true;
  bool _isFullScreen = false;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    setState(() {
      _hasError = false;
      _errorMessage = '';
      _isInitialized = false;
    });

    final videoUrl = widget.track.audioSourceUrl.isNotEmpty
        ? widget.track.audioSourceUrl
        : (widget.track.sourceDetailUrl ?? '');

    if (videoUrl.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Video URL is empty or invalid.';
      });
      return;
    }

    try {
      final uri = Uri.parse(videoUrl);
      _controller = VideoPlayerController.networkUrl(uri);
      await _controller.initialize();
      _controller.addListener(_videoListener);
      await _controller.setVolume(_volume);
      await _controller.play();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Unable to load video stream. The source might be offline or in an unsupported format.\nDetails: $e';
        });
      }
    }
  }

  void _videoListener() {
    if (mounted) {
      setState(() {});
    }
  }

  void _togglePlayPause() {
    if (!_isInitialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  void _seekRelative(int seconds) {
    if (!_isInitialized) return;
    final currentPos = _controller.value.position;
    final targetPos = currentPos + Duration(seconds: seconds);
    final clamped = targetPos < Duration.zero
        ? Duration.zero
        : (targetPos > _controller.value.duration
            ? _controller.value.duration
            : targetPos);
    _controller.seekTo(clamped);
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } else {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_videoListener);
    _controller.dispose();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isFullScreen) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: _buildVideoView(isFull: true),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: Text(
          widget.track.title,
          style: AppTypography.titleMedium.copyWith(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 14),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF8E2DE2).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF8E2DE2), width: 0.8),
            ),
            child: const Row(
              children: [
                Icon(Icons.ondemand_video_rounded,
                    size: 14, color: Color(0xFFC471ED)),
                SizedBox(width: 4),
                Text(
                  'Video Stream',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFC471ED),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Video Player Canvas
            Container(
              color: Colors.black,
              width: double.infinity,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: _buildVideoView(isFull: false),
              ),
            ),

            // 2. Metadata & Details Below
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.track.title,
                              style: AppTypography.displayMedium
                                  .copyWith(fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.track.artistName,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.secondaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _volume > 0
                              ? Icons.volume_up_rounded
                              : Icons.volume_off_rounded,
                          color: AppColors.primaryAccent,
                        ),
                        onPressed: () {
                          setState(() {
                            _volume = _volume > 0 ? 0.0 : 1.0;
                            if (_isInitialized) {
                              _controller.setVolume(_volume);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Volume Slider Card
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.volume_down_rounded,
                            size: 18, color: AppColors.secondaryText),
                        Expanded(
                          child: Slider(
                            value: _volume,
                            min: 0.0,
                            max: 1.0,
                            activeColor: AppColors.primaryAccent,
                            inactiveColor: Colors.white12,
                            onChanged: (v) {
                              setState(() {
                                _volume = v;
                                if (_isInitialized) {
                                  _controller.setVolume(_volume);
                                }
                              });
                            },
                          ),
                        ),
                        const Icon(Icons.volume_up_rounded,
                            size: 18, color: AppColors.secondaryText),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Policy & Background Playback Notice Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 0.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.info_outline_rounded,
                                size: 16, color: AppColors.info),
                            SizedBox(width: 8),
                            Text(
                              'Video Playback & Background Audio',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '• This is an authorized HTTPS video stream rendered in high definition.\n'
                          '• Full-screen and landscape viewing are fully supported via the expand button.\n'
                          '• Note: Video playback requires an active display. For locked-screen or minimized background playback, stream from the Online Audio or Spotify preview sources.',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.secondaryText,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stream Source Details
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Stream Information',
                            style: AppTypography.titleSmall
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Source: Authorized HTTPS Video Stream',
                            style: AppTypography.bodySmall),
                        const SizedBox(height: 4),
                        Text(
                            'Duration: ${DurationFormatter.formatMs(widget.track.durationMs)}',
                            style: AppTypography.bodySmall),
                        if (widget.track.license != null) ...[
                          const SizedBox(height: 4),
                          Text('License: ${widget.track.license}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.primaryAccent,
                              )),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoView({required bool isFull}) {
    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: AppColors.error, size: 40),
              const SizedBox(height: 8),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(color: AppColors.secondaryText, fontSize: 12),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.black),
                onPressed: _initializePlayer,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry Playback'),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryAccent),
      );
    }

    final isPlaying = _controller.value.isPlaying;
    final position = _controller.value.position;
    final duration = _controller.value.duration;
    final isBuffering = _controller.value.isBuffering;

    return GestureDetector(
      onTap: () {
        setState(() {
          _showControls = !_showControls;
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Video Itself
          Center(
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),

          // Buffering Indicator
          if (isBuffering)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.primaryAccent,
                ),
              ),
            ),

          // Video Controls Overlay
          if (_showControls)
            Container(
              color: Colors.black.withValues(alpha: 0.45),
              child: Stack(
                children: [
                  // Center Controls: Rewind, Play/Pause, Forward
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 34,
                          icon: const Icon(Icons.replay_10_rounded,
                              color: Colors.white),
                          onPressed: () => _seekRelative(-10),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: _togglePlayPause,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryAccent,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 38,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        IconButton(
                          iconSize: 34,
                          icon: const Icon(Icons.forward_10_rounded,
                              color: Colors.white),
                          onPressed: () => _seekRelative(10),
                        ),
                      ],
                    ),
                  ),

                  // Bottom Progress Bar & Fullscreen Button
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: 8,
                    child: Row(
                      children: [
                        Text(
                          DurationFormatter.format(position),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 11),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 10),
                              trackHeight: 3,
                            ),
                            child: Slider(
                              value: duration.inMilliseconds > 0
                                  ? (position.inMilliseconds /
                                          duration.inMilliseconds)
                                      .clamp(0.0, 1.0)
                                  : 0.0,
                              activeColor: AppColors.primaryAccent,
                              inactiveColor: Colors.white24,
                              onChanged: (val) {
                                final seekPos = Duration(
                                    milliseconds:
                                        (val * duration.inMilliseconds)
                                            .toInt());
                                _controller.seekTo(seekPos);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          DurationFormatter.format(duration),
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(width: 6),
                        IconButton(
                          icon: Icon(
                            _isFullScreen
                                ? Icons.fullscreen_exit_rounded
                                : Icons.fullscreen_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: _toggleFullScreen,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
