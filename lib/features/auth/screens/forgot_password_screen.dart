import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../../core/widgets/custom_button.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    setState(() => _isLoading = true);
    try {
      final auth = ref.read(authServiceProvider);
      await auth.sendPasswordResetEmail(_emailController.text.trim());
      setState(() => _emailSent = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reset Password',
                style: AppTypography.displayMedium
                    .copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your registered email address and we will send password reset instructions.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 24),
              if (_emailSent)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: AppColors.success),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Password reset instructions sent to ${_emailController.text}!',
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: AppTypography.bodyLarge,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Send Reset Link',
                  width: double.infinity,
                  isLoading: _isLoading,
                  onPressed: _handleReset,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
