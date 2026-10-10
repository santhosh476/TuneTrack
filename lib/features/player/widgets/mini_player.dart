import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/network_or_asset_image.dart';
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

    final isFav = ref.watch(trackRepositoryProvider).isFavourite(track.id);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.miniPlayerOverlay,
        borderRadius: BorderRadius.circular(10),
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
                    // Artwork
                    NetworkOrAssetImage(
                      imageUrl: track.artworkUrl,
                      width: 44,
                      height: 44,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    const SizedBox(width: 12),
                    // Track Title & Artist
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
                          Text(
                            track.artistName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.secondaryText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                    // Play / Pause Button
                    IconButton(
                      icon: Icon(
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
