import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/custom_button.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.registerWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
      );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Account created! Guest history merged.')),
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
                child: Text(
                  'Create an Account',
                  style: AppTypography.displayMedium
                      .copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Your local playlists and listening streaks will be saved to your profile',
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
                  child: Text(_errorMessage!,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.error)),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: _nameController,
                style: AppTypography.bodyLarge,
                decoration: const InputDecoration(
                  labelText: 'Your Name / Nickname',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 16),
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
                  labelText: 'Password (min 6 characters)',
                  prefixIcon: Icon(Icons.lock_outline_rounded),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                text: 'Create Free Account',
                width: double.infinity,
                isLoading: _isLoading,
                onPressed: _handleRegister,
              ),
              const SizedBox(height: 16),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Already have an account?',
                        style: AppTypography.bodyMedium),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                              builder: (context) => const LoginScreen()),
                        );
                      },
                      child: Text(
                        'Sign In',
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
