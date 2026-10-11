import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../data/models/track_model.dart';
import '../../../data/models/playlist_model.dart';
import '../../../services/youtube/youtube_api_service.dart';
import '../../player/screens/online_video_player_screen.dart';
import '../../player/screens/youtube_music_player_screen.dart';
import 'genre_detail_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String _query = '';
  int _searchSourceIndex = 0; // 0: All, 1: YouTube, 2: Spotify, 3: Online Streams, 4: Local

  List<TrackModel> _localResults = [];
  List<TrackModel> _youtubeResults = [];
  String? _youtubeNextPageToken;
  bool _isLoadingMoreYouTube = false;

  List<TrackModel> _onlineResults = [];
  List<TrackModel> _onlineVideoResults = [];
  List<TrackModel> _spotifyTracks = [];
  bool _spotifyRequiresAuth = false;

  List<String> _searchSuggestions = [];
  bool _isLoadingSearch = false;
  String? _quotaOrAuthWarning;

  final List<Map<String, dynamic>> _genres = const [
    {
      'name': 'Tamil Hits',
      'colors': [Color(0xFFFF512F), Color(0xFFDD2476)]
    },
    {
      'name': 'Trending Pop',
      'colors': [Color(0xFF8E2DE2), Color(0xFF4A00E0)]
    },
    {
      'name': 'Hindi Bollywood',
      'colors': [Color(0xFFFF7675), Color(0xFFD63031)]
    },
    {
      'name': 'Telugu Hits',
      'colors': [Color(0xFFF7971E), Color(0xFFFFD200)]
    },
    {
      'name': 'Malayalam Melodies',
      'colors': [Color(0xFF2193B0), Color(0xFF6DD5ED)]
    },
    {
      'name': 'Lofi & Chill Beats',
      'colors': [Color(0xFF11998E), Color(0xFF38EF7D)]
    },
    {
      'name': 'Kannada Super Hits',
      'colors': [Color(0xFF8E2DE2), Color(0xFF4A00E0)]
    },
    {
      'name': 'Classical Focus',
      'colors': [Color(0xFF3A6073), Color(0xFF3A7BD5)]
    },
  ];

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    _debounceTimer?.cancel();
    final trimmed = text.trim();
    setState(() {
      _query = trimmed;
      _quotaOrAuthWarning = null;
    });

    if (trimmed.isEmpty) {
      setState(() {
        _localResults = [];
        _youtubeResults = [];
        _youtubeNextPageToken = null;
        _onlineResults = [];
        _onlineVideoResults = [];
        _spotifyTracks = [];
        _spotifyRequiresAuth = false;
        _searchSuggestions = [];
        _isLoadingSearch = false;
      });
      return;
    }

    // 1. Immediate local library & authorized video search
    final localRepo = ref.read(trackRepositoryProvider);
    final onlineMusicService = ref.read(onlineMusicServiceProvider);
    setState(() {
      _localResults = localRepo.searchTracks(trimmed);
      _onlineVideoResults = onlineMusicService.searchOnlineVideos(trimmed);
    });

    // 2. Fetch search suggestions fast
    final youtubeService = ref.read(youtubeApiServiceProvider);
    youtubeService.getSearchSuggestions(trimmed).then((suggestions) {
      if (mounted && _query == trimmed) {
        setState(() => _searchSuggestions = suggestions);
      }
    });

    // 3. Debounced concurrent API queries across YouTube, Spotify & Audius
    _debounceTimer = Timer(const Duration(milliseconds: 380), () async {
      final onlineRepo = ref.read(onlineMusicRepositoryProvider);
      final spotifyRepo = ref.read(spotifyRepositoryProvider);

      setState(() => _isLoadingSearch = true);

      try {
        final ytFuture = youtubeService.searchMusicVideosWithPagination(
          trimmed,
          maxResults: 15,
        );
        final onlineFuture = onlineRepo.searchOnlineTracks(trimmed);
        final spotifyFuture = spotifyRepo.searchSpotify(trimmed, limit: 15);

        final results = await Future.wait([
          ytFuture.catchError((e) {
            if (e is YouTubeApiException) {
              if (mounted) {
                setState(() {
                  _quotaOrAuthWarning = e.isConfigError
                      ? 'YouTube API key not configured. Tap to enter your API key.'
                      : 'YouTube daily quota reached. Enter your custom API key in Settings.';
                });
              }
            }
            return const YouTubeSearchResult(tracks: []);
          }),
          onlineFuture.catchError((_) => <TrackModel>[]),
          spotifyFuture.catchError((_) => <String, dynamic>{
                'tracks': <TrackModel>[],
                'playlists': <PlaylistModel>[],
                'requiresAuth': false,
              }),
        ]);

        if (mounted) {
          final ytResult = results[0] as YouTubeSearchResult;
          final spotifyResult = results[2] as Map<String, dynamic>;

          setState(() {
            _youtubeResults = ytResult.tracks;
            _youtubeNextPageToken = ytResult.nextPageToken;
            _onlineResults = results[1] as List<TrackModel>;
            _spotifyTracks = (spotifyResult['tracks'] as List?)?.cast<TrackModel>() ?? [];
            _spotifyRequiresAuth = spotifyResult['requiresAuth'] as bool? ?? false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _youtubeResults = [];
            _onlineResults = [];
            _spotifyTracks = [];
          });
        }
      } finally {
        if (mounted) setState(() => _isLoadingSearch = false);
      }
    });
  }

  Future<void> _loadMoreYouTube() async {
    if (_youtubeNextPageToken == null || _isLoadingMoreYouTube || _query.isEmpty) return;
    setState(() => _isLoadingMoreYouTube = true);
    try {
      final ytService = ref.read(youtubeApiServiceProvider);
      final res = await ytService.searchMusicVideosWithPagination(
        _query,
        pageToken: _youtubeNextPageToken,
        maxResults: 15,
      );
      if (mounted) {
        setState(() {
          _youtubeResults.addAll(res.tracks);
          _youtubeNextPageToken = res.nextPageToken;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingMoreYouTube = false);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _localResults = [];
      _youtubeResults = [];
      _youtubeNextPageToken = null;
      _onlineResults = [];
      _onlineVideoResults = [];
      _spotifyTracks = [];
      _spotifyRequiresAuth = false;
      _searchSuggestions = [];
      _isLoadingSearch = false;
      _quotaOrAuthWarning = null;
    });
  }

  void _showApiKeyConfigDialog() {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.key_rounded, color: Colors.redAccent),
            SizedBox(width: 8),
            Text('YouTube API Key',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google Cloud YouTube Data API v3 key to enable high-speed music search, exact video durations, and official player streaming.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'AIzaSy...',
                hintStyle: const TextStyle(color: AppColors.tertiaryText),
                filled: true,
                fillColor: AppColors.primaryBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              final key = textController.text.trim();
              if (key.isNotEmpty) {
                await secureStorage.saveCustomApiKey('youtube', key);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('YouTube API key updated successfully!')),
                  );
                  if (_query.isNotEmpty) _onSearchChanged(_query);
                }
              }
            },
            child: const Text('Save Key', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSpotifyConfigDialog() {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final clientIdController = TextEditingController();
    final clientSecretController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Row(
          children: [
            Icon(Icons.graphic_eq_rounded, color: Color(0xFF1DB954)),
            SizedBox(width: 8),
            Text('Spotify Integration',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Spotify Developer Client ID and Secret to search 100M+ tracks, artists, and playlists via Spotify Web API.',
              style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: clientIdController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Spotify Client ID',
                hintStyle: const TextStyle(color: AppColors.tertiaryText),
                filled: true,
                fillColor: AppColors.primaryBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: clientSecretController,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Spotify Client Secret (Optional)',
                hintStyle: const TextStyle(color: AppColors.tertiaryText),
                filled: true,
                fillColor: AppColors.primaryBackground,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1DB954)),
            onPressed: () async {
              final id = clientIdController.text.trim();
              final secret = clientSecretController.text.trim();
              if (id.isNotEmpty) {
                await secureStorage.saveSpotifyCredentials(
                  clientId: id,
                  clientSecret: secret.isNotEmpty ? secret : null,
                );
                final repo = ref.read(spotifyRepositoryProvider);
                if (secret.isNotEmpty) {
                  await repo.connectWithClientCredentials(id, secret);
                } else {
                  repo.configureClientId(id);
                }
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Spotify credentials saved!')),
                  );
                  if (_query.isNotEmpty) _onSearchChanged(_query);
                }
              }
            },
            child: const Text('Connect', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _playTrack(TrackModel track, List<TrackModel> queue) {
    final prefs = ref.read(sharedPreferencesServiceProvider);
    prefs.addRecentSearch(track.title);

    if (track.sourceType == AudioSourceType.youtubeVideo) {
      // 1. YouTube in-app video playback with official player
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => YoutubeMusicPlayerScreen(
            title: track.title,
            artist: track.artistName,
            videoId: track.youtubeVideoId,
            videoUrl: track.sourceDetailUrl,
            durationMs: track.durationMs,
            artworkUrl: track.artworkUrl,
            track: track,
          ),
        ),
      );
    } else if (track.sourceType == AudioSourceType.onlineVideo) {
      // 1.5 Authorized Online Video Stream: open HD Video Player
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OnlineVideoPlayerScreen(track: track),
        ),
      );
    } else if (track.sourceType == AudioSourceType.spotifyStream) {
      // 2. Spotify Track: if 30s preview URL is available, play in audio engine; else handoff to Spotify App
      if (track.previewUrl != null && track.previewUrl!.isNotEmpty) {
        final audio = ref.read(audioPlayerServiceProvider);
        audio.playTrack(track, queueContext: queue);
      } else {
        final repo = ref.read(spotifyRepositoryProvider);
        repo.openInSpotify(track.audioSourceUrl);
      }
    } else {
      // 3. Audio playback for local & audio stream tracks
      final audio = ref.read(audioPlayerServiceProvider);
      audio.playTrack(track, queueContext: queue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPreferencesServiceProvider);
    final recentSearches = prefs.getRecentSearches();
    final isSearching = _query.isNotEmpty;

    const sourceTabs = [
      {'label': 'All Sources', 'icon': Icons.apps_rounded, 'color': AppColors.primaryAccent},
      {'label': 'YouTube', 'icon': Icons.smart_display_rounded, 'color': Colors.redAccent},
      {'label': 'Videos', 'icon': Icons.ondemand_video_rounded, 'color': Color(0xFFC471ED)},
      {'label': 'Spotify', 'icon': Icons.graphic_eq_rounded, 'color': Color(0xFF1DB954)},
      {'label': 'Streams', 'icon': Icons.cloud_queue_rounded, 'color': Color(0xFF8E2DE2)},
      {'label': 'Local', 'icon': Icons.folder_rounded, 'color': Color(0xFF00B4D8)},
    ];

    // Filter displayed results based on selected source tab
    List<TrackModel> displayedResults = [];
    if (_searchSourceIndex == 0) {
      displayedResults = [
        ..._youtubeResults,
        ..._onlineVideoResults,
        ..._spotifyTracks,
        ..._onlineResults,
        ..._localResults,
      ];
    } else if (_searchSourceIndex == 1) {
      displayedResults = _youtubeResults;
    } else if (_searchSourceIndex == 2) {
      displayedResults = _onlineVideoResults;
    } else if (_searchSourceIndex == 3) {
      displayedResults = _spotifyTracks;
    } else if (_searchSourceIndex == 4) {
      displayedResults = _onlineResults;
    } else if (_searchSourceIndex == 5) {
      displayedResults = _localResults;
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: Text('Search Music',
            style: AppTypography.displayMedium.copyWith(fontSize: 24)),
        actions: [
          IconButton(
            icon: const Icon(Icons.graphic_eq_rounded, size: 20, color: Color(0xFF1DB954)),
            tooltip: 'Spotify Integration Settings',
            onPressed: _showSpotifyConfigDialog,
          ),
          IconButton(
            icon: const Icon(Icons.vpn_key_outlined, size: 20, color: Colors.redAccent),
            tooltip: 'YouTube API Key Settings',
            onPressed: _showApiKeyConfigDialog,
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  style: AppTypography.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Search songs across YouTube, Spotify, Streams...',
                    hintStyle: AppTypography.bodyMedium
                        .copyWith(color: AppColors.tertiaryText),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.secondaryText),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded,
                                color: AppColors.secondaryText),
                            onPressed: _clearSearch,
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
            ),
          ),

          // 2. Source Provider Filter Chips
          if (isSearching)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: sourceTabs.length,
                  itemBuilder: (context, index) {
                    final tab = sourceTabs[index];
                    final isSelected = _searchSourceIndex == index;
                    final tabColor = tab['color'] as Color;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        avatar: Icon(
                          tab['icon'] as IconData,
                          size: 16,
                          color: isSelected ? Colors.black : tabColor,
                        ),
                        label: Text(
                          tab['label'] as String,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected ? Colors.black : AppColors.primaryText,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: tabColor,
                        backgroundColor: AppColors.surface,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        onSelected: (_) {
                          setState(() => _searchSourceIndex = index);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

          // 2.2 Live Search Suggestions
          if (isSearching && _searchSuggestions.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                height: 34,
                margin: const EdgeInsets.only(top: 8),
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _searchSuggestions.length,
                  itemBuilder: (context, idx) {
                    final sug = _searchSuggestions[idx];
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        backgroundColor: AppColors.surfaceElevated,
                        label: Text(sug, style: const TextStyle(fontSize: 11)),
                        onPressed: () {
                          _searchController.text = sug;
                          _onSearchChanged(sug);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

          // 2.5 YouTube Warning Banner
          if (_quotaOrAuthWarning != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _quotaOrAuthWarning!,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: _showApiKeyConfigDialog,
                        child: const Text('Config Key',
                            style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 2.7 Spotify Unauthenticated Helper Card (When viewing Spotify tab)
          if (isSearching && _searchSourceIndex == 2 && (_spotifyRequiresAuth || _spotifyTracks.isEmpty && !_isLoadingSearch))
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1DB954).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF1DB954).withValues(alpha: 0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.graphic_eq_rounded, color: Color(0xFF1DB954), size: 20),
                          SizedBox(width: 8),
                          Text('Spotify Catalog Integration',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Connect Spotify API using your Developer Client ID or PKCE to search 100M+ songs, view full album art, and hand off playback directly to Spotify.',
                        style: TextStyle(color: AppColors.secondaryText, fontSize: 12),
                      ),
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1DB954),
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        ),
                        onPressed: _showSpotifyConfigDialog,
                        icon: const Icon(Icons.vpn_key_rounded, size: 16),
                        label: const Text('Configure Spotify API', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 3. Search Results
          if (isSearching) ...[
            if (_isLoadingSearch)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.primaryAccent),
                  ),
                ),
              ),
            if (displayedResults.isEmpty && !_isLoadingSearch)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.search_off_rounded,
                  title: 'No results found',
                  description:
                      'No matching tracks for "$_query" under ${sourceTabs[_searchSourceIndex]['label']}. Try switching the source chip or adjusting keywords.',
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = displayedResults[index];
                    final isYouTube = track.sourceType == AudioSourceType.youtubeVideo;
                    final isOnlineVideo = track.sourceType == AudioSourceType.onlineVideo;
                    final isSpotify = track.sourceType == AudioSourceType.spotifyStream;
                    final isOnline = track.sourceType == AudioSourceType.networkStream;

                    Color pillColor = const Color(0xFF00B4D8);
                    String pillText = 'Local';
                    IconData trailingIcon = Icons.play_circle_filled_rounded;

                    if (isYouTube) {
                      pillColor = Colors.redAccent;
                      pillText = 'YouTube';
                      trailingIcon = Icons.smart_display_rounded;
                    } else if (isOnlineVideo) {
                      pillColor = const Color(0xFFC471ED);
                      pillText = 'Video';
                      trailingIcon = Icons.ondemand_video_rounded;
                    } else if (isSpotify) {
                      pillColor = const Color(0xFF1DB954);
                      pillText = 'Spotify';
                      trailingIcon = Icons.open_in_new_rounded;
                    } else if (isOnline) {
                      pillColor = const Color(0xFF8E2DE2);
                      pillText = 'Stream';
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Stack(
                          children: [
                            NetworkOrAssetImage(
                              imageUrl: track.artworkUrl,
                              width: 52,
                              height: 52,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            Positioned(
                              bottom: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isYouTube
                                      ? Icons.play_arrow_rounded
                                      : (isSpotify ? Icons.graphic_eq_rounded : Icons.music_note_rounded),
                                  size: 12,
                                  color: pillColor,
                                ),
                              ),
                            ),
                          ],
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
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: pillColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                pillText,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: pillColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Text(
                          isYouTube
                              ? '${track.artistName} • ${DurationFormatter.formatMs(track.durationMs)} • ID: ${track.youtubeVideoId ?? ""}'
                              : '${track.artistName} • ${DurationFormatter.formatMs(track.durationMs)}',
                          style: AppTypography.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: IconButton(
                          icon: Icon(trailingIcon, color: pillColor, size: 28),
                          tooltip: isYouTube
                              ? 'Watch in YouTube Player'
                              : (isSpotify ? 'Open in Spotify' : 'Play Song'),
                          onPressed: () => _playTrack(track, displayedResults),
                        ),
                        onTap: () => _playTrack(track, displayedResults),
                      ),
                    );
                  },
                  childCount: displayedResults.length,
                ),
              ),

            // Pagination button for YouTube
            if (_searchSourceIndex == 1 && _youtubeNextPageToken != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Center(
                    child: _isLoadingMoreYouTube
                        ? const CircularProgressIndicator(color: Colors.redAccent)
                        : OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent),
                            ),
                            icon: const Icon(Icons.expand_more_rounded),
                            label: const Text('Load More YouTube Videos'),
                            onPressed: _loadMoreYouTube,
                          ),
                  ),
                ),
              ),
          ] else ...[
            // Recent Searches header
            if (recentSearches.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Searches',
                          style: AppTypography.titleMedium
                              .copyWith(fontWeight: FontWeight.w600)),
                      TextButton(
                        onPressed: () {
                          prefs.clearRecentSearches();
                          setState(() {});
                        },
                        child: Text('Clear All',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.secondaryText)),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 40,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: recentSearches.length,
                    itemBuilder: (context, index) {
                      final item = recentSearches[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          backgroundColor: AppColors.surface,
                          label: Text(item, style: AppTypography.bodySmall),
                          avatar: const Icon(Icons.history_rounded,
                              size: 16, color: AppColors.secondaryText),
                          onPressed: () {
                            _searchController.text = item;
                            _onSearchChanged(item);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],

            // Explore Genres Title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                child: Text('Explore Genres & Music Hubs',
                    style: AppTypography.titleMedium
                        .copyWith(fontWeight: FontWeight.w700)),
              ),
            ),

            // Vibrant Genre Cards Grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.6,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final genre = _genres[index];
                    final colors = genre['colors'] as List<Color>;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: colors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: colors.first.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => GenreDetailScreen(
                                  genreName: genre['name'] as String,
                                  gradientColors: colors,
                                ),
                              ),
                            );
                          },
                          child: Stack(
                            children: [
                              Positioned(
                                top: 12,
                                left: 12,
                                right: 12,
                                child: Text(
                                  genre['name'] as String,
                                  style: AppTypography.titleMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: -10,
                                right: -10,
                                child: Transform.rotate(
                                  angle: 0.4,
                                  child: Icon(
                                    Icons.music_note_rounded,
                                    size: 64,
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _genres.length,
                ),
              ),
            ),
          ],

          const SliverToBoxAdapter(
            child: SizedBox(height: 90),
          ),
        ],
      ),
    );
  }
}
