import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';
import 'otp_verification_screen.dart';

class PhoneSignInScreen extends ConsumerStatefulWidget {
  const PhoneSignInScreen({super.key});

  @override
  ConsumerState<PhoneSignInScreen> createState() => _PhoneSignInScreenState();
}

class _PhoneSignInScreenState extends ConsumerState<PhoneSignInScreen> {
  final TextEditingController _phoneController = TextEditingController();
  String _selectedCountryCode = '+91';
  String _selectedCountryName = 'India';
  String _selectedCountryFlag = '🇮🇳';
  bool _isLoading = false;
  String? _errorMessage;

  final List<Map<String, String>> _countries = const [
    {'code': '+91', 'name': 'India', 'flag': '🇮🇳'},
    {'code': '+1', 'name': 'United States', 'flag': '🇺🇸'},
    {'code': '+44', 'name': 'United Kingdom', 'flag': '🇬🇧'},
    {'code': '+971', 'name': 'United Arab Emirates', 'flag': '🇦🇪'},
    {'code': '+65', 'name': 'Singapore', 'flag': '🇸🇬'},
    {'code': '+60', 'name': 'Malaysia', 'flag': '🇲🇾'},
    {'code': '+61', 'name': 'Australia', 'flag': '🇦🇺'},
    {'code': '+1', 'name': 'Canada', 'flag': '🇨🇦'},
    {'code': '+49', 'name': 'Germany', 'flag': '🇩🇪'},
    {'code': '+33', 'name': 'France', 'flag': '🇫🇷'},
    {'code': '+81', 'name': 'Japan', 'flag': '🇯🇵'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return ListView.builder(
          itemCount: _countries.length,
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemBuilder: (context, index) {
            final country = _countries[index];
            final isSelected = country['code'] == _selectedCountryCode &&
                country['name'] == _selectedCountryName;
            return ListTile(
              leading:
                  Text(country['flag']!, style: const TextStyle(fontSize: 24)),
              title: Text(country['name']!,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  )),
              trailing: Text(country['code']!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.primaryAccent,
                    fontWeight: FontWeight.w600,
                  )),
              onTap: () {
                setState(() {
                  _selectedCountryCode = country['code']!;
                  _selectedCountryName = country['name']!;
                  _selectedCountryFlag = country['flag']!;
                });
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }

  Future<void> _handleSendOtp() async {
    final rawNumber = _phoneController.text.trim();
    if (rawNumber.isEmpty || rawNumber.length < 7) {
      setState(() {
        _errorMessage = 'Please enter a valid phone number';
      });
      return;
    }

    final fullPhoneNumber = '$_selectedCountryCode$rawNumber';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final auth = ref.read(authServiceProvider);

    await auth.sendPhoneOtp(
      fullPhoneNumber,
      onCodeSent: (verificationId, resendToken) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OtpVerificationScreen(
                phoneNumber: fullPhoneNumber,
                verificationId: verificationId,
                resendToken: resendToken,
              ),
            ),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = error;
          });
        }
      },
    );
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
                'Enter Phone Number',
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'We will send a 6-digit verification code via SMS to verify your account.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
              const SizedBox(height: 32),

              // Country Code & Phone Input Field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    // Country selector
                    InkWell(
                      onTap: _showCountryPicker,
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        child: Row(
                          children: [
                            Text(_selectedCountryFlag,
                                style: const TextStyle(fontSize: 20)),
                            const SizedBox(width: 6),
                            Text(
                              _selectedCountryCode,
                              style: AppTypography.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18, color: AppColors.secondaryText),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: AppColors.divider,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Phone number',
                          hintStyle: AppTypography.bodyMedium.copyWith(
                            color: AppColors.tertiaryText,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                        ),
                      ),
                    ),
                  ],
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
                  onPressed: _isLoading ? null : _handleSendOtp,
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
                          'Send Verification Code',
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
