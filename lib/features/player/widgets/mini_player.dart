import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../data/models/track_model.dart';
import '../screens/full_player_screen.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackAsync = ref.watch(currentTrackStreamProvider);
    final isPlayingAsync = ref.watch(isPlayingStreamProvider);
    final positionAsync = ref.watch(playbackPositionStreamProvider);
    final durationAsync = ref.watch(playbackDurationStreamProvider);

    final track =
        trackAsync.value ?? ref.watch(audioPlayerServiceProvider).currentTrack;
    if (track == null) return const SizedBox.shrink();

    final isPlaying =
        isPlayingAsync.value ?? ref.watch(audioPlayerServiceProvider).isPlaying;
    final position = positionAsync.value ?? Duration.zero;
    final duration = durationAsync.value ?? track.duration;

    final progress = (duration.inMilliseconds > 0)
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    final isBufferingAsync = ref.watch(isBufferingStreamProvider);
    final isBuffering =
        isBufferingAsync.value ?? ref.watch(audioPlayerServiceProvider).isBuffering;

    final isFav = ref.watch(trackRepositoryProvider).isFavourite(track.id);

    final isYouTube = track.sourceType == AudioSourceType.youtubeVideo;
    final isSpotify = track.sourceType == AudioSourceType.spotifyStream;
    final isStream = track.sourceType == AudioSourceType.networkStream;

    Color badgeColor = const Color(0xFF00B4D8);
    String badgeLabel = 'Local';
    IconData badgeIcon = Icons.folder_rounded;

    if (isYouTube) {
      badgeColor = Colors.redAccent;
      badgeLabel = 'YouTube';
      badgeIcon = Icons.smart_display_rounded;
    } else if (isSpotify) {
      badgeColor = const Color(0xFF1DB954);
      badgeLabel = 'Spotify';
      badgeIcon = Icons.graphic_eq_rounded;
    } else if (isStream) {
      badgeColor = const Color(0xFF8E2DE2);
      badgeLabel = 'Stream';
      badgeIcon = Icons.cloud_queue_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.miniPlayerOverlay,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.3),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (context) => const FullPlayerScreen(),
              ),
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Row(
                  children: [
                    // Artwork with Source Icon overlay
                    Stack(
                      children: [
                        NetworkOrAssetImage(
                          imageUrl: track.artworkUrl,
                          width: 44,
                          height: 44,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.85),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(4),
                                bottomRight: Radius.circular(6),
                              ),
                            ),
                            child: Icon(badgeIcon, size: 10, color: badgeColor),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    // Track Title, Artist, & Source Badge
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            track.title,
                            style: AppTypography.titleSmall.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: badgeColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  badgeLabel,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  track.artistName,
                                  style: AppTypography.bodySmall.copyWith(
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
                    // Favourite Button
                    IconButton(
                      icon: Icon(
                        isFav
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: isFav
                            ? AppColors.primaryAccent
                            : AppColors.secondaryText,
                        size: 22,
                      ),
                      onPressed: () async {
                        await ref
                            .read(trackRepositoryProvider)
                            .toggleFavourite(track.id);
                      },
                    ),
                    // Play / Pause / Buffering Button
                    IconButton(
                      icon: isBuffering
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: AppColors.primaryAccent,
                              ),
                            )
                          : Icon(
                              isPlaying
                                  ? Icons.pause_circle_filled_rounded
                                  : Icons.play_circle_filled_rounded,
                              color: AppColors.primaryText,
                              size: 36,
                            ),
                      onPressed: () {
                        ref.read(audioPlayerServiceProvider).togglePlayPause();
                      },
                    ),
                  ],
                ),
              ),
              // Progress indicator bar at the bottom of mini player
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 2.5,
                  backgroundColor: AppColors.surface,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.primaryAccent),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
