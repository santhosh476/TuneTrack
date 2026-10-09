import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/models/track_model.dart';

class AlbumDetailScreen extends ConsumerWidget {
  final String albumName;
  final String? artistName;
  final String? artworkUrl;

  const AlbumDetailScreen({
    super.key,
    required this.albumName,
    this.artistName,
    this.artworkUrl,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTracks = ref.watch(allTracksProvider);
    final albumTracks = allTracks.where((t) => t.albumName.toLowerCase() == albumName.toLowerCase()).toList();
    final audio = ref.read(audioPlayerServiceProvider);
    final totalDurationMs = albumTracks.fold<int>(0, (sum, t) => sum + t.durationMs);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          // Album Banner
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.secondaryBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondaryAccent.withValues(alpha: 0.6),
                      AppColors.primaryBackground,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      NetworkOrAssetImage(
                        imageUrl: artworkUrl ?? (albumTracks.isNotEmpty ? albumTracks.first.artworkUrl : null),
                        width: 130,
                        height: 130,
                        borderRadius: BorderRadius.circular(12),
                        placeholderIcon: Icons.album_rounded,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        albumName,
                        style: AppTypography.displayMedium.copyWith(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      if (artistName != null || albumTracks.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          artistName ?? albumTracks.first.artistName,
                          style: AppTypography.titleMedium.copyWith(color: AppColors.secondaryText),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${albumTracks.length} tracks • ${DurationFormatter.formatListeningSeconds((totalDurationMs / 1000).round())}',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Play & Shuffle Row
          if (albumTracks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shuffle_rounded, color: AppColors.secondaryText, size: 26),
                      onPressed: () {
                        final shuffled = List<TrackModel>.from(albumTracks)..shuffle();
                        audio.playTrack(shuffled.first, queueContext: shuffled);
                      },
                    ),
                    FloatingActionButton.small(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.black,
                      onPressed: () => audio.playTrack(albumTracks.first, queueContext: albumTracks),
                      child: const Icon(Icons.play_arrow_rounded, size: 28),
                    ),
                  ],
                ),
              ),
            ),

          // Track List
          if (albumTracks.isEmpty)
            SliverFillRemaining(
              child: EmptyStateView(
                icon: Icons.album_outlined,
                title: 'No tracks found in $albumName',
                description: 'Add songs with this album tag to your library to see them here',
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = albumTracks[index];
                  return ListTile(
                    leading: Text('${index + 1}', style: AppTypography.labelMedium.copyWith(color: AppColors.secondaryText)),
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
                    onTap: () => audio.playTrack(track, queueContext: albumTracks),
                  );
                },
                childCount: albumTracks.length,
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),
    );
  }
}
