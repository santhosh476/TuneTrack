import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../core/widgets/empty_state_view.dart';
import 'playlist_detail_screen.dart';
import 'liked_songs_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedFilterIndex = 0;
  final List<String> _filters = [
    'Playlists',
    'Liked Songs',
    'Local Music',
    'Downloaded'
  ];

  @override
  Widget build(BuildContext context) {
    final playlists = ref.watch(playlistsProvider);
    final favTracks = ref.watch(favouriteTracksProvider);
    final allTracks = ref.watch(allTracksProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: Text('Your Library',
            style: AppTypography.displayMedium.copyWith(fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded,
                size: 28, color: AppColors.primaryText),
            tooltip: 'Create Playlist',
            onPressed: () => _showCreatePlaylistDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined,
                color: AppColors.primaryAccent),
            tooltip: 'Import Local Audio',
            onPressed: () => _importLocalFiles(context),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Filter Chips Row
          SliverToBoxAdapter(
            child: SizedBox(
              height: 44,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedFilterIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(
                        _filters[index],
                        style: AppTypography.labelMedium.copyWith(
                          color:
                              isSelected ? Colors.black : AppColors.primaryText,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primaryAccent,
                      backgroundColor: AppColors.surface,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      onSelected: (val) {
                        setState(() {
                          _selectedFilterIndex = index;
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // 2. Liked Songs Card (Always pinned at top if on Playlists or Liked Songs filter)
          if (_selectedFilterIndex == 0 || _selectedFilterIndex == 1)
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF450AF5), Color(0xFF8E8EE5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.favorite_rounded,
                        color: Colors.white, size: 28),
                  ),
                  title: Text(
                    'Liked Songs',
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${favTracks.length} songs • Auto-playlist',
                    style: AppTypography.bodySmall,
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const LikedSongsScreen()),
                    );
                  },
                ),
              ),
            ),

          // 3. Playlists or Filtered View
          if (_selectedFilterIndex == 0) ...[
            if (playlists.isEmpty)
              SliverFillRemaining(
                child: EmptyStateView(
                  icon: Icons.playlist_add_rounded,
                  title: 'No playlists yet',
                  description:
                      'Create your first custom playlist to organise your favourite tracks',
                  actionLabel: 'Create Playlist',
                  onAction: () => _showCreatePlaylistDialog(context),
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = playlists[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: NetworkOrAssetImage(
                          imageUrl: p.coverUrl,
                          width: 56,
                          height: 56,
                          borderRadius: BorderRadius.circular(8),
                          placeholderIcon: Icons.queue_music_rounded,
                        ),
                        title: Text(
                          p.title,
                          style: AppTypography.titleMedium
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          'Playlist • ${p.trackIds.length} songs',
                          style: AppTypography.bodySmall,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            color: AppColors.secondaryText),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  PlaylistDetailScreen(playlistId: p.id),
                            ),
                          );
                        },
                      ),
                    );
                  },
                  childCount: playlists.length,
                ),
              ),
          ] else if (_selectedFilterIndex == 2) ...[
            // Local music filter
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = allTracks[index];
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
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
                      ),
                      subtitle: Text('${track.artistName} • ${track.albumName}',
                          style: AppTypography.bodySmall),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_circle_filled_rounded,
                            color: AppColors.primaryAccent),
                        onPressed: () => ref
                            .read(audioPlayerServiceProvider)
                            .playTrack(track, queueContext: allTracks),
                      ),
                      onTap: () => ref
                          .read(audioPlayerServiceProvider)
                          .playTrack(track, queueContext: allTracks),
                    ),
                  );
                },
                childCount: allTracks.length,
              ),
            ),
          ],

          const SliverToBoxAdapter(
            child: SizedBox(height: 90), // Mini player space
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    final user = ref.read(currentUserProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: Text('New Playlist', style: AppTypography.headlineSmall),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              autofocus: true,
              style: AppTypography.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'Playlist Title',
                hintText: 'e.g. Synthwave Night Drive',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: AppTypography.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What\'s this playlist for?',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.trim().isNotEmpty) {
                await ref.read(playlistRepositoryProvider).createPlaylist(
                      title: titleController.text.trim(),
                      description: descController.text.trim(),
                      userId: user.id,
                    );
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _importLocalFiles(BuildContext context) async {
    final repo = ref.read(trackRepositoryProvider);
    final imported = await repo.pickLocalAudioFiles();
    if (context.mounted) {
      if (imported.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Successfully imported ${imported.length} local audio track(s)!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No audio files were selected.')),
        );
      }
    }
  }
}
