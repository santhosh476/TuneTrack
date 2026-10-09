import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_application_1/app/app.dart';
import 'package:flutter_application_1/core/providers.dart';

void main() {
  testWidgets('TuneTrack renders navigation tabs and switches cleanly',
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

    // Verify 5 Navigation Tabs exist
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Search'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Insights'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    // Verify Home content
    expect(find.text('Daily Listening Goal'), findsOneWidget);
    expect(find.text('Featured & Trending'), findsOneWidget);

    // Switch to Search Tab
    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Explore Genres & Moods'), findsOneWidget);

    // Switch to Library Tab
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Liked Songs'), findsWidgets);

    // Switch to Insights Tab
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Listening Time'), findsOneWidget);
    expect(find.text('Valid Plays'), findsOneWidget);

    // Switch to Profile Tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Listening Preferences'), findsOneWidget);
  });
}
