import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/spotify_constants.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/network_or_asset_image.dart';

class SpotifyConnectScreen extends ConsumerStatefulWidget {
  const SpotifyConnectScreen({super.key});

  @override
  ConsumerState<SpotifyConnectScreen> createState() =>
      _SpotifyConnectScreenState();
}

class _SpotifyConnectScreenState extends ConsumerState<SpotifyConnectScreen> {
  late final TextEditingController _clientIdController;
  final TextEditingController _authCodeController = TextEditingController();
  bool _isConnected = false;
  bool _isLoading = false;
  bool _isSyncing = false;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    final spotifyRepo = ref.read(spotifyRepositoryProvider);
    _clientIdController = TextEditingController(text: spotifyRepo.clientId);
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final spotifyRepo = ref.read(spotifyRepositoryProvider);
    final connected = await spotifyRepo.isConnected();
    Map<String, dynamic>? profile;
    if (connected) {
      profile = await spotifyRepo.getCurrentUserProfile();
    }
    if (mounted) {
      setState(() {
        _isConnected = connected;
        _userProfile = profile;
      });
    }
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _authCodeController.dispose();
    super.dispose();
  }

  Future<void> _launchSpotifyOAuthBrowser() async {
    final clientId = _clientIdController.text.trim().isEmpty
        ? SpotifyConstants.defaultClientId
        : _clientIdController.text.trim();

    final spotifyRepo = ref.read(spotifyRepositoryProvider);
    spotifyRepo.configureClientId(clientId);

    final authUrl =
        spotifyRepo.getAuthorizationUrl(SpotifyConstants.redirectUriMobile);

    try {
      final launched = await launchUrl(
        Uri.parse(authUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Could not open system browser automatically.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening Spotify authorization: $e')),
        );
      }
    }
  }

  Future<void> _exchangeCode() async {
    final codeInput = _authCodeController.text.trim();
    if (codeInput.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Please paste the authorization code or redirect callback URL')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final spotifyRepo = ref.read(spotifyRepositoryProvider);
      final clientId = _clientIdController.text.trim().isEmpty
          ? SpotifyConstants.defaultClientId
          : _clientIdController.text.trim();
      spotifyRepo.configureClientId(clientId);

      await spotifyRepo.handleAuthCode(
        codeInput,
        SpotifyConstants.redirectUriMobile,
      );

      final profile = await spotifyRepo.getCurrentUserProfile();

      setState(() {
        _isLoading = false;
        _isConnected = true;
        _userProfile = profile;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1DB954),
            content: Text(
                'Successfully authenticated with Spotify! Tokens secured.'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Authentication error: $e'),
          ),
        );
      }
    }
  }

  Future<void> _syncData() async {
    setState(() => _isSyncing = true);
    final spotifyRepo = ref.read(spotifyRepositoryProvider);
    final result = await spotifyRepo.syncSpotifyData();
    setState(() => _isSyncing = false);

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF1DB954),
            content: Text(
                'Synced ${result['playlistsCount']} playlists and ${result['tracksCount']} tracks from Spotify!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('Sync failed: ${result['message']}'),
          ),
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
        title: Text('Spotify Integration', style: AppTypography.titleLarge),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Hero Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1DB954), Color(0xFF121216)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF1DB954).withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.music_note_rounded,
                        color: Colors.white, size: 36),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _isConnected
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isConnected
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 14,
                            color: _isConnected
                                ? const Color(0xFF1DB954)
                                : Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _isConnected ? 'CONNECTED' : 'DISCONNECTED',
                            style: AppTypography.labelSmall.copyWith(
                              color: _isConnected
                                  ? const Color(0xFF1DB954)
                                  : Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Spotify Web API (PKCE Flow)',
                  style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Authenticate securely via official Spotify OAuth 2.0 PKCE. No client secrets are stored on your device.',
                  style:
                      AppTypography.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 2. Connected State View
          if (_isConnected) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_userProfile?['avatarUrl'] != null)
                        NetworkOrAssetImage(
                          imageUrl: _userProfile!['avatarUrl'] as String,
                          width: 52,
                          height: 52,
                          borderRadius: BorderRadius.circular(26),
                        )
                      else
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Color(0xFF1DB954),
                          child: Icon(Icons.person_rounded,
                              color: Colors.white, size: 28),
                        ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _userProfile?['displayName'] as String? ??
                                  'Spotify Account',
                              style: AppTypography.titleMedium
                                  .copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _userProfile?['email'] as String? ?? '',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (_userProfile?['product'] == 'premium')
                              ? const Color(0xFF1DB954).withValues(alpha: 0.2)
                              : Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: (_userProfile?['product'] == 'premium')
                                ? const Color(0xFF1DB954)
                                : Colors.white24,
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          (_userProfile?['product'] as String? ?? 'FREE')
                              .toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: (_userProfile?['product'] == 'premium')
                                ? const Color(0xFF1DB954)
                                : Colors.white70,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.divider),
                  Text('Granted Permissions:',
                      style: AppTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _buildScopeRow('Read user profile & email address'),
                  _buildScopeRow('Sync user playlists & saved tracks'),
                  _buildScopeRow('Access top artists & listening history'),
                  _buildScopeRow('Inspect & control Spotify Connect playback'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Sync Playlists & Saved Tracks Now',
              icon: Icons.sync_rounded,
              isLoading: _isSyncing,
              onPressed: _syncData,
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Disconnect Spotify Account',
              isOutlined: true,
              textColor: AppColors.error,
              onPressed: () async {
                await ref.read(spotifyRepositoryProvider).disconnect();
                if (!context.mounted) return;
                setState(() {
                  _isConnected = false;
                  _userProfile = null;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Disconnected Spotify account.')),
                );
              },
            ),
          ] else ...[
            // 3. Disconnected Configuration & Setup
            Text('Spotify Developer Setup',
                style: AppTypography.titleMedium
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'To connect your account, create an App on the Spotify Developer Dashboard with PKCE authorization.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),

            // Step-by-step Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildStepRow(
                    step: '1',
                    title: 'Create an App in Spotify Dashboard',
                    subtitle: 'Visit developer.spotify.com/dashboard',
                    trailing: IconButton(
                      icon: const Icon(Icons.open_in_new_rounded,
                          color: Color(0xFF1DB954), size: 20),
                      onPressed: () => launchUrl(
                        Uri.parse(SpotifyConstants.developerPortalUrl),
                        mode: LaunchMode.externalApplication,
                      ),
                    ),
                  ),
                  const Divider(height: 20, color: AppColors.divider),
                  _buildStepRow(
                    step: '2',
                    title: 'Add Android Redirect URI',
                    subtitle: SpotifyConstants.redirectUriMobile,
                    trailing: IconButton(
                      icon: const Icon(Icons.copy_rounded,
                          color: AppColors.primaryAccent, size: 20),
                      tooltip: 'Copy Redirect URI',
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(
                            text: SpotifyConstants.redirectUriMobile));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Redirect URI copied to clipboard!')),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 20, color: AppColors.divider),
                  _buildStepRow(
                    step: '3',
                    title: 'Enter Client ID below',
                    subtitle: 'From Basic Information in App Settings',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            TextField(
              controller: _clientIdController,
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Spotify Client ID',
                hintText: 'e.g. 3a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d',
                prefixIcon:
                    const Icon(Icons.key_rounded, color: Color(0xFF1DB954)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () => _clientIdController.clear(),
                ),
              ),
            ),
            const SizedBox(height: 16),

            CustomButton(
              text: 'Open Spotify Login (System Browser)',
              icon: Icons.open_in_browser_rounded,
              backgroundColor: const Color(0xFF1DB954),
              textColor: Colors.black,
              onPressed: _launchSpotifyOAuthBrowser,
            ),
            const SizedBox(height: 20),

            Text('Complete Login / Authorization Code',
                style: AppTypography.titleSmall
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(
              'After authorizing in the browser, paste the callback URL or authorization code here:',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 10),

            TextField(
              controller: _authCodeController,
              style: AppTypography.bodyLarge,
              decoration: InputDecoration(
                labelText: 'Authorization Code or Callback URL',
                hintText: 'tunetrack://spotify-auth-callback?code=AQD...',
                prefixIcon: const Icon(Icons.qr_code_rounded,
                    color: AppColors.primaryAccent),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste_rounded, size: 20),
                  tooltip: 'Paste from clipboard',
                  onPressed: () async {
                    final data = await Clipboard.getData('text/plain');
                    if (data?.text != null) {
                      _authCodeController.text = data!.text!;
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            CustomButton(
              text: 'Exchange Code & Connect',
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isLoading,
              onPressed: _exchangeCode,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String step,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: const Color(0xFF1DB954).withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF1DB954), width: 1),
          ),
          child: Center(
            child: Text(
              step,
              style: AppTypography.labelMedium.copyWith(
                  color: const Color(0xFF1DB954), fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.secondaryText)),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildScopeRow(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          const Icon(Icons.check_rounded, size: 16, color: Color(0xFF1DB954)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.primaryText)),
          ),
        ],
      ),
    );
  }
}
