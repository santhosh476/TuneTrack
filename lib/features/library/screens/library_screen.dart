import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/track_model.dart';
import '../../../data/models/playlist_model.dart';
import '../../profile/screens/spotify_connect_screen.dart';
import 'playlist_detail_screen.dart';
import 'liked_songs_screen.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  int _selectedFilterIndex = 0;
  bool _isSyncing = false;

  final List<String> _filters = const [
    'All',
    'Spotify',
    'Local Music',
    'Playlists',
    'Favorites',
    'Recently Played',
  ];

  @override
  Widget build(BuildContext context) {
    final localPlaylists = ref.watch(playlistsProvider);
    final favTracks = ref.watch(favouriteTracksProvider);
    final allLocalTracks = ref.watch(allTracksProvider);
    final spotifyConnected =
        ref.watch(isSpotifyConnectedProvider).value ?? false;
    final spotifyRepo = ref.watch(spotifyRepositoryProvider);
    final audio = ref.read(audioPlayerServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: Text('Your Library',
            style: AppTypography.displayMedium.copyWith(fontSize: 24)),
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF1DB954)),
                ),
              ),
            )
          else
            IconButton(
              icon:
                  const Icon(Icons.sync_rounded, color: AppColors.primaryText),
              tooltip: 'Sync Spotify & Library',
              onPressed: () => _syncLibrary(context),
            ),
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
        onRefresh: () => _syncLibrary(context),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // 1. Connection & Sync Status Banner
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
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: spotifyConnected
                              ? const Color(0xFF1DB954)
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          spotifyConnected
                              ? 'Spotify Connected • Cloud Metadata Active'
                              : 'Offline / Local Mode Active • Connect Spotify for Sync',
                          style: AppTypography.bodySmall.copyWith(
                            color: spotifyConnected
                                ? AppColors.primaryText
                                : AppColors.secondaryText,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (!spotifyConnected)
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SpotifyConnectScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Connect',
                            style: AppTypography.labelSmall.copyWith(
                              color: const Color(0xFF1DB954),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                        selectedColor: _filters[index] == 'Spotify'
                            ? const Color(0xFF1DB954)
                            : AppColors.primaryAccent,
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
              // TAB 0: ALL (Combined Playlists & Quick Links)
              _buildLikedSongsTile(context, favTracks.length),
              _buildSectionHeader('Playlists (${localPlaylists.length})'),
              _buildPlaylistsList(localPlaylists),
              _buildSectionHeader('Device Tracks (${allLocalTracks.length})'),
              _buildTracksList(allLocalTracks, audio, spotifyRepo),
            ] else if (_selectedFilterIndex == 1) ...[
              // TAB 1: SPOTIFY
              if (!spotifyConnected)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color:
                                const Color(0xFF1DB954).withValues(alpha: 0.15),
                          ),
                          child: const Icon(Icons.music_note_rounded,
                              size: 48, color: Color(0xFF1DB954)),
                        ),
                        const SizedBox(height: 16),
                        Text('Connect Spotify Account',
                            style: AppTypography.headlineSmall
                                .copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text(
                          'Sync your Spotify playlists, saved songs, and recently played tracks directly into TuneTrack.',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.secondaryText),
                        ),
                        const SizedBox(height: 24),
                        CustomButton(
                          text: 'Connect with Spotify (PKCE)',
                          icon: Icons.link_rounded,
                          backgroundColor: const Color(0xFF1DB954),
                          textColor: Colors.black,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (context) =>
                                      const SpotifyConnectScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                _buildSpotifyOverview(context, spotifyRepo),
              ],
            ] else if (_selectedFilterIndex == 2) ...[
              // TAB 2: LOCAL MUSIC
              if (allLocalTracks.isEmpty)
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
                _buildTracksList(allLocalTracks, audio, spotifyRepo),
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
                _buildTracksList(favTracks, audio, spotifyRepo),
            ] else if (_selectedFilterIndex == 5) ...[
              // TAB 5: RECENTLY PLAYED
              _buildRecentlyPlayedList(context, audio, spotifyRepo),
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
                colors: [Color(0xFF450AF5), Color(0xFF8E8EE5)],
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
          final isSpotify = p.id.startsWith('spotify_ply_');
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: NetworkOrAssetImage(
                imageUrl: p.coverUrl,
                width: 56,
                height: 56,
                borderRadius: BorderRadius.circular(8),
                placeholderIcon: isSpotify
                    ? Icons.graphic_eq_rounded
                    : Icons.queue_music_rounded,
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      p.title,
                      style: AppTypography.titleMedium
                          .copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSpotify
                          ? const Color(0xFF1DB954).withValues(alpha: 0.2)
                          : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isSpotify ? 'Spotify' : 'Local',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isSpotify
                            ? const Color(0xFF1DB954)
                            : AppColors.secondaryText,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                '${p.trackIds.length} tracks • ${p.description.isNotEmpty ? p.description : "User playlist"}',
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

  Widget _buildTracksList(
      List<TrackModel> tracks, dynamic audio, dynamic spotifyRepo) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = tracks[index];
          final isSpotify = track.sourceType == AudioSourceType.spotifyStream;
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${track.artistName} • ${DurationFormatter.formatMs(track.durationMs)}',
                style: AppTypography.bodySmall,
              ),
              trailing: isSpotify
                  ? IconButton(
                      icon: const Icon(Icons.open_in_new_rounded,
                          color: Color(0xFF1DB954), size: 22),
                      tooltip: 'Open in Spotify',
                      onPressed: () =>
                          spotifyRepo.openInSpotify(track.audioUrl),
                    )
                  : IconButton(
                      icon: const Icon(Icons.play_circle_filled_rounded,
                          color: AppColors.primaryAccent, size: 28),
                      onPressed: () =>
                          audio.playTrack(track, queueContext: tracks),
                    ),
              onTap: () {
                if (isSpotify) {
                  spotifyRepo.openInSpotify(track.audioUrl);
                } else {
                  audio.playTrack(track, queueContext: tracks);
                }
              },
            ),
          );
        },
        childCount: tracks.length,
      ),
    );
  }

  Widget _buildSpotifyOverview(BuildContext context, dynamic spotifyRepo) {
    return SliverToBoxAdapter(
      child: FutureBuilder<Map<String, dynamic>>(
        future: spotifyRepo.syncSpotifyData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF1DB954)),
              ),
            );
          }

          final data = snapshot.data ?? {};
          final playlists = (data['playlists'] as List<PlaylistModel>?) ?? [];
          final savedTracks = (data['savedTracks'] as List<TrackModel>?) ?? [];

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Synced Spotify Playlists (${playlists.length})',
                        style: AppTypography.titleMedium
                            .copyWith(fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () => _syncLibrary(context),
                      icon: const Icon(Icons.refresh_rounded,
                          size: 16, color: Color(0xFF1DB954)),
                      label: Text('Refresh',
                          style: AppTypography.labelMedium
                              .copyWith(color: const Color(0xFF1DB954))),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (playlists.isEmpty)
                  Text('No public playlists found on your Spotify account.',
                      style: AppTypography.bodySmall)
                else
                  ...playlists.map((p) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: NetworkOrAssetImage(
                          imageUrl: p.coverUrl,
                          width: 50,
                          height: 50,
                          borderRadius: BorderRadius.circular(6),
                          placeholderIcon: Icons.music_note_rounded,
                        ),
                        title: Text(p.title,
                            style: AppTypography.titleSmall
                                .copyWith(fontWeight: FontWeight.w600)),
                        subtitle: Text('${p.trackIds.length} tracks',
                            style: AppTypography.bodySmall),
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
                      )),
                const SizedBox(height: 16),
                Text('Saved Spotify Tracks (${savedTracks.length})',
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (savedTracks.isEmpty)
                  Text('No saved tracks found on Spotify.',
                      style: AppTypography.bodySmall)
                else
                  ...savedTracks.take(15).map((t) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: NetworkOrAssetImage(
                          imageUrl: t.artworkUrl,
                          width: 44,
                          height: 44,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        title: Text(t.title,
                            style: AppTypography.titleSmall
                                .copyWith(fontWeight: FontWeight.w600)),
                        subtitle:
                            Text(t.artistName, style: AppTypography.bodySmall),
                        trailing: IconButton(
                          icon: const Icon(Icons.open_in_new_rounded,
                              color: Color(0xFF1DB954), size: 20),
                          onPressed: () =>
                              spotifyRepo.openInSpotify(t.audioUrl),
                        ),
                        onTap: () => spotifyRepo.openInSpotify(t.audioUrl),
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRecentlyPlayedList(
      BuildContext context, dynamic audio, dynamic spotifyRepo) {
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

          final isSpotify = track.sourceType == AudioSourceType.spotifyStream;
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
                icon: Icon(
                  isSpotify
                      ? Icons.open_in_new_rounded
                      : Icons.play_circle_filled_rounded,
                  color: isSpotify
                      ? const Color(0xFF1DB954)
                      : AppColors.primaryAccent,
                  size: 26,
                ),
                onPressed: () {
                  if (isSpotify) {
                    spotifyRepo.openInSpotify(track.audioUrl);
                  } else {
                    audio.playTrack(track);
                  }
                },
              ),
              onTap: () {
                if (isSpotify) {
                  spotifyRepo.openInSpotify(track.audioUrl);
                } else {
                  audio.playTrack(track);
                }
              },
            ),
          );
        },
        childCount: sessions.length,
      ),
    );
  }

  Future<void> _syncLibrary(BuildContext context) async {
    setState(() => _isSyncing = true);
    try {
      final spotifyRepo = ref.read(spotifyRepositoryProvider);
      final res = await spotifyRepo.syncSpotifyData();
      if (context.mounted) {
        if (res['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Synced ${res['playlistsCount']} playlists and ${res['tracksCount']} tracks from Spotify!'),
              backgroundColor: const Color(0xFF1DB954),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(res['message']?.toString() ?? 'Library updated.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
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
