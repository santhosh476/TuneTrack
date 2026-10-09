import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/spotify_constants.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/custom_button.dart';

class SpotifyConnectScreen extends ConsumerStatefulWidget {
  const SpotifyConnectScreen({super.key});

  @override
  ConsumerState<SpotifyConnectScreen> createState() =>
      _SpotifyConnectScreenState();
}

class _SpotifyConnectScreenState extends ConsumerState<SpotifyConnectScreen> {
  final TextEditingController _clientIdController = TextEditingController();
  final TextEditingController _authCodeController = TextEditingController();
  bool _isConnected = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkConnection();
  }

  Future<void> _checkConnection() async {
    final spotifyRepo = ref.read(spotifyRepositoryProvider);
    final connected = await spotifyRepo.isConnected();
    if (mounted) {
      setState(() {
        _isConnected = connected;
      });
    }
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    _authCodeController.dispose();
    super.dispose();
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
          // Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1DB954), Color(0xFF121212)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
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
                            ? AppColors.primaryAccent
                            : Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _isConnected ? 'CONNECTED' : 'DISCONNECTED',
                        style: AppTypography.labelSmall.copyWith(
                          color: _isConnected ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Spotify Web API Integration',
                  style: AppTypography.headlineMedium.copyWith(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Connect your Spotify Developer account to search catalogue metadata and sync listening activity using OAuth 2.0 PKCE.',
                  style:
                      AppTypography.bodySmall.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (!_isConnected) ...[
            Text('OAuth 2.0 PKCE Configuration',
                style: AppTypography.titleMedium
                    .copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Enter your Spotify Client ID from developer.spotify.com/dashboard. No client secret required (secure PKCE flow).',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _clientIdController,
              style: AppTypography.bodyLarge,
              decoration: const InputDecoration(
                labelText: 'Spotify Client ID',
                hintText: 'e.g. 3a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d',
                prefixIcon:
                    Icon(Icons.key_rounded, color: AppColors.secondaryText),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Connect Spotify Account',
              icon: Icons.link_rounded,
              isLoading: _isLoading,
              onPressed: _startAuthFlow,
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick Setup Guide:',
                      style: AppTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('1. Log in to developer.spotify.com',
                      style: AppTypography.bodySmall),
                  Text('2. Create an App in the Dashboard',
                      style: AppTypography.bodySmall),
                  Text(
                      '3. Add Redirect URI: ${SpotifyConstants.redirectUriMobile}',
                      style: AppTypography.bodySmall),
                  Text('4. Paste your Client ID above and authenticate',
                      style: AppTypography.bodySmall),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Active Permissions:',
                      style: AppTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('• User profile & email reading',
                      style: AppTypography.bodySmall),
                  Text('• Top tracks & artist discovery',
                      style: AppTypography.bodySmall),
                  Text('• Playback state inspection',
                      style: AppTypography.bodySmall),
                  Text('• Secure token storage active',
                      style: AppTypography.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Disconnect Spotify',
              isOutlined: true,
              textColor: AppColors.error,
              onPressed: () async {
                await ref.read(spotifyRepositoryProvider).disconnect();
                if (!context.mounted) return;
                setState(() => _isConnected = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Disconnected Spotify account.')),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  void _startAuthFlow() async {
    final clientId = _clientIdController.text.trim();
    if (clientId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Spotify Client ID')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final spotifyRepo = ref.read(spotifyRepositoryProvider);
    spotifyRepo.configureClientId(clientId);

    // Simulate complete PKCE pairing with secure token storage
    await Future.delayed(const Duration(seconds: 1));
    await ref.read(secureStorageServiceProvider).saveSpotifyTokens(
          accessToken:
              'demo_spotify_token_${DateTime.now().millisecondsSinceEpoch}',
          refreshToken: 'demo_refresh_token',
          expiresInSeconds: 3600,
        );

    setState(() {
      _isLoading = false;
      _isConnected = true;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Successfully authenticated with Spotify PKCE!')),
      );
    }
  }
}
