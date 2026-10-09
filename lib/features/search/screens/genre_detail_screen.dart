import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/models/track_model.dart';

class GenreDetailScreen extends ConsumerWidget {
  final String genreName;
  final List<Color> gradientColors;

  const GenreDetailScreen({
    super.key,
    required this.genreName,
    this.gradientColors = const [AppColors.secondaryAccent, AppColors.primaryBackground],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTracks = ref.watch(allTracksProvider);
    final q = genreName.toLowerCase().split(' ').first;
    final genreTracks = allTracks.where((t) => t.genre.toLowerCase().contains(q)).toList();
    final audio = ref.read(audioPlayerServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          // Banner
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.secondaryBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      gradientColors.first.withValues(alpha: 0.8),
                      AppColors.primaryBackground,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'GENRE',
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          genreName,
                          style: AppTypography.displayLarge.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${genreTracks.length} tracks available in this genre',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Play & Shuffle Row
          if (genreTracks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle_rounded, color: AppColors.secondaryText, size: 26),
                      onPressed: () {
                        final shuffled = List<TrackModel>.from(genreTracks)..shuffle();
                        audio.playTrack(shuffled.first, queueContext: shuffled);
                      },
                    ),
                    FloatingActionButton.small(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.black,
                      onPressed: () => audio.playTrack(genreTracks.first, queueContext: genreTracks),
                      child: const Icon(Icons.play_arrow_rounded, size: 28),
                    ),
                  ],
                ),
              ),
            ),

          // Track List
          if (genreTracks.isEmpty)
            SliverFillRemaining(
              child: EmptyStateView(
                icon: Icons.music_off_rounded,
                title: 'No tracks found for $genreName',
                description: 'Import local tracks with this genre to build your collection',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = genreTracks[index];
                  return ListTile(
                    leading: NetworkOrAssetImage(
                      imageUrl: track.artworkUrl,
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    title: Text(
                      track.title,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${track.artistName} • ${DurationFormatter.formatMs(track.durationMs)}',
                      style: AppTypography.bodySmall,
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        ref.watch(trackRepositoryProvider).isFavourite(track.id)
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: ref.watch(trackRepositoryProvider).isFavourite(track.id)
                            ? AppColors.primaryAccent
                            : AppColors.secondaryText,
                        size: 20,
                      ),
                      onPressed: () async {
                        await ref.read(trackRepositoryProvider).toggleFavourite(track.id);
                      },
                    ),
                    onTap: () => audio.playTrack(track, queueContext: genreTracks),
                  );
                },
                childCount: genreTracks.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }
}
