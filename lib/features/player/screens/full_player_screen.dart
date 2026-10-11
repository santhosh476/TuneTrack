import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../data/models/track_model.dart';
import '../../../services/audio/audio_player_service.dart';
import 'online_video_player_screen.dart';
import 'youtube_music_player_screen.dart';
import 'queue_screen.dart';
import 'sleep_timer_dialog.dart';

class FullPlayerScreen extends ConsumerStatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  ConsumerState<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends ConsumerState<FullPlayerScreen> {
  double? _dragPositionSeconds;

  @override
  Widget build(BuildContext context) {
    final audio = ref.watch(audioPlayerServiceProvider);
    final trackAsync = ref.watch(currentTrackStreamProvider);
    final isPlayingAsync = ref.watch(isPlayingStreamProvider);
    final positionAsync = ref.watch(playbackPositionStreamProvider);
    final durationAsync = ref.watch(playbackDurationStreamProvider);
    final isShuffleAsync = ref.watch(shuffleStreamProvider);
    final repeatModeAsync = ref.watch(repeatStreamProvider);

    final track = trackAsync.value ?? audio.currentTrack;
    if (track == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: AppBar(),
        body: const Center(child: Text('No track playing')),
      );
    }

    final isPlaying = isPlayingAsync.value ?? audio.isPlaying;
    final position = positionAsync.value ?? audio.currentPosition;
    final duration = durationAsync.value ?? audio.duration ?? track.duration;
    final isShuffle = isShuffleAsync.value ?? audio.isShuffle;
    final repeatMode = repeatModeAsync.value ?? audio.repeatMode;

    final totalSeconds =
        duration.inSeconds > 0 ? duration.inSeconds.toDouble() : 1.0;
    final currentSeconds = _dragPositionSeconds ??
        position.inSeconds.toDouble().clamp(0.0, totalSeconds);

    final isFav = ref.watch(trackRepositoryProvider).isFavourite(track.id);

    final isBufferingAsync = ref.watch(isBufferingStreamProvider);
    final isBuffering = isBufferingAsync.value ?? audio.isBuffering;

    final volumeAsync = ref.watch(volumeStreamProvider);
    final currentVolume = volumeAsync.value ?? audio.volume;

    final isYouTube = track.sourceType == AudioSourceType.youtubeVideo;
    final isOnlineVideo = track.sourceType == AudioSourceType.onlineVideo;
    final isSpotify = track.sourceType == AudioSourceType.spotifyStream;
    final isStream = track.sourceType == AudioSourceType.networkStream;

    Color badgeColor = const Color(0xFF00B4D8);
    String badgeLabel = 'Local Audio File';
    IconData badgeIcon = Icons.folder_rounded;

    if (isYouTube) {
      badgeColor = Colors.redAccent;
      badgeLabel = 'YouTube Music Video';
      badgeIcon = Icons.smart_display_rounded;
    } else if (isOnlineVideo) {
      badgeColor = const Color(0xFFC471ED);
      badgeLabel = 'Online HD Video';
      badgeIcon = Icons.ondemand_video_rounded;
    } else if (isSpotify) {
      badgeColor = const Color(0xFF1DB954);
      badgeLabel = 'Spotify Track';
      badgeIcon = Icons.graphic_eq_rounded;
    } else if (isStream) {
      badgeColor = const Color(0xFF8E2DE2);
      badgeLabel = 'Online Audio Stream';
      badgeIcon = Icons.cloud_queue_rounded;
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              badgeColor.withValues(alpha: 0.15),
              AppColors.primaryBackground,
              AppColors.primaryBackground,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // 1. Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.keyboard_arrow_down_rounded,
                          size: 32, color: AppColors.primaryText),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Column(
                      children: [
                        Text(
                          'PLAYING FROM',
                          style: AppTypography.labelSmall.copyWith(
                            letterSpacing: 1.2,
                            color: AppColors.secondaryText,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.albumName.isNotEmpty
                              ? track.albumName
                              : 'TuneTrack Library',
                          style: AppTypography.titleSmall
                              .copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert_rounded,
                          color: AppColors.primaryText),
                      onPressed: () => _showTrackOptions(context, track),
                    ),
                  ],
                ),

                // 2. Large Album Artwork with Buffering Overlay
                const Spacer(),
                Container(
                  width: MediaQuery.of(context).size.width * 0.74,
                  height: MediaQuery.of(context).size.width * 0.74,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 14),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: NetworkOrAssetImage(
                            imageUrl: track.artworkUrl,
                            fit: BoxFit.cover,
                            placeholderIcon: Icons.album_rounded,
                          ),
                        ),
                      ),
                      if (isBuffering)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Center(
                              child: SizedBox(
                                width: 42,
                                height: 42,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.5,
                                  color: AppColors.primaryAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const Spacer(),

                // 3. Track Info, Favourite Button & Source Pill
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title,
                                style: AppTypography.displaySmall
                                    .copyWith(fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                track.artistName,
                                style: AppTypography.titleMedium
                                    .copyWith(color: AppColors.secondaryText),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            isFav
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            color: isFav
                                ? AppColors.primaryAccent
                                : AppColors.secondaryText,
                            size: 28,
                          ),
                          onPressed: () async {
                            await ref
                                .read(trackRepositoryProvider)
                                .toggleFavourite(track.id);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Dedicated Source Action Banner
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: badgeColor.withValues(alpha: 0.3), width: 0.8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(badgeIcon, size: 16, color: badgeColor),
                              const SizedBox(width: 6),
                              Text(
                                badgeLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: badgeColor,
                                ),
                              ),
                            ],
                          ),
                          if (isYouTube)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                              ),
                              icon: const Icon(Icons.smart_display_rounded,
                                  size: 16, color: Colors.redAccent),
                              label: const Text('Watch Video',
                                  style: TextStyle(
                                      color: Colors.redAccent, fontSize: 11)),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        YoutubeMusicPlayerScreen(
                                      title: track.title,
                                      artist: track.artistName,
                                      videoId: track.youtubeVideoId,
                                      videoUrl: track.sourceDetailUrl,
                                      durationMs: track.durationMs,
                                      artworkUrl: track.artworkUrl,
                                      track: track,
                                    ),
                                  ),
                                );
                              },
                            )
                          else if (isOnlineVideo)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                              ),
                              icon: const Icon(Icons.ondemand_video_rounded,
                                  size: 16, color: Color(0xFFC471ED)),
                              label: const Text('Watch Video',
                                  style: TextStyle(
                                      color: Color(0xFFC471ED), fontSize: 11)),
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        OnlineVideoPlayerScreen(track: track),
                                  ),
                                );
                              },
                            )
                          else if (isSpotify)
                            TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                              ),
                              icon: const Icon(Icons.open_in_new_rounded,
                                  size: 15, color: Color(0xFF1DB954)),
                              label: const Text('Open Spotify',
                                  style: TextStyle(
                                      color: Color(0xFF1DB954), fontSize: 11)),
                              onPressed: () {
                                final repo = ref.read(spotifyRepositoryProvider);
                                repo.openInSpotify(track.audioSourceUrl);
                              },
                            )
                          else
                            const Text(
                              'Authorized Audio',
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.secondaryText),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Seek Bar & Times
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: badgeColor,
                        inactiveTrackColor: AppColors.surfaceLight,
                        thumbColor: Colors.white,
                        trackHeight: 4,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 14),
                      ),
                      child: Slider(
                        value: currentSeconds.clamp(0.0, totalSeconds),
                        min: 0.0,
                        max: totalSeconds,
                        onChanged: (val) {
                          setState(() {
                            _dragPositionSeconds = val;
                          });
                        },
                        onChangeEnd: (val) {
                          audio.seek(Duration(seconds: val.toInt()));
                          setState(() {
                            _dragPositionSeconds = null;
                          });
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            DurationFormatter.format(
                                Duration(seconds: currentSeconds.toInt())),
                            style: AppTypography.bodySmall,
                          ),
                          Text(
                            DurationFormatter.format(duration),
                            style: AppTypography.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 5. Main Controls (Shuffle, Previous, Play/Pause, Next, Repeat)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.shuffle_rounded,
                        color: isShuffle
                            ? AppColors.primaryAccent
                            : AppColors.secondaryText,
                        size: 24,
                      ),
                      onPressed: () => audio.toggleShuffle(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_previous_rounded,
                          size: 36, color: AppColors.primaryText),
                      onPressed: () => audio.previous(),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: badgeColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: badgeColor.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        iconSize: 42,
                        padding: const EdgeInsets.all(12),
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.black,
                        ),
                        onPressed: () => audio.togglePlayPause(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.skip_next_rounded,
                          size: 36, color: AppColors.primaryText),
                      onPressed: () => audio.next(),
                    ),
                    IconButton(
                      icon: Icon(
                        repeatMode == AudioRepeatMode.one
                            ? Icons.repeat_one_rounded
                            : repeatMode == AudioRepeatMode.all
                                ? Icons.repeat_on_rounded
                                : Icons.repeat_rounded,
                        color: repeatMode != AudioRepeatMode.off
                            ? AppColors.primaryAccent
                            : AppColors.secondaryText,
                        size: 24,
                      ),
                      onPressed: () => audio.cycleRepeatMode(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 6. Interactive Volume Slider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: Icon(
                          currentVolume == 0.0
                              ? Icons.volume_off_rounded
                              : (currentVolume < 0.5
                                  ? Icons.volume_down_rounded
                                  : Icons.volume_up_rounded),
                          size: 20,
                          color: AppColors.secondaryText,
                        ),
                        onPressed: () {
                          audio.setVolume(currentVolume > 0 ? 0.0 : 1.0);
                        },
                      ),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 2.5,
                            thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 4),
                            activeTrackColor: AppColors.secondaryText,
                            inactiveTrackColor: AppColors.surfaceLight,
                            thumbColor: AppColors.primaryText,
                          ),
                          child: Slider(
                            value: currentVolume.clamp(0.0, 1.0),
                            min: 0.0,
                            max: 1.0,
                            onChanged: (val) => audio.setVolume(val),
                          ),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                        ),
                        onPressed: () => _showSpeedSelector(context, audio),
                        icon: const Icon(Icons.speed_rounded,
                            size: 16, color: AppColors.secondaryText),
                        label: Text('1.0x',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.secondaryText)),
                      ),
                    ],
                  ),
                ),

                // 7. Auxiliary Actions (Sleep Timer, Queue, Retry)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded,
                          color: AppColors.secondaryText, size: 20),
                      tooltip: 'Retry Stream',
                      onPressed: () => audio.retryCurrentTrack(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.timer_outlined,
                          color: AppColors.secondaryText, size: 22),
                      tooltip: 'Sleep Timer',
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => const SleepTimerDialog(),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.queue_music_rounded,
                          color: AppColors.secondaryText, size: 24),
                      tooltip: 'Playback Queue',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => const QueueScreen()),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTrackOptions(BuildContext context, dynamic track) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add_rounded,
                  color: AppColors.primaryText),
              title: Text('Add to Playlist', style: AppTypography.titleMedium),
              onTap: () {
                Navigator.of(context).pop();
                _showAddToPlaylistDialog(context, track.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded,
                  color: AppColors.primaryText),
              title: Text('Track Details', style: AppTypography.titleMedium),
              subtitle: Text(
                  '${track.artistName} • ${track.albumName} • ${track.genre}',
                  style: AppTypography.bodySmall),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, String trackId) {
    final playlists = ref.read(playlistsProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: Text('Add to Playlist', style: AppTypography.headlineSmall),
        content: SizedBox(
          width: double.maxFinite,
          child: playlists.isEmpty
              ? Text('No playlists created yet.',
                  style: AppTypography.bodyMedium)
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: playlists.length,
                  itemBuilder: (context, index) {
                    final p = playlists[index];
                    return ListTile(
                      title: Text(p.title, style: AppTypography.bodyLarge),
                      subtitle: Text('${p.trackIds.length} tracks',
                          style: AppTypography.bodySmall),
                      onTap: () async {
                        await ref
                            .read(playlistRepositoryProvider)
                            .addTrackToPlaylist(p.id, trackId);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added to "${p.title}"')),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showSpeedSelector(BuildContext context, AudioPlayerService audio) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((speed) {
            return ListTile(
              title: Text('${speed}x', style: AppTypography.bodyLarge),
              onTap: () {
                audio.setPlaybackSpeed(speed);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        ),
      ),
    );
  }
}
