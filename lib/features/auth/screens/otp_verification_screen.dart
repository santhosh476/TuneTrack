import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import '../../onboarding/screens/language_onboarding_screen.dart';

class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String phoneNumber;
  final String verificationId;
  final int? resendToken;

  const OtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.verificationId,
    this.resendToken,
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  late String _activeVerificationId;
  bool _isLoading = false;
  String? _errorMessage;

  // 60-Second Countdown Timer
  Timer? _timer;
  int _countdownSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _activeVerificationId = widget.verificationId;
    _startCountdown();
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _countdownSeconds = 60;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdownSeconds > 0) {
        setState(() {
          _countdownSeconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _handleResendOtp() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = ref.read(authServiceProvider);

    await auth.sendPhoneOtp(
      widget.phoneNumber,
      onCodeSent: (newVerId, _) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _activeVerificationId = newVerId;
          });
          _startCountdown();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('A new 6-digit code has been sent.'),
              backgroundColor: AppColors.primaryAccent,
            ),
          );
        }
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = err;
          });
        }
      },
    );
  }

  Future<void> _handleVerifyOtp() async {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit verification code';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final auth = ref.read(authServiceProvider);
      await auth.verifyPhoneOtp(
        verificationId: _activeVerificationId,
        smsCode: code,
      );

      final prefs = ref.read(sharedPreferencesServiceProvider);
      await prefs.setOnboardingCompleted(true);

      if (!mounted) return;

      if (!prefs.isLanguageOnboardingCompleted()) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const LanguageOnboardingScreen(),
          ),
          (route) => false,
        );
      } else {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify Phone Number',
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to ${widget.phoneNumber}',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 32),

              // OTP Input Field
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: AppTypography.displaySmall.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 14.0,
                    color: AppColors.primaryAccent,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    hintText: '••••••',
                    hintStyle: TextStyle(
                      color: AppColors.tertiaryText,
                      letterSpacing: 14.0,
                    ),
                  ),
                  onChanged: (val) {
                    if (val.length == 6) {
                      _handleVerifyOtp();
                    }
                  },
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
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

              const SizedBox(height: 24),

              // Countdown / Resend Option
              Center(
                child: _canResend
                    ? TextButton.icon(
                        onPressed: _handleResendOtp,
                        icon: const Icon(Icons.refresh_rounded,
                            size: 18, color: AppColors.primaryAccent),
                        label: Text(
                          'Resend Verification Code',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primaryAccent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : Text(
                        'Resend code in 00:${_countdownSeconds.toString().padLeft(2, '0')}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.secondaryText,
                        ),
                      ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(26),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleVerifyOtp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          'Verify & Continue',
                          style: AppTypography.titleSmall.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
