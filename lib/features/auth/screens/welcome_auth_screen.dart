import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../onboarding/screens/language_onboarding_screen.dart';
import 'login_screen.dart';
import 'phone_sign_in_screen.dart';

class WelcomeAuthScreen extends ConsumerStatefulWidget {
  const WelcomeAuthScreen({super.key});

  @override
  ConsumerState<WelcomeAuthScreen> createState() => _WelcomeAuthScreenState();
}

class _WelcomeAuthScreenState extends ConsumerState<WelcomeAuthScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGuestEntry() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInAsGuest();

      final prefs = ref.read(sharedPreferencesServiceProvider);
      await prefs.setOnboardingCompleted(true);

      if (!mounted) return;

      // Navigate to Language Personalization
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const LanguageOnboardingScreen(),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to continue as guest: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithGoogle(
        displayName: 'TuneTrack Google User',
        email: 'user@gmail.com',
      );

      final prefs = ref.read(sharedPreferencesServiceProvider);
      await prefs.setOnboardingCompleted(true);

      if (!mounted) return;

      // Check if language onboarding is completed
      if (!prefs.isLanguageOnboardingCompleted()) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const LanguageOnboardingScreen(),
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Google Sign-In failed: $e';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToPhoneSignIn() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const PhoneSignInScreen(),
      ),
    );
  }

  void _navigateToEmailSignIn() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo & App Branding
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppColors.greenGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryAccent.withValues(alpha: 0.35),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.music_note_rounded,
                  size: 48,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),

              Text(
                'TuneTrack',
                style: AppTypography.displayLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              Text(
                'Millions of songs, offline tracks, and smart analytics tailored in your language.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.4,
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySmall
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(flex: 3),

              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryAccent,
                  ),
                )
              else ...[
                // 1. Continue with Phone Number
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: _navigateToPhoneSignIn,
                    icon: const Icon(Icons.phone_iphone_rounded, size: 20),
                    label: Text(
                      'Continue with Phone Number',
                      style: AppTypography.titleSmall.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 2. Continue with Google
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.primaryText,
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                      ),
                    ),
                    onPressed: _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata_rounded,
                        size: 28, color: Colors.white),
                    label: Text(
                      'Continue with Google',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // 3. Continue as Guest
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: AppColors.primaryText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(26),
                        side: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onPressed: _handleGuestEntry,
                    icon: const Icon(Icons.person_outline_rounded,
                        size: 20, color: AppColors.secondaryText),
                    label: Text(
                      'Continue as Guest',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.primaryText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Email login alternative
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Have an email account? ',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.secondaryText),
                    ),
                    GestureDetector(
                      onTap: _navigateToEmailSignIn,
                      child: Text(
                        'Log in',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 16),
              Text(
                'By continuing, you agree to TuneTrack Terms & Privacy Policy.',
                textAlign: TextAlign.center,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.tertiaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
