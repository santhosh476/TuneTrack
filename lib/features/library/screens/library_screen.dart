import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/models/track_model.dart';
import '../../../data/models/playlist_model.dart';
import 'playlist_detail_screen.dart';
import 'liked_songs_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedFilterIndex = 0;
  bool _isRefreshing = false;

  final List<String> _filters = const [
    'All',
    'Online Music',
    'Local Music',
    'Playlists',
    'Favorites',
    'Recently Played',
  ];

  @override
  Widget build(BuildContext context) {
    final localPlaylists = ref.watch(playlistsProvider);
    final favTracks = ref.watch(favouriteTracksProvider);
    final allTracks = ref.watch(allTracksProvider);
    final audio = ref.read(audioPlayerServiceProvider);

    final localTracks = allTracks
        .where((t) =>
            t.sourceType == AudioSourceType.localFile ||
            t.sourceType == AudioSourceType.demoAsset)
        .toList();

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
      body: RefreshIndicator(
        color: AppColors.primaryAccent,
        backgroundColor: AppColors.surfaceElevated,
        onRefresh: () => _refreshOnlineCatalogue(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Connectivity Status Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryAccent,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Open Public Music Engine Active • Zero Auth / Offline Capable',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.primaryText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (_isRefreshing)
                        const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppColors.primaryAccent),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Filter Chips Row (6 Tabs)
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
                            color: isSelected
                                ? Colors.black
                                : AppColors.primaryText,
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

            const SliverToBoxAdapter(child: SizedBox(height: 8)),

            // 3. Render content according to selected filter
            if (_selectedFilterIndex == 0) ...[
              // TAB 0: ALL
              _buildLikedSongsTile(context, favTracks.length),
              _buildSectionHeader('Playlists (${localPlaylists.length})'),
              _buildPlaylistsList(localPlaylists),
              _buildSectionHeader('All Tracks (${allTracks.length})'),
              _buildTracksList(allTracks, audio),
            ] else if (_selectedFilterIndex == 1) ...[
              // TAB 1: ONLINE MUSIC (Public Catalogue)
              _buildOnlineMusicOverview(context, audio),
            ] else if (_selectedFilterIndex == 2) ...[
              // TAB 2: LOCAL MUSIC
              if (localTracks.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    icon: Icons.folder_open_rounded,
                    title: 'No Local Audio Files',
                    description:
                        'Import MP3, WAV, FLAC, or AAC files from your device storage.',
                    actionLabel: 'Import Audio Files',
                    onAction: () => _importLocalFiles(context),
                  ),
                )
              else
                _buildTracksList(localTracks, audio),
            ] else if (_selectedFilterIndex == 3) ...[
              // TAB 3: PLAYLISTS
              if (localPlaylists.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    icon: Icons.playlist_add_rounded,
                    title: 'No playlists yet',
                    description:
                        'Create your first custom playlist to organise your favourite tracks.',
                    actionLabel: 'Create Playlist',
                    onAction: () => _showCreatePlaylistDialog(context),
                  ),
                )
              else
                _buildPlaylistsList(localPlaylists),
            ] else if (_selectedFilterIndex == 4) ...[
              // TAB 4: FAVORITES
              _buildLikedSongsTile(context, favTracks.length),
              if (favTracks.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyStateView(
                    icon: Icons.favorite_border_rounded,
                    title: 'No Liked Songs Yet',
                    description:
                        'Tap the heart icon on any track to add it to your favourites.',
                  ),
                )
              else
                _buildTracksList(favTracks, audio),
            ] else if (_selectedFilterIndex == 5) ...[
              // TAB 5: RECENTLY PLAYED
              _buildRecentlyPlayedList(context, audio),
            ],

            const SliverToBoxAdapter(
              child: SizedBox(height: 90), // Mini player space
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.secondaryText,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLikedSongsTile(BuildContext context, int count) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.favorite_rounded,
                color: Colors.white, size: 28),
          ),
          title: Text('Liked Songs',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text('$count songs • Auto-playlist',
              style: AppTypography.bodySmall),
          trailing: const Icon(Icons.chevron_right_rounded,
              color: AppColors.secondaryText),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const LikedSongsScreen()),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlaylistsList(List<PlaylistModel> playlists) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final p = playlists[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                '${p.trackIds.length} tracks • ${p.description.isNotEmpty ? p.description : "Playlist"}',
                style: AppTypography.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    );
  }

  Widget _buildTracksList(List<TrackModel> tracks, dynamic audio) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = tracks[index];
          final isOnline = track.sourceType == AudioSourceType.networkStream;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: NetworkOrAssetImage(
                imageUrl: track.artworkUrl,
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(6),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      track.title,
                      style: AppTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? const Color(0xFF8E2DE2).withValues(alpha: 0.2)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isOnline ? 'Online' : 'Local',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isOnline
                            ? const Color(0xFF8E2DE2)
                            : AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                '${track.artistName} • ${DurationFormatter.formatMs(track.durationMs)}',
                style: AppTypography.bodySmall,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.play_circle_filled_rounded,
                    color: AppColors.primaryAccent, size: 28),
                onPressed: () => audio.playTrack(track, queueContext: tracks),
              ),
              onTap: () => audio.playTrack(track, queueContext: tracks),
            ),
          );
        },
        childCount: tracks.length,
      ),
    );
  }

  Widget _buildOnlineMusicOverview(BuildContext context, dynamic audio) {
    final onlineRepo = ref.watch(onlineMusicRepositoryProvider);
    return SliverToBoxAdapter(
      child: FutureBuilder<List<TrackModel>>(
        future: onlineRepo.getFeaturedOnlineTracks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child:
                    CircularProgressIndicator(color: AppColors.primaryAccent),
              ),
            );
          }

          final tracks = snapshot.data ?? [];
          if (tracks.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                  child:
                      Text('No online tracks loaded. Tap Refresh or Search.')),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Featured Public Catalogue (${tracks.length})',
                        style: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () => _refreshOnlineCatalogue(),
                      icon: const Icon(Icons.refresh_rounded,
                          size: 16, color: AppColors.primaryAccent),
                      label: Text('Refresh',
                          style: AppTypography.labelMedium
                              .copyWith(color: AppColors.primaryAccent)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...tracks.map((t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: NetworkOrAssetImage(
                        imageUrl: t.artworkUrl,
                        width: 48,
                        height: 48,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      title: Text(t.title,
                          style: AppTypography.titleSmall
                              .copyWith(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text('${t.artistName} • ${t.genre}',
                          style: AppTypography.bodySmall),
                      trailing: IconButton(
                        icon: const Icon(Icons.play_circle_filled_rounded,
                            color: AppColors.primaryAccent, size: 26),
                        onPressed: () =>
                            audio.playTrack(t, queueContext: tracks),
                      ),
                      onTap: () => audio.playTrack(t, queueContext: tracks),
                    )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentlyPlayedList(BuildContext context, dynamic audio) {
    final sessionRepo = ref.watch(sessionRepositoryProvider);
    final user = ref.watch(currentUserProvider);
    final sessions = sessionRepo.getAllSessions(userId: user.id);

    if (sessions.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: EmptyStateView(
          icon: Icons.history_rounded,
          title: 'No Listening History Yet',
          description:
              'Play some music and your recently played tracks will appear here.',
        ),
      );
    }

    final trackRepo = ref.watch(trackRepositoryProvider);
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final s = sessions[index];
          final track = trackRepo.getTrackById(s.trackId);
          if (track == null) return const SizedBox.shrink();

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
              subtitle: Text(
                '${track.artistName} • Played ${s.playedAt.hour.toString().padLeft(2, '0')}:${s.playedAt.minute.toString().padLeft(2, '0')}',
                style: AppTypography.bodySmall,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.play_circle_filled_rounded,
                    color: AppColors.primaryAccent, size: 26),
                onPressed: () => audio.playTrack(track),
              ),
              onTap: () => audio.playTrack(track),
            ),
          );
        },
        childCount: sessions.length,
      ),
    );
  }

  Future<void> _refreshOnlineCatalogue() async {
    setState(() => _isRefreshing = true);
    try {
      final onlineRepo = ref.read(onlineMusicRepositoryProvider);
      final tracks = await onlineRepo.getFeaturedOnlineTracks();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Updated online catalogue with ${tracks.length} tracks!')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
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
