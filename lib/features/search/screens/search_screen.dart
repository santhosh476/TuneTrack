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
  int _searchSourceIndex = 0; // 0: All, 1: Spotify, 2: Local
  final List<String> _searchSources = const [
    'All Results',
    'Spotify Catalogue',
    'Local Device Audio'
  ];

  List<TrackModel> _localResults = [];
  List<TrackModel> _spotifyResults = [];
  bool _isLoadingSpotify = false;

  final List<Map<String, dynamic>> _genres = const [
    {
      'name': 'Synthwave',
      'colors': [Color(0xFF8E2DE2), Color(0xFF4A00E0)]
    },
    {
      'name': 'Ambient & Chill',
      'colors': [Color(0xFF2193B0), Color(0xFF6DD5ED)]
    },
    {
      'name': 'Lofi Beats',
      'colors': [Color(0xFFFF512F), Color(0xFFDD2476)]
    },
    {
      'name': 'Electronic',
      'colors': [Color(0xFF11998E), Color(0xFF38EF7D)]
    },
    {
      'name': 'Acoustic',
      'colors': [Color(0xFFF7971E), Color(0xFFFFD200)]
    },
    {
      'name': 'Hip-Hop',
      'colors': [Color(0xFFEB3349), Color(0xFFF45C43)]
    },
    {
      'name': 'Rock & Indie',
      'colors': [Color(0xFF4568DC), Color(0xFFB06AB3)]
    },
    {
      'name': 'Jazz & Soul',
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
    setState(() {
      _query = text.trim();
    });

    if (text.trim().isEmpty) {
      setState(() {
        _localResults = [];
        _spotifyResults = [];
        _isLoadingSpotify = false;
      });
      return;
    }

    // Immediate local search
    final localRepo = ref.read(trackRepositoryProvider);
    final localMatches = localRepo.searchTracks(text.trim());
    setState(() {
      _localResults = localMatches;
    });

    // Debounced Spotify search (300ms)
    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      final spotifyRepo = ref.read(spotifyRepositoryProvider);
      setState(() => _isLoadingSpotify = true);
      try {
        final res = await spotifyRepo.searchSpotify(text.trim());
        if (mounted) {
          setState(() {
            _spotifyResults = (res['tracks'] as List<TrackModel>?) ?? [];
          });
        }
      } catch (_) {
        if (mounted) setState(() => _spotifyResults = []);
      } finally {
        if (mounted) setState(() => _isLoadingSpotify = false);
      }
    });
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _localResults = [];
      _spotifyResults = [];
      _isLoadingSpotify = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPreferencesServiceProvider);
    final recentSearches = prefs.getRecentSearches();
    final audio = ref.read(audioPlayerServiceProvider);
    final spotifyRepo = ref.read(spotifyRepositoryProvider);
    final isSearching = _query.isNotEmpty;

    // Filter results based on selected search source chip
    List<TrackModel> displayedResults = [];
    if (_searchSourceIndex == 0) {
      displayedResults = [..._localResults, ..._spotifyResults];
    } else if (_searchSourceIndex == 1) {
      displayedResults = _spotifyResults;
    } else {
      displayedResults = _localResults;
    }

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: Text('Search Music',
            style: AppTypography.displayMedium.copyWith(fontSize: 24)),
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
                    hintText: 'Search songs, artists, or Spotify catalogue...',
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

          // 2. Search Source Selector Chips (when query is active)
          if (isSearching)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _searchSources.length,
                  itemBuilder: (context, index) {
                    final isSelected = _searchSourceIndex == index;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(
                          _searchSources[index],
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? Colors.black
                                : AppColors.primaryText,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: index == 1
                            ? const Color(0xFF1DB954)
                            : AppColors.primaryAccent,
                        backgroundColor: AppColors.surface,
                        side: BorderSide.none,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        onSelected: (val) {
                          setState(() {
                            _searchSourceIndex = index;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

          // 3. Search Results View OR Browse Genres View
          if (isSearching) ...[
            if (_isLoadingSpotify)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF1DB954)),
                    ),
                  ),
                ),
              ),
            if (displayedResults.isEmpty && !_isLoadingSpotify)
              SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyStateView(
                  icon: Icons.search_off_rounded,
                  title: 'No results found',
                  description:
                      'We couldn\'t find any matching tracks for "$_query". Try searching by another song or artist name.',
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = displayedResults[index];
                    final isSpotify =
                        track.sourceType == AudioSourceType.spotifyStream;
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSpotify
                                    ? const Color(0xFF1DB954)
                                        .withValues(alpha: 0.2)
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
                          '${track.artistName} • ${DurationFormatter.formatMs(track.durationMs)}',
                          style: AppTypography.bodySmall,
                        ),
                        trailing: isSpotify
                            ? IconButton(
                                icon: const Icon(Icons.open_in_new_rounded,
                                    color: Color(0xFF1DB954), size: 22),
                                tooltip: 'Open in Spotify',
                                onPressed: () {
                                  prefs.addRecentSearch(track.title);
                                  spotifyRepo.openInSpotify(track.audioUrl);
                                },
                              )
                            : IconButton(
                                icon: const Icon(
                                    Icons.play_circle_filled_rounded,
                                    color: AppColors.primaryAccent,
                                    size: 30),
                                onPressed: () {
                                  prefs.addRecentSearch(track.title);
                                  audio.playTrack(track,
                                      queueContext: displayedResults);
                                },
                              ),
                        onTap: () {
                          prefs.addRecentSearch(track.title);
                          if (isSpotify) {
                            spotifyRepo.openInSpotify(track.audioUrl);
                          } else {
                            audio.playTrack(track,
                                queueContext: displayedResults);
                          }
                        },
                      ),
                    );
                  },
                  childCount: displayedResults.length,
                ),
              ),
          ] else ...[
            // Recent searches header
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
                child: Text('Explore Genres & Moods',
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
            child: SizedBox(height: 90), // Mini player padding
          ),
        ],
      ),
    );
  }
}
