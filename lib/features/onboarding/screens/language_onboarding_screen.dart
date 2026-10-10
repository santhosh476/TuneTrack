import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/app.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/providers.dart';

class LanguageOnboardingScreen extends ConsumerStatefulWidget {
  final bool isFromSettings;

  const LanguageOnboardingScreen({
    super.key,
    this.isFromSettings = false,
  });

  @override
  ConsumerState<LanguageOnboardingScreen> createState() =>
      _LanguageOnboardingScreenState();
}

class _LanguageOnboardingScreenState
    extends ConsumerState<LanguageOnboardingScreen> {
  final Set<String> _selectedLanguages = {'Tamil', 'English'};
  String _primaryLanguage = 'Tamil';
  bool _isSaving = false;

  final List<Map<String, String>> _availableLanguages = const [
    {'name': 'Tamil', 'native': 'தமிழ்', 'gradient': '0xFF1DB954'},
    {'name': 'English', 'native': 'International', 'gradient': '0xFF6C5CE7'},
    {'name': 'Hindi', 'native': 'हिंदी', 'gradient': '0xFFFF7675'},
    {'name': 'Telugu', 'native': 'తెలుగు', 'gradient': '0xFFF7971E'},
    {'name': 'Malayalam', 'native': 'മലയാളം', 'gradient': '0xFF2193B0'},
    {'name': 'Kannada', 'native': 'ಕನ್ನಡ', 'gradient': '0xFF8E2DE2'},
    {'name': 'Punjabi', 'native': 'ਪੰਜਾਬੀ', 'gradient': '0xFFFF512F'},
    {'name': 'Bengali', 'native': 'বাংলা', 'gradient': '0xFF00B894'},
    {'name': 'Marathi', 'native': 'मराठी', 'gradient': '0xFFE17055'},
    {'name': 'Spanish', 'native': 'Español', 'gradient': '0xFF0984E3'},
    {'name': 'Korean', 'native': '한국어 (K-Pop)', 'gradient': '0xFFFD79A8'},
  ];

  @override
  void initState() {
    super.initState();
    _loadExistingPreferences();
  }

  void _loadExistingPreferences() {
    final prefs = ref.read(sharedPreferencesServiceProvider);
    final saved = prefs.getPreferredLanguages();
    if (saved.isNotEmpty) {
      setState(() {
        _selectedLanguages.clear();
        _selectedLanguages.addAll(saved);
        _primaryLanguage = prefs.getPrimaryLanguage();
      });
    }
  }

  void _toggleLanguage(String name) {
    setState(() {
      if (_selectedLanguages.contains(name)) {
        if (_selectedLanguages.length > 1) {
          _selectedLanguages.remove(name);
          if (_primaryLanguage == name) {
            _primaryLanguage = _selectedLanguages.first;
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please keep at least one preferred language.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        _selectedLanguages.add(name);
      }
    });
  }

  Future<void> _saveAndContinue({bool isSkipped = false}) async {
    setState(() {
      _isSaving = true;
    });

    final prefs = ref.read(sharedPreferencesServiceProvider);
    final auth = ref.read(authServiceProvider);

    final languages =
        isSkipped ? ['Tamil', 'English'] : _selectedLanguages.toList();
    final primary = isSkipped ? 'Tamil' : _primaryLanguage;

    await auth.updateUserLanguages(languages, primary);
    await prefs.setLanguageOnboardingCompleted(true);
    await prefs.setOnboardingCompleted(true);

    if (!mounted) return;

    if (widget.isFromSettings) {
      Navigator.of(context).pop(true);
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const MainNavigationShell(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: widget.isFromSettings,
        actions: [
          if (!widget.isFromSettings)
            TextButton(
              onPressed:
                  _isSaving ? null : () => _saveAndContinue(isSkipped: true),
              child: Text(
                'Skip',
                style: AppTypography.titleSmall.copyWith(
                  color: AppColors.secondaryText,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What music languages do you love?',
                style: AppTypography.displaySmall.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select one or more to personalize your dashboard, recommendations, and search results.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 20),

              // Language Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: _availableLanguages.length,
                  itemBuilder: (context, index) {
                    final item = _availableLanguages[index];
                    final name = item['name']!;
                    final native = item['native']!;
                    final isSelected = _selectedLanguages.contains(name);
                    final isPrimary = _primaryLanguage == name;

                    return GestureDetector(
                      onTap: () => _toggleLanguage(name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primaryAccent.withValues(alpha: 0.15)
                              : AppColors.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primaryAccent
                                : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    name,
                                    style: AppTypography.titleSmall.copyWith(
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? AppColors.primaryText
                                          : AppColors.secondaryText,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    native,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isSelected
                                          ? AppColors.primaryAccent
                                          : AppColors.tertiaryText,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                isPrimary
                                    ? Icons.star_rounded
                                    : Icons.check_circle_rounded,
                                color: AppColors.primaryAccent,
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Selected count indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selectedLanguages.length} languages selected',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_selectedLanguages.length > 1)
                    PopupMenuButton<String>(
                      color: AppColors.surfaceElevated,
                      onSelected: (val) {
                        setState(() {
                          _primaryLanguage = val;
                        });
                      },
                      itemBuilder: (context) {
                        return _selectedLanguages.map((lang) {
                          return PopupMenuItem(
                            value: lang,
                            child: Row(
                              children: [
                                Text(lang, style: AppTypography.bodyMedium),
                                const Spacer(),
                                if (_primaryLanguage == lang)
                                  const Icon(Icons.check,
                                      color: AppColors.primaryAccent, size: 18),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      child: Row(
                        children: [
                          Text(
                            'Primary: $_primaryLanguage',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primaryAccent,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color: AppColors.primaryAccent, size: 18),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Continue Button
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
                  onPressed: _isSaving ? null : () => _saveAndContinue(),
                  child: _isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          widget.isFromSettings
                              ? 'Save Preferences'
                              : 'Continue',
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
