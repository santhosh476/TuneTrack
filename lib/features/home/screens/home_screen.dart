import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../data/models/track_model.dart';
import '../../../data/models/stats_summary_model.dart';
import '../../library/screens/playlist_detail_screen.dart';
import '../../onboarding/screens/language_onboarding_screen.dart';
import '../../player/screens/youtube_music_player_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _playTrack(BuildContext context, WidgetRef ref, TrackModel track,
      List<TrackModel> queue) {
    if (track.sourceType == AudioSourceType.youtubeVideo) {
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
    } else if (track.sourceType == AudioSourceType.spotifyStream &&
        (track.previewUrl == null || track.previewUrl!.isEmpty) &&
        track.audioSourceUrl.isEmpty) {
      ref.read(spotifyRepositoryProvider).openInSpotify(track.sourceDetailUrl ?? track.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening "${track.title}" in Spotify...'),
          backgroundColor: const Color(0xFF1DB954),
        ),
      );
    } else {
      final audio = ref.read(audioPlayerServiceProvider);
      audio.playTrack(track, queueContext: queue);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tracks = ref.watch(allTracksProvider);
    final playlists = ref.watch(playlistsProvider);
    final stats = ref.watch(statsSummaryProvider(StatsTimeRange.day));
    final audio = ref.read(audioPlayerServiceProvider);
    final recommendedAsync = ref.watch(recommendedTracksFutureProvider);

    final greeting = DateFormatter.getGreeting();
    final preferredLanguages = user.preferredLanguages.isNotEmpty
        ? user.preferredLanguages
        : ['Tamil', 'English'];

    // Separate local vs online tracks
    final localTracks = tracks
        .where((t) =>
            t.sourceType == AudioSourceType.localFile ||
            t.sourceType == AudioSourceType.demoAsset)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          // 1. App Bar / Dynamic Greeting & Profile Info
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.primaryBackground,
            title: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      AppColors.primaryAccent.withValues(alpha: 0.2),
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName.substring(0, 1).toUpperCase()
                        : 'T',
                    style: const TextStyle(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: AppTypography.displayMedium.copyWith(
                            fontSize: 20, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${user.displayName} • ${user.primaryLanguage}',
                        style: AppTypography.labelSmall
                            .copyWith(color: AppColors.primaryAccent),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Language Selector Action Chip
              IconButton(
                icon: const Icon(Icons.translate_rounded,
                    color: AppColors.primaryText),
                tooltip: 'Language Preferences',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const LanguageOnboardingScreen(
                        isFromSettings: true,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),

          // 2. Daily Goal & Streak Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A2F), Color(0xFF16251F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: AppColors.primaryAccent.withValues(alpha: 0.3),
                      width: 1),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryAccent.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.local_fire_department_rounded,
                          color: AppColors.primaryAccent, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Daily Listening Goal',
                                style: AppTypography.titleMedium
                                    .copyWith(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${stats.todayListeningMinutes}/${stats.dailyGoalMinutes}m',
                                style: AppTypography.labelMedium.copyWith(
                                  color: stats.isGoalMet
                                      ? AppColors.primaryAccent
                                      : AppColors.secondaryText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: stats.goalProgress,
                              minHeight: 6,
                              backgroundColor: Colors.white12,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                stats.isGoalMet
                                    ? AppColors.primaryAccentLight
                                    : AppColors.primaryAccent,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            stats.currentStreak > 0
                                ? '🔥 ${stats.currentStreak} day streak! Keep listening.'
                                : 'Start your listening streak today!',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.secondaryText),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. Quick Playlists Grid (2x3 cards)
          if (playlists.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 3.0,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final p = playlists[index % playlists.length];
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    PlaylistDetailScreen(playlistId: p.id),
                              ),
                            );
                          },
                          child: Row(
                            children: [
                              NetworkOrAssetImage(
                                imageUrl: p.coverUrl,
                                width: 56,
                                height: 56,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(8),
                                  bottomLeft: Radius.circular(8),
                                ),
                                placeholderIcon: Icons.queue_music_rounded,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  p.title,
                                  style: AppTypography.titleSmall
                                      .copyWith(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: playlists.length.clamp(0, 6),
                ),
              ),
            ),

          // 4. Personalized Recommendations based on Preferred Languages
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Recommended for You',
              subtitle:
                  'Tailored for ${user.primaryLanguage} & your favorite genres',
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 210,
              child: recommendedAsync.when(
                data: (recs) {
                  final list = recs.isNotEmpty ? recs : tracks;
                  if (list.isEmpty) {
                    return const Center(
                      child: Text('No recommendations available yet.',
                          style: TextStyle(color: AppColors.secondaryText)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final track = list[index];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => _playTrack(context, ref, track, list),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  NetworkOrAssetImage(
                                    imageUrl: track.artworkUrl,
                                    width: 140,
                                    height: 140,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  if (track.title.contains('(Preview)') ||
                                      track.id.startsWith('itunes_'))
                                    Positioned(
                                      top: 6,
                                      right: 6,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.black
                                              .withValues(alpha: 0.75),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'Preview',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orangeAccent,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                track.title,
                                style: AppTypography.titleSmall
                                    .copyWith(fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                track.artistName,
                                style: AppTypography.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                ),
                error: (_, __) => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  scrollDirection: Axis.horizontal,
                  itemCount: tracks.length,
                  itemBuilder: (context, index) {
                    final track = tracks[index];
                    return Container(
                      width: 140,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () =>
                            audio.playTrack(track, queueContext: tracks),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NetworkOrAssetImage(
                              imageUrl: track.artworkUrl,
                              width: 140,
                              height: 140,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              track.title,
                              style: AppTypography.titleSmall
                                  .copyWith(fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              track.artistName,
                              style: AppTypography.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 5. Dynamic Language-Based Sections
          for (final lang in preferredLanguages.take(3)) ...[
            SliverToBoxAdapter(
              child: SectionHeader(
                title: '$lang Melodies & Hits',
                subtitle: 'Top streamable tracks in $lang',
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 200,
                child: Consumer(
                  builder: (context, ref, _) {
                    final langTracksAsync =
                        ref.watch(languageTracksFutureProvider(lang));
                    return langTracksAsync.when(
                      data: (langTracks) {
                        final items =
                            langTracks.isNotEmpty ? langTracks : tracks;
                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final track = items[index];
                            return Container(
                              width: 130,
                              margin: const EdgeInsets.symmetric(horizontal: 6),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(10),
                                onTap: () =>
                                    _playTrack(context, ref, track, items),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    NetworkOrAssetImage(
                                      imageUrl: track.artworkUrl,
                                      width: 130,
                                      height: 130,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      track.title,
                                      style: AppTypography.titleSmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Text(
                                      track.artistName,
                                      style: AppTypography.bodySmall
                                          .copyWith(fontSize: 11),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryAccent,
                          ),
                        ),
                      ),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                ),
              ),
            ),
          ],

          // 6. Local Device Audio Section (Offline Playable)
          if (localTracks.isNotEmpty) ...[
            const SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Local Music on Device',
                subtitle: 'Offline playable tracks from local storage',
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final track = localTracks[index];
                  return ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
                      icon: const Icon(Icons.play_arrow_rounded,
                          color: AppColors.primaryAccent),
                      onPressed: () =>
                          _playTrack(context, ref, track, localTracks),
                    ),
                    onTap: () => _playTrack(context, ref, track, localTracks),
                  );
                },
                childCount: localTracks.length.clamp(0, 5),
              ),
            ),
          ],

          // 7. Quick Picks / All Tracks List
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'All Music & Discoveries',
              subtitle: 'From public catalog and your library',
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = tracks[index];
                final isYouTube =
                    track.sourceType == AudioSourceType.youtubeVideo;
                final isSpotify =
                    track.sourceType == AudioSourceType.spotifyStream;
                final isOnline =
                    track.sourceType == AudioSourceType.networkStream;
                return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
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
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isYouTube
                              ? Colors.red.withValues(alpha: 0.2)
                              : (isSpotify
                                  ? const Color(0xFF1DB954)
                                      .withValues(alpha: 0.2)
                                  : (isOnline
                                      ? const Color(0xFF8E2DE2)
                                          .withValues(alpha: 0.2)
                                      : AppColors.surfaceLight)),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          isYouTube
                              ? 'YouTube'
                              : (isSpotify
                                  ? 'Spotify'
                                  : (isOnline ? 'Online' : 'Local')),
                          style: TextStyle(
                            fontSize: 9,
                            color: isYouTube
                                ? Colors.redAccent
                                : (isSpotify
                                    ? const Color(0xFF1DB954)
                                    : (isOnline
                                        ? const Color(0xFF8E2DE2)
                                        : AppColors.secondaryText)),
                            fontWeight: FontWeight.bold,
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
                    icon: Icon(
                      isYouTube
                          ? Icons.smart_display_rounded
                          : (isSpotify
                              ? Icons.music_note_rounded
                              : Icons.play_arrow_rounded),
                      color: isYouTube
                          ? Colors.redAccent
                          : (isSpotify
                              ? const Color(0xFF1DB954)
                              : AppColors.primaryAccent),
                    ),
                    onPressed: () => _playTrack(context, ref, track, tracks),
                  ),
                  onTap: () => _playTrack(context, ref, track, tracks),
                );
              },
              childCount: tracks.length,
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 90), // Bottom padding for mini-player
          ),
        ],
      ),
    );
  }
}
