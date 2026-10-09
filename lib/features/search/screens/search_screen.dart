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
  String _query = '';
  List<TrackModel> _searchResults = [];
  bool _isSearching = false;

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
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String text) {
    setState(() {
      _query = text;
      _isSearching = text.isNotEmpty;
    });

    if (text.isNotEmpty) {
      final repo = ref.read(trackRepositoryProvider);
      setState(() {
        _searchResults = repo.searchTracks(text);
      });
    }
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _query = '';
      _isSearching = false;
      _searchResults = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(sharedPreferencesServiceProvider);
    final recentSearches = prefs.getRecentSearches();
    final audio = ref.read(audioPlayerServiceProvider);

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: Text('Search',
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
                    hintText: 'What do you want to listen to?',
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

          // 2. Search Results View OR Browse Genres View
          if (_isSearching) ...[
            if (_searchResults.isEmpty)
              SliverFillRemaining(
                child: EmptyStateView(
                  icon: Icons.search_off_rounded,
                  title: 'No results found',
                  description:
                      'We couldn\'t find any tracks matching "$_query"',
                ),
              )
            else
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final track = _searchResults[index];
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
                        icon: const Icon(Icons.play_circle_filled_rounded,
                            color: AppColors.primaryAccent, size: 30),
                        onPressed: () {
                          prefs.addRecentSearch(track.title);
                          audio.playTrack(track, queueContext: _searchResults);
                        },
                      ),
                      onTap: () {
                        prefs.addRecentSearch(track.title);
                        audio.playTrack(track, queueContext: _searchResults);
                      },
                    );
                  },
                  childCount: _searchResults.length,
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
