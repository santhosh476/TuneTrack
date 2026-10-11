import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../data/models/track_model.dart';

/// Full-featured in-app YouTube Music Video Player
/// Plays full-length videos, controls playback, respects orientation,
/// and handles unavailable/restricted videos gracefully.
class YoutubeMusicPlayerScreen extends ConsumerStatefulWidget {
  final String title;
  final String artist;
  final String? videoId;
  final String? videoUrl;
  final int? durationMs;
  final String? artworkUrl;
  final TrackModel? track;

  const YoutubeMusicPlayerScreen({
    super.key,
    required this.title,
    this.artist = 'YouTube Music',
    this.videoId,
    this.videoUrl,
    this.durationMs,
    this.artworkUrl,
    this.track,
  });

  @override
  ConsumerState<YoutubeMusicPlayerScreen> createState() =>
      _YoutubeMusicPlayerScreenState();
}

class _YoutubeMusicPlayerScreenState
    extends ConsumerState<YoutubeMusicPlayerScreen> {
  late YoutubePlayerController _controller;
  late TextEditingController _idController;
  late TextEditingController _seekToController;

  bool _isPlayerReady = false;
  String _resolvedVideoId = '';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _resolveVideoId();
    _initPlayer();
  }

  void _resolveVideoId() {
    if (widget.videoId != null && widget.videoId!.isNotEmpty) {
      _resolvedVideoId = widget.videoId!;
    } else if (widget.track != null && widget.track!.youtubeVideoId != null) {
      _resolvedVideoId = widget.track!.youtubeVideoId!;
    } else if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      _resolvedVideoId =
          YoutubePlayer.convertUrlToId(widget.videoUrl!) ?? widget.videoUrl!;
    } else {
      _resolvedVideoId = '';
    }
  }

  void _initPlayer() {
    // Pause any active background audio from the local player
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioPlayerServiceProvider).pause();
    });

    if (_resolvedVideoId.isEmpty) {
      _hasError = true;
      _errorMessage = 'Video ID not found. You can watch directly on YouTube.';
      return;
    }

    try {
      _controller = YoutubePlayerController(
        initialVideoId: _resolvedVideoId,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          enableCaption: false,
          isLive: false,
          forceHD: false,
          loop: false,
          showLiveFullscreenButton: true,
        ),
      )..addListener(_listener);
      _idController = TextEditingController();
      _seekToController = TextEditingController();
    } catch (e) {
      _hasError = true;
      _errorMessage = 'Could not initialize YouTube player: $e';
    }
  }

  void _listener() {
    if (_isPlayerReady && mounted && !_controller.value.isFullScreen) {
      setState(() {});
    }
    if (_controller.value.hasError) {
      setState(() {
        _hasError = true;
        _errorMessage =
            'This video is unavailable for in-app embedding (may be region-restricted or copyright protected).';
      });
    }
  }

  @override
  void deactivate() {
    // Pauses video while navigating to next page.
    if (!_hasError && _resolvedVideoId.isNotEmpty) {
      _controller.pause();
    }
    super.deactivate();
  }

  @override
  void dispose() {
    if (!_hasError && _resolvedVideoId.isNotEmpty) {
      _controller.dispose();
      _idController.dispose();
      _seekToController.dispose();
    }
    super.dispose();
  }

  Future<void> _launchExternalYouTube() async {
    final searchParam =
        Uri.encodeComponent('${widget.title} ${widget.artist} official');
    final url = _resolvedVideoId.isNotEmpty
        ? Uri.parse('https://www.youtube.com/watch?v=$_resolvedVideoId')
        : Uri.parse(
            'https://www.youtube.com/results?search_query=$searchParam');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external YouTube app.')),
        );
      }
    }
  }

  void _toggleFavorite() {
    if (widget.track != null) {
      final repo = ref.read(trackRepositoryProvider);
      repo.toggleFavourite(widget.track!.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.track!.isFavourite
                ? 'Removed from Favorites'
                : 'Added to Favorites ❤️',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError || _resolvedVideoId.isEmpty) {
      return _buildErrorOrFallbackScaffold();
    }

    return YoutubePlayerBuilder(
      onExitFullScreen: () {
        SystemChrome.setPreferredOrientations(DeviceOrientation.values);
      },
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Colors.redAccent,
        progressColors: const ProgressBarColors(
          playedColor: Colors.red,
          handleColor: Colors.redAccent,
          bufferedColor: Colors.white24,
          backgroundColor: Colors.grey,
        ),
        topActions: <Widget>[
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              _controller.metadata.title.isNotEmpty
                  ? _controller.metadata.title
                  : widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                overflow: TextOverflow.ellipsis,
              ),
              maxLines: 1,
            ),
          ),
          IconButton(
            icon:
                const Icon(Icons.open_in_new, color: Colors.white, size: 20.0),
            onPressed: _launchExternalYouTube,
            tooltip: 'Open in YouTube App',
          ),
        ],
        onReady: () {
          _isPlayerReady = true;
        },
        onEnded: (data) {
          // Playback finished completely
        },
      ),
      builder: (context, player) {
        final currentPosition = _controller.value.position;
        final totalDuration = _controller.metadata.duration.inMilliseconds > 0
            ? _controller.metadata.duration
            : Duration(milliseconds: widget.durationMs ?? 240000);

        return Scaffold(
          backgroundColor: AppColors.primaryBackground,
          appBar: AppBar(
            backgroundColor: AppColors.primaryBackground,
            elevation: 0,
            title: Text(
              'YouTube Player',
              style: AppTypography.displayMedium.copyWith(fontSize: 18),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.open_in_new_rounded,
                    color: AppColors.primaryText),
                tooltip: 'Watch on YouTube App',
                onPressed: _launchExternalYouTube,
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            children: [
              // 1. Embedded YouTube Player
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  color: Colors.black,
                  child: player,
                ),
              ),
              const SizedBox(height: 16),

              // 2. Video Title & Channel Info
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _controller.metadata.title.isNotEmpty
                              ? _controller.metadata.title
                              : widget.title,
                          style: AppTypography.titleLarge.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.verified_rounded,
                                color: Colors.redAccent, size: 14),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                _controller.metadata.author.isNotEmpty
                                    ? _controller.metadata.author
                                    : widget.artist,
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.secondaryText,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.track != null)
                    IconButton(
                      icon: Icon(
                        widget.track!.isFavourite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: widget.track!.isFavourite
                            ? Colors.red
                            : AppColors.secondaryText,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. Playback Status Badge & Duration Indicator
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _controller.value.isPlaying
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                          color: AppColors.primaryAccent,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _controller.value.isPlaying
                              ? 'Playing Full Video'
                              : 'Paused',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${DurationFormatter.format(currentPosition)} / ${DurationFormatter.format(totalDuration)}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. Player Controls Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10_rounded,
                        color: AppColors.primaryText, size: 28),
                    onPressed: () {
                      final current = _controller.value.position;
                      _controller.seekTo(current - const Duration(seconds: 10));
                    },
                    tooltip: 'Rewind 10s',
                  ),
                  FloatingActionButton.small(
                    heroTag: 'yt_play_pause',
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                    onPressed: () {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                      }
                      setState(() {});
                    },
                    child: Icon(
                      _controller.value.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 24,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.forward_10_rounded,
                        color: AppColors.primaryText, size: 28),
                    onPressed: () {
                      final current = _controller.value.position;
                      _controller.seekTo(current + const Duration(seconds: 10));
                    },
                    tooltip: 'Forward 10s',
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Features & Fallback Banner
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade900.withValues(alpha: 0.25),
                      AppColors.surface,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Full Length Official Playback',
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'This video streams in full length directly via the YouTube embedded player. No 30-second preview limit.',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _launchExternalYouTube,
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Open in YouTube App'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.redAccent),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildErrorOrFallbackScaffold() {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: Text(
          'YouTube Video',
          style: AppTypography.displayMedium.copyWith(fontSize: 18),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_display_rounded,
                  color: Colors.red,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: AppTypography.titleLarge
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                widget.artist,
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 16),
              Text(
                _errorMessage.isNotEmpty
                    ? _errorMessage
                    : 'This video cannot be embedded inside the app due to YouTube copyright/privacy settings. You can watch it directly on YouTube.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.secondaryText),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _launchExternalYouTube,
                icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                label: const Text(
                  'Watch on YouTube',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
