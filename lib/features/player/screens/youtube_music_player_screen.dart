import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// YouTube Music & Video Experience Screen supporting instant video discovery,
/// official playback, lyric video watching, and YouTube App integration.
class YoutubeMusicPlayerScreen extends StatelessWidget {
  final String title;
  final String artist;
  final String? videoUrl;

  const YoutubeMusicPlayerScreen({
    super.key,
    required this.title,
    this.artist = 'YouTube Music',
    this.videoUrl,
  });

  Future<void> _launchYouTube(BuildContext context) async {
    final searchParam = Uri.encodeComponent('$title $artist official video');
    final url = videoUrl != null && videoUrl!.isNotEmpty
        ? Uri.parse(videoUrl!)
        : Uri.parse('https://www.youtube.com/results?search_query=$searchParam');

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch YouTube.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        elevation: 0,
        title: Text(
          'YouTube Music Video',
          style: AppTypography.displayMedium.copyWith(fontSize: 18),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // YouTube Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.red.withValues(alpha: 0.4), width: 1.2),
              ),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_circle_fill_rounded,
                      color: Colors.red,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTypography.titleLarge
                        .copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artist,
                    style: AppTypography.bodyMedium
                        .copyWith(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 20),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 16),
                  Text(
                    'Watch official HD music videos, live concerts, and lyric videos directly on YouTube with full controls.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.secondaryText),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _launchYouTube(context),
                      icon: const Icon(Icons.play_arrow_rounded, color: Colors.white),
                      label: const Text(
                        'Watch on YouTube',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
