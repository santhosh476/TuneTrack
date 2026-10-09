import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/models/track_model.dart';

class ArtistDetailScreen extends ConsumerWidget {
  final String artistName;
  final String? artistImageUrl;

  const ArtistDetailScreen({
    super.key,
    required this.artistName,
    this.artistImageUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTracks = ref.watch(allTracksProvider);
    final artistTracks = allTracks.where((t) => t.artistName.toLowerCase() == artistName.toLowerCase()).toList();
    final audio = ref.read(audioPlayerServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          // Banner with Artist Image / Gradient
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: AppColors.secondaryBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  NetworkOrAssetImage(
                    imageUrl: artistImageUrl ?? (artistTracks.isNotEmpty ? artistTracks.first.artworkUrl : null),
                    fit: BoxFit.cover,
                    placeholderIcon: Icons.person_rounded,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.primaryBackground.withValues(alpha: 0.8),
                          AppColors.primaryBackground,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryAccent.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ARTIST',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          artistName,
                          style: AppTypography.displayLarge.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${artistTracks.length} tracks available',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Play & Shuffle Row
          if (artistTracks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle_rounded, color: AppColors.secondaryText, size: 26),
                      onPressed: () {
                        final shuffled = List<TrackModel>.from(artistTracks)..shuffle();
                        audio.playTrack(shuffled.first, queueContext: shuffled);
                      },
                    ),
                    FloatingActionButton.small(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.black,
                      onPressed: () => audio.playTrack(artistTracks.first, queueContext: artistTracks),
                      child: const Icon(Icons.play_arrow_rounded, size: 28),
                    ),
                  ],
                ),
              ),
            ),

          // Track List
          if (artistTracks.isEmpty)
            SliverFillRemaining(
              child: EmptyStateView(
                icon: Icons.music_off_rounded,
                title: 'No tracks found for $artistName',
                description: 'Import local audio or search Spotify to add tracks for this artist',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = artistTracks[index];
                  return ListTile(
                    leading: Text('${index + 1}', style: AppTypography.labelMedium.copyWith(color: AppColors.secondaryText)),
                    title: Text(
                      track.title,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${track.albumName} • ${DurationFormatter.formatMs(track.durationMs)}',
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
                    onTap: () => audio.playTrack(track, queueContext: artistTracks),
                  );
                },
                childCount: artistTracks.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }
}
