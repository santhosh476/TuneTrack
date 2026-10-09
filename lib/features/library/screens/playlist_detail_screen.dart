import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/models/track_model.dart';

class PlaylistDetailScreen extends ConsumerWidget {
  final String playlistId;

  const PlaylistDetailScreen({super.key, required this.playlistId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlistRepo = ref.watch(playlistRepositoryProvider);
    final playlist = playlistRepo.getPlaylistById(playlistId);
    final audio = ref.read(audioPlayerServiceProvider);

    if (playlist == null) {
      return Scaffold(
        backgroundColor: AppColors.primaryBackground,
        appBar: AppBar(),
        body: const Center(child: Text('Playlist not found')),
      );
    }

    final tracks = playlistRepo.getTracksForPlaylist(playlistId);
    final totalDurationMs = tracks.fold<int>(0, (sum, t) => sum + t.durationMs);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          // 1. Sliver App Bar with Artwork Banner
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.secondaryBackground,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryAccent.withValues(alpha: 0.6),
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
                        imageUrl: playlist.coverUrl,
                        width: 130,
                        height: 130,
                        borderRadius: BorderRadius.circular(12),
                        placeholderIcon: Icons.queue_music_rounded,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        playlist.title,
                        style: AppTypography.displayMedium.copyWith(
                            fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      if (playlist.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          playlist.description,
                          style: AppTypography.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${tracks.length} songs • ${DurationFormatter.formatListeningSeconds((totalDurationMs / 1000).round())}',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () => _showPlaylistActions(context, ref, playlist),
              ),
            ],
          ),

          // 2. Play & Shuffle Action Row
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shuffle_rounded,
                            color: AppColors.secondaryText, size: 24),
                        onPressed: () {
                          if (tracks.isNotEmpty) {
                            final shuffled = List<TrackModel>.from(tracks)
                              ..shuffle();
                            audio.playTrack(shuffled.first,
                                queueContext: shuffled);
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded,
                            color: AppColors.secondaryText, size: 24),
                        onPressed: () => _showAddTrackSelector(context, ref),
                      ),
                    ],
                  ),
                  FloatingActionButton.small(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.black,
                    onPressed: () {
                      if (tracks.isNotEmpty) {
                        audio.playTrack(tracks.first, queueContext: tracks);
                      }
                    },
                    child: const Icon(Icons.play_arrow_rounded, size: 28),
                  ),
                ],
              ),
            ),
          ),

          // 3. Track Listing
          if (tracks.isEmpty)
            SliverFillRemaining(
              child: EmptyStateView(
                icon: Icons.music_off_rounded,
                title: 'No songs in this playlist',
                description:
                    'Add some songs from your library to start listening',
                actionLabel: 'Add Songs',
                onAction: () => _showAddTrackSelector(context, ref),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = tracks[index];
                  return ListTile(
                    leading: Text(
                      '${index + 1}',
                      style: AppTypography.labelMedium
                          .copyWith(color: AppColors.secondaryText),
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
                      icon: const Icon(Icons.remove_circle_outline_rounded,
                          color: AppColors.secondaryText, size: 20),
                      onPressed: () async {
                        await playlistRepo.removeTrackFromPlaylist(
                            playlistId, track.id);
                      },
                    ),
                    onTap: () => audio.playTrack(track, queueContext: tracks),
                  );
                },
                childCount: tracks.length,
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 90),
          ),
        ],
      ),
    );
  }

  void _showPlaylistActions(
      BuildContext context, WidgetRef ref, dynamic playlist) {
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
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error),
              title: Text('Delete Playlist',
                  style: AppTypography.titleMedium
                      .copyWith(color: AppColors.error)),
              onTap: () async {
                Navigator.of(context).pop();
                await ref
                    .read(playlistRepositoryProvider)
                    .deletePlaylist(playlist.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTrackSelector(BuildContext context, WidgetRef ref) {
    final allTracks = ref.read(allTracksProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Add Songs to Playlist',
                  style: AppTypography.titleLarge),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: allTracks.length,
                itemBuilder: (context, index) {
                  final track = allTracks[index];
                  return ListTile(
                    leading: NetworkOrAssetImage(
                      imageUrl: track.artworkUrl,
                      width: 44,
                      height: 44,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    title: Text(track.title, style: AppTypography.titleSmall),
                    subtitle:
                        Text(track.artistName, style: AppTypography.bodySmall),
                    trailing: const Icon(Icons.add_rounded,
                        color: AppColors.primaryAccent),
                    onTap: () async {
                      await ref
                          .read(playlistRepositoryProvider)
                          .addTrackToPlaylist(playlistId, track.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Added "${track.title}"')),
                        );
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
