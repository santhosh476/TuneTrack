import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/custom_button.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Welcome back to TuneTrack!')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e
            .toString()
            .replaceAll('Exception: ', '')
            .replaceAll('[null] ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.music_note_rounded,
                      size: 40, color: Colors.black),
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text(
                  'Sign In to TuneTrack',
                  style: AppTypography.displayMedium
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Synchronize your listening history, playlists & stats across devices',
                  style: AppTypography.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error),
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
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: AppTypography.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                style: AppTypography.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (context) => const ForgotPasswordScreen()),
                    );
                  },
                  child: Text(
                    'Forgot Password?',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.primaryAccent),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Sign In',
                width: double.infinity,
                isLoading: _isLoading,
                onPressed: _handleLogin,
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Don\'t have an account?',
                        style: AppTypography.bodyMedium),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: Text(
                        'Register',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.primaryAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
