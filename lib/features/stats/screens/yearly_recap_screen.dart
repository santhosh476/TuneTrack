import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/utils/duration_formatter.dart';
import '../../../core/widgets/network_or_asset_image.dart';
import '../../../data/models/stats_summary_model.dart';

class YearlyRecapScreen extends ConsumerStatefulWidget {
  const YearlyRecapScreen({super.key});

  @override
  ConsumerState<YearlyRecapScreen> createState() => _YearlyRecapScreenState();
}

class _YearlyRecapScreenState extends ConsumerState<YearlyRecapScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(statsSummaryProvider(StatsTimeRange.allTime));
    final topTrack = stats.topTracks.isNotEmpty ? stats.topTracks.first : null;
    final topArtist =
        stats.topArtists.isNotEmpty ? stats.topArtists.first : null;

    final slides = [
      // Slide 1: Welcome
      _buildSlide(
        gradient: AppColors.purpleGradient,
        icon: Icons.auto_awesome_rounded,
        tag: 'TUNETRACK RECAP',
        title: 'Your Sound Story',
        subtitle:
            'Here is the music and vibe that defined your listening journey.',
      ),
      // Slide 2: Total Hours
      _buildSlide(
        gradient: AppColors.sunsetGradient,
        icon: Icons.access_time_filled_rounded,
        tag: 'LISTENING MILESTONE',
        title: DurationFormatter.formatListeningSeconds(
            stats.totalListeningSeconds),
        subtitle:
            'You completed ${stats.validPlaysCount} total valid plays across all sessions.',
      ),
      // Slide 3: Top Track
      _buildSlide(
        gradient: AppColors.greenGradient,
        icon: Icons.music_note_rounded,
        tag: 'YOUR #1 TRACK',
        title: topTrack?.title ?? 'Midnight Echoes',
        subtitle: topTrack != null
            ? 'Played ${topTrack.playCount} times by ${topTrack.subtitle}'
            : 'Explore more music to reveal your #1 track!',
        artworkUrl: topTrack?.artworkUrl,
      ),
      // Slide 4: Top Artist
      _buildSlide(
        gradient: AppColors.oceanGradient,
        icon: Icons.person_rounded,
        tag: 'TOP ARTIST',
        title: topArtist?.title ?? 'Luna Horizon',
        subtitle: 'You spent hours immersed in their unique soundscapes.',
      ),
      // Slide 5: Streak & Dedication
      _buildSlide(
        gradient: AppColors.amberGradient,
        icon: Icons.local_fire_department_rounded,
        tag: 'LISTENING DEDICATION',
        title: '${stats.longestStreak} Day Streak',
        subtitle:
            'Your passion for music kept the rhythm alive every single day.',
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (idx) => setState(() => _currentPage = idx),
            itemCount: slides.length,
            itemBuilder: (context, index) => slides[index],
          ),

          // Progress indicators at top
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              children: List.generate(slides.length, (i) {
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: i <= _currentPage ? Colors.white : Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Close button
          Positioned(
            top: 60,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white, size: 28),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide({
    required List<Color> gradient,
    required IconData icon,
    required String tag,
    required String title,
    required String subtitle,
    String? artworkUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tag,
              style: AppTypography.labelSmall.copyWith(
                color: Colors.white,
                letterSpacing: 1.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 32),
          if (artworkUrl != null) ...[
            NetworkOrAssetImage(
              imageUrl: artworkUrl,
              width: 180,
              height: 180,
              borderRadius: BorderRadius.circular(16),
            ),
            const SizedBox(height: 24),
          ] else ...[
            Icon(icon, size: 80, color: Colors.white),
            const SizedBox(height: 24),
          ],
          Text(
            title,
            style: AppTypography.displayLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            subtitle,
            style: AppTypography.titleMedium.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
