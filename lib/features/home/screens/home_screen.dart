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

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final tracks = ref.watch(allTracksProvider);
    final playlists = ref.watch(playlistsProvider);
    final stats = ref.watch(statsSummaryProvider(StatsTimeRange.day));
    final audio = ref.read(audioPlayerServiceProvider);

    final greeting = DateFormatter.getGreeting();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: CustomScrollView(
        slivers: [
          // 1. App Bar / Greeting
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.primaryBackground,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: AppTypography.displayMedium.copyWith(fontSize: 22),
                ),
                Text(
                  user.displayName,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.primaryAccent),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: AppColors.primaryText),
                onPressed: () {},
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

          // 4. Featured Online Streams & Trending Tracks
          SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Featured & Trending',
              subtitle: 'Open public streaming catalogue & trending songs',
              actionText: 'View All',
              onAction: () {},
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 210,
              child: Builder(
                builder: (context) {
                  final displayTracks = tracks;
                  if (displayTracks.isEmpty) {
                    return const Center(
                      child: Text('No tracks available. Import or search online.',
                          style: TextStyle(color: AppColors.secondaryText)),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: displayTracks.length,
                    itemBuilder: (context, index) {
                      final track = displayTracks[index];
                      return Container(
                        width: 140,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => audio.playTrack(track,
                              queueContext: displayTracks),
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
                  );
                },
              ),
            ),
          ),

          // 5. Quick Picks for You (All Tracks)
          const SliverToBoxAdapter(
            child: SectionHeader(
              title: 'Quick Picks for You',
              subtitle: 'From your device library and recent streams',
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final track = tracks[index];
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
                          color: isOnline
                              ? const Color(0xFF8E2DE2).withValues(alpha: 0.2)
                              : AppColors.surfaceLight,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          isOnline ? 'Online' : 'Local',
                          style: TextStyle(
                            fontSize: 9,
                            color: isOnline
                                ? const Color(0xFF8E2DE2)
                                : AppColors.secondaryText,
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
                    icon: const Icon(Icons.play_arrow_rounded,
                        color: AppColors.primaryAccent),
                    onPressed: () =>
                        audio.playTrack(track, queueContext: tracks),
                  ),
                  onTap: () => audio.playTrack(track, queueContext: tracks),
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
