import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/models/track_model.dart';

class LikedSongsScreen extends ConsumerWidget {
  const LikedSongsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favTracks = ref.watch(favouriteTracksProvider);
    final audio = ref.read(audioPlayerServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          // 1. Liked Songs Gradient Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF450AF5),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF450AF5), AppColors.primaryBackground],
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
                        Text(
                          'Liked Songs',
                          style: AppTypography.displayLarge
                              .copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${favTracks.length} tracks • Automatically tracked',
                          style: AppTypography.bodyMedium
                              .copyWith(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // 2. Play & Shuffle Row
          if (favTracks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle_rounded,
                          color: AppColors.secondaryText, size: 28),
                      onPressed: () {
                        final shuffled = List<TrackModel>.from(favTracks)
                          ..shuffle();
                        audio.playTrack(shuffled.first, queueContext: shuffled);
                      },
                    ),
                    FloatingActionButton.small(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.black,
                      onPressed: () => audio.playTrack(favTracks.first,
                          queueContext: favTracks),
                      child: const Icon(Icons.play_arrow_rounded, size: 28),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Track List
          if (favTracks.isEmpty)
            const SliverFillRemaining(
              child: EmptyStateView(
                icon: Icons.favorite_border_rounded,
                title: 'Songs you like will appear here',
                description:
                    'Tap the heart icon on any song or player to save it to your favourites',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = favTracks[index];
                  return ListTile(
                    leading: NetworkOrAssetImage(
                      imageUrl: track.artworkUrl,
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    title: Text(
                      track.title,
                      style: AppTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${track.artistName} • ${DurationFormatter.formatMs(track.durationMs)}',
                      style: AppTypography.bodySmall,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.favorite_rounded,
                          color: AppColors.primaryAccent, size: 22),
                      onPressed: () async {
                        await ref
                            .read(trackRepositoryProvider)
                            .toggleFavourite(track.id);
                      },
                    ),
                    onTap: () =>
                        audio.playTrack(track, queueContext: favTracks),
                  );
                },
                childCount: favTracks.length,
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 90),
          ),
        ],
      ),
    );
  }
}
