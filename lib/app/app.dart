import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme/app_theme.dart';
import '../app/theme/app_colors.dart';
import '../core/providers.dart';
import '../features/auth/screens/welcome_auth_screen.dart';
import '../features/onboarding/screens/language_onboarding_screen.dart';
import '../features/home/screens/home_screen.dart';
import '../features/search/screens/search_screen.dart';
import '../features/library/screens/library_screen.dart';
import '../features/stats/screens/stats_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/player/widgets/mini_player.dart';

class TuneTrackApp extends ConsumerWidget {
  const TuneTrackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialize the active listening tracker
    ref.watch(listeningTrackerServiceProvider);

    final prefs = ref.watch(sharedPreferencesServiceProvider);
    final isOnboardingCompleted = prefs.isOnboardingCompleted();
    final isLanguageOnboardingCompleted = prefs.isLanguageOnboardingCompleted();

    Widget homeWidget;
    if (!isOnboardingCompleted) {
      homeWidget = const WelcomeAuthScreen();
    } else if (!isLanguageOnboardingCompleted) {
      homeWidget = const LanguageOnboardingScreen();
    } else {
      homeWidget = const MainNavigationShell();
    }

    return MaterialApp(
      title: 'TuneTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: homeWidget,
    );
  }
}

class MainNavigationShell extends StatefulWidget {
  const MainNavigationShell({super.key});

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
    StatsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBackground,
      body: Stack(
        children: [
          // 1. Active Tab Content
          IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),

          // 2. Persistent Floating MiniPlayer above bottom navigation
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: AppColors.bottomNavBackground,
        selectedItemColor: AppColors.primaryAccent,
        unselectedItemColor: AppColors.secondaryText,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            activeIcon: Icon(Icons.home_filled, color: AppColors.primaryAccent),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            activeIcon:
                Icon(Icons.search_rounded, color: AppColors.primaryAccent),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_music_outlined),
            activeIcon: Icon(Icons.library_music_rounded,
                color: AppColors.primaryAccent),
            label: 'Library',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_outlined),
            activeIcon:
                Icon(Icons.insights_rounded, color: AppColors.primaryAccent),
            label: 'Insights',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon:
                Icon(Icons.person_rounded, color: AppColors.primaryAccent),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
