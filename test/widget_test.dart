import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';

void main() {
  testWidgets(
      'TuneTrack shows WelcomeAuthScreen on first launch and handles guest flow',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TuneTrackApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Welcome Screen elements
    expect(find.text('TuneTrack'), findsOneWidget);
    expect(find.text('Continue as Guest'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Phone Number'), findsOneWidget);

    // Tap Continue as Guest
    await tester.tap(find.text('Continue as Guest'));
    await tester.pumpAndSettle();

    // Should navigate to Language Personalization Screen
    expect(find.text('What music languages do you love?'), findsOneWidget);
    expect(find.text('Tamil'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);

    // Tap Continue on Language Onboarding
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Should arrive at Main Navigation Dashboard
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets(
      'TuneTrack renders navigation tabs and switches cleanly when authenticated',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({
      'is_onboarding_completed': true,
      'is_language_onboarding_completed': true,
      'preferred_music_languages': ['Tamil', 'English'],
      'primary_music_language': 'Tamil',
    });
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const TuneTrackApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify 5 Navigation Tabs exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify Home content
    expect(find.text('Daily Listening Goal'), findsOneWidget);
    expect(find.text('Recommended for You'), findsOneWidget);

    // Switch to Search Tab
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Explore Genres & Music Hubs'), findsOneWidget);

    // Switch to Library Tab
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Liked Songs'), findsWidgets);

    // Switch to Favorites Tab
    await tester.tap(find.byIcon(Icons.favorite_border_rounded));
    await tester.pumpAndSettle();
    expect(find.text('Liked Songs'), findsWidgets);

    // Switch to Settings Tab
    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Music Language Preferences'), findsOneWidget);
    expect(find.text('Listening Goals & Habits'), findsOneWidget);
  });
}
