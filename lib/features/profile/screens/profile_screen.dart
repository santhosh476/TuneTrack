import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../auth/screens/welcome_auth_screen.dart';
import '../../onboarding/screens/language_onboarding_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final syncService = ref.watch(cloudSyncServiceProvider);
    final prefs = ref.watch(sharedPreferencesServiceProvider);
    final lastSync = prefs.getLastSyncTime();

    String providerLabel = 'Guest (Local Storage)';
    IconData providerIcon = Icons.person_outline_rounded;
    if (user.authProvider == 'google') {
      providerLabel = 'Google Account';
      providerIcon = Icons.g_mobiledata_rounded;
    } else if (user.authProvider == 'phone') {
      providerLabel = 'Verified Phone Number';
      providerIcon = Icons.phone_iphone_rounded;
    } else if (user.authProvider == 'email') {
      providerLabel = 'Email Account';
      providerIcon = Icons.email_outlined;
    }

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
                        : 'T',
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
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(providerIcon,
                              size: 14,
                              color: user.isGuest
                                  ? AppColors.warning
                                  : AppColors.primaryAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.isGuest
                                  ? providerLabel
                                  : (user.phoneNumber.isNotEmpty
                                      ? '${user.phoneNumber} ($providerLabel)'
                                      : '${user.email} ($providerLabel)'),
                              style: AppTypography.bodySmall.copyWith(
                                color: user.isGuest
                                    ? AppColors.warning
                                    : AppColors.secondaryText,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
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
                            builder: (context) => const WelcomeAuthScreen()),
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

          // 2. Music Language Personalization Section
          Text('Music Language Preferences',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.translate_rounded,
                      color: AppColors.primaryAccent),
                  title: Text('Preferred Languages',
                      style: AppTypography.bodyLarge),
                  subtitle: Text(
                    user.preferredLanguages.isNotEmpty
                        ? user.preferredLanguages.join(', ')
                        : 'Tamil, English',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.primaryAccent),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.secondaryText),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const LanguageOnboardingScreen(
                          isFromSettings: true,
                        ),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.star_outline_rounded,
                      color: Colors.amberAccent),
                  title:
                      Text('Primary Language', style: AppTypography.bodyLarge),
                  subtitle: Text(
                    user.primaryLanguage,
                    style: AppTypography.bodySmall,
                  ),
                  trailing: TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const LanguageOnboardingScreen(
                            isFromSettings: true,
                          ),
                        ),
                      );
                    },
                    child: const Text('Change'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Appearance & Theme
          Text('Appearance',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Material(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            child: Consumer(
              builder: (context, ref, _) {
                final themeMode = ref.watch(themeModeProvider);
                final isDarkMode = themeMode == ThemeMode.dark;
                return SwitchListTile(
                  secondary: Icon(
                    isDarkMode ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: isDarkMode ? AppColors.primaryAccent : Colors.orangeAccent,
                  ),
                  title: Text('Dark Theme', style: AppTypography.bodyLarge),
                  subtitle: Text(
                    isDarkMode
                        ? 'AMOLED dark theme enabled'
                        : 'Clean light theme enabled',
                    style: AppTypography.bodySmall,
                  ),
                  value: isDarkMode,
                  activeThumbColor: AppColors.primaryAccent,
                  onChanged: (_) {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // 4. Listening Preferences
          Text('Listening Goals & Habits',
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

          // 5. Integrations & Sync
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
                  leading: const Icon(Icons.smart_display_rounded,
                      color: Colors.redAccent),
                  title: Text('YouTube Data API v3',
                      style: AppTypography.bodyLarge),
                  subtitle: Text(
                      'Official video discovery, search & verified durations',
                      style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.secondaryText),
                  onTap: () => _showYouTubeApiKeyDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.music_note_rounded,
                      color: Color(0xFF1DB954)),
                  title: Text('Spotify Web API',
                      style: AppTypography.bodyLarge),
                  subtitle: Text(
                      'Official search, album art, 30s previews & app handoff',
                      style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.chevron_right_rounded,
                      color: AppColors.secondaryText),
                  onTap: () => _showSpotifyCredentialsDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.public_rounded,
                      color: AppColors.primaryAccent),
                  title: Text('Public Online Music Streams',
                      style: AppTypography.bodyLarge),
                  subtitle: Text(
                      'Direct HTTPS streams & Audius catalog • Always Active',
                      style: AppTypography.bodySmall),
                  trailing: const Icon(Icons.check_circle_rounded,
                      color: AppColors.primaryAccent, size: 20),
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

          // 5. Privacy & Data
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

  void _showYouTubeApiKeyDialog(BuildContext context, WidgetRef ref) {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Row(
          children: [
            Icon(Icons.smart_display_rounded, color: Colors.redAccent),
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
              'Enter your Google Cloud YouTube Data API v3 key to enable high-speed music search, exact durations, and official in-app video playback.',
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
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border)),
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
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () async {
              final key = textController.text.trim();
              if (key.isNotEmpty) {
                await secureStorage.saveCustomApiKey('youtube', key);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('YouTube API key updated successfully!')),
                  );
                }
              }
            },
            child:
                const Text('Save Key', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showSpotifyCredentialsDialog(BuildContext context, WidgetRef ref) {
    final secureStorage = ref.read(secureStorageServiceProvider);
    final clientIdController = TextEditingController();
    final clientSecretController = TextEditingController();

    secureStorage.getSpotifyClientId().then((id) {
      if (id != null) clientIdController.text = id;
    });
    secureStorage.getSpotifyClientSecret().then((secret) {
      if (secret != null) clientSecretController.text = secret;
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.secondaryBackground,
        title: const Row(
          children: [
            Icon(Icons.music_note_rounded, color: Color(0xFF1DB954)),
            SizedBox(width: 8),
            Text('Spotify Web API',
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter Spotify Developer Client ID and Secret to enable search across 100M+ tracks, albums, playlists, 30s previews, and handoff.',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 13),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: clientIdController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Client ID',
                  labelStyle: const TextStyle(color: AppColors.secondaryText),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: clientSecretController,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Client Secret',
                  labelStyle: const TextStyle(color: AppColors.secondaryText),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1DB954),
              foregroundColor: Colors.black,
            ),
            onPressed: () async {
              final clientId = clientIdController.text.trim();
              final clientSecret = clientSecretController.text.trim();
              if (clientId.isNotEmpty && clientSecret.isNotEmpty) {
                await secureStorage.saveSpotifyCredentials(
                  clientId: clientId,
                  clientSecret: clientSecret,
                );
                final auth = ref.read(spotifyAuthServiceProvider);
                final token = await auth.requestClientCredentialsToken(
                  clientId: clientId,
                  clientSecret: clientSecret,
                );
                final success = token != null;
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success
                          ? 'Spotify credentials verified and connected!'
                          : 'Spotify credentials saved. Ready for search!'),
                      backgroundColor: const Color(0xFF1DB954),
                    ),
                  );
                }
              }
            },
            child: const Text('Connect Spotify'),
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
