import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../auth/screens/login_screen.dart';
import 'spotify_connect_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final syncService = ref.watch(cloudSyncServiceProvider);
    final prefs = ref.watch(sharedPreferencesServiceProvider);
    final lastSync = prefs.getLastSyncTime();

    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBackground,
        title: Text('Profile & Settings',
            style: AppTypography.displayMedium.copyWith(fontSize: 24)),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. User Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 0.5),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryAccent,
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : 'U',
                    style: AppTypography.displayMedium.copyWith(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.displayName,
                        style: AppTypography.titleLarge
                            .copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.isGuest
                            ? 'Guest Mode (Offline-First)'
                            : user.email,
                        style: AppTypography.bodySmall.copyWith(
                          color: user.isGuest
                              ? AppColors.warning
                              : AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                if (user.isGuest)
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                      );
                    },
                    child: const Text('Sign In'),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.error),
                    tooltip: 'Log Out',
                    onPressed: () => _confirmLogout(context, ref),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Listening Preferences
          Text('Listening Preferences',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.timer_outlined,
                      color: AppColors.primaryAccent),
                  title: Text('Daily Listening Goal',
                      style: AppTypography.bodyLarge),
                  subtitle: Text('${user.dailyGoalMinutes} minutes / day',
                      style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.secondaryText),
                  onTap: () => _showGoalSliderDialog(
                      context, ref, user.dailyGoalMinutes),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Integrations & Cloud Sync
          Text('Integrations & Sync',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.music_note_rounded,
                      color: AppColors.primaryAccent),
                  title: Text('Spotify Integration',
                      style: AppTypography.bodyLarge),
                  subtitle: Text('Connect Spotify account & remote devices',
                      style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.secondaryText),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const SpotifyConnectScreen()),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.cloud_sync_outlined,
                      color: AppColors.secondaryAccent),
                  title: Text('Cloud Synchronization',
                      style: AppTypography.bodyLarge),
                  subtitle: Text(
                    lastSync != null
                        ? 'Last sync: ${lastSync.toLocal().toString().split('.')[0]}'
                        : 'Offline / Ready',
                    style: AppTypography.bodySmall,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.sync_rounded,
                        color: AppColors.primaryAccent),
                    onPressed: () async {
                      await syncService.syncPendingOperations();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Offline queue synchronized successfully!')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Privacy & Data
          Text('Privacy & Data',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                ListTile(
                  leading:
                      const Icon(Icons.download_rounded, color: AppColors.info),
                  title: Text('Export My Data (JSON)',
                      style: AppTypography.bodyLarge),
                  subtitle: Text('Export local playlists & listening history',
                      style: AppTypography.bodySmall),
                  onTap: () => _exportUserData(context, ref, user.id),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.delete_sweep_rounded,
                      color: AppColors.error),
                  title: Text('Clear Listening History',
                      style: AppTypography.bodyLarge
                          .copyWith(color: AppColors.error)),
                  onTap: () => _confirmClearHistory(context, ref, user.id),
                ),
              ],
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showGoalSliderDialog(
      BuildContext context, WidgetRef ref, int currentMins) {
    double tempVal = currentMins.toDouble();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.secondaryBackground,
          title:
              Text('Daily Listening Goal', style: AppTypography.headlineSmall),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${tempVal.toInt()} Minutes / Day',
                  style: AppTypography.titleLarge
                      .copyWith(color: AppColors.primaryAccent)),
              Slider(
                value: tempVal,
                min: 15,
                max: 180,
                divisions: 11,
                onChanged: (v) => setState(() => tempVal = v),
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
                await ref
                    .read(userRepositoryProvider)
                    .updateDailyGoal(tempVal.toInt());
                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportUserData(BuildContext context, WidgetRef ref, String userId) {
    final jsonString = ref.read(sessionRepositoryProvider).exportJson(userId);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: Text('Exported User Data', style: AppTypography.headlineSmall),
        content: SizedBox(
          width: double.maxFinite,
          height: 250,
          child: SingleChildScrollView(
            child: SelectableText(jsonString,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: jsonString));
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Copied data JSON to clipboard!')),
                );
              }
            },
            child: const Text('Copy to Clipboard'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(
      BuildContext context, WidgetRef ref, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: Text('Clear History?', style: AppTypography.headlineSmall),
        content: Text(
          'Are you sure you want to erase all recorded listening history? This cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              await ref
                  .read(sessionRepositoryProvider)
                  .clearHistory(userId: userId);
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Listening history cleared.')),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: Text('Sign Out', style: AppTypography.headlineSmall),
        content: Text('Sign out and switch back to Guest mode?',
            style: AppTypography.bodyMedium),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
