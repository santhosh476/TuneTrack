import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../services/audio/audio_player_service.dart';
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

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.surfaceElevated.withValues(alpha: 0.8),
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

                // 2. Large Album Artwork
                const Spacer(),
                Container(
                  width: MediaQuery.of(context).size.width * 0.78,
                  height: MediaQuery.of(context).size.width * 0.78,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 30,
                        offset: const Offset(0, 16),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: NetworkOrAssetImage(
                      imageUrl: track.artworkUrl,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.album_rounded,
                    ),
                  ),
                ),
                const Spacer(),

                // 3. Track Info & Favourite Button
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
                const SizedBox(height: 16),

                // 4. Seek Bar & Times
                Column(
                  children: [
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primaryAccent,
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
                const SizedBox(height: 12),

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
                      decoration: const BoxDecoration(
                        color: AppColors.primaryAccent,
                        shape: BoxShape.circle,
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
                const SizedBox(height: 16),

                // 6. Bottom Auxiliary Controls (Speed, Sleep Timer, Queue)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showSpeedSelector(context, audio),
                      icon: const Icon(Icons.speed_rounded,
                          size: 18, color: AppColors.secondaryText),
                      label: Text('1.0x',
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.secondaryText)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.timer_outlined,
                          color: AppColors.secondaryText, size: 22),
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
