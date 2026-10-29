import 'package:demonica/app/providers.dart';
import 'package:demonica/design_system/theme.dart';
import 'package:demonica/features/compendium/demon_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Asset loading is real I/O, so it has to run outside the test's fake clock.
  Future<void> load(WidgetTester tester, ProviderContainer c) async {
    await tester.runAsync(() async {
      await c.read(gameDataProvider.future);
      await c.read(locationsProvider.future);
      // Let the settings notifier pick up its defaults.
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  }

  Future<void> pumpDemon(WidgetTester tester, ProviderContainer c, String id) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          theme: demonicaTheme(Brightness.dark),
          home: DemonDetailScreen(demonId: id),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> scrollTo(WidgetTester tester, Finder f) => tester.scrollUntilVisible(
    f,
    200,
    scrollable: find.descendant(of: find.byType(ListView), matching: find.byType(Scrollable)).first,
  );

  testWidgets('demon page lists recruit areas and hides late-game ones', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await load(tester, c);

    // Hel is in Roppongi (late Tokyo) and Blasted Tokyo (spoiler).
    await pumpDemon(tester, c, 'hel');
    await scrollTo(tester, find.text('Roppongi'));
    expect(find.text('WHERE TO FIND'), findsOneWidget);
    expect(find.text('Roppongi'), findsOneWidget);
    expect(find.text('Blasted Tokyo'), findsNothing);
    expect(find.textContaining('1 late-game area hidden'), findsOneWidget);

    c.read(settingsProvider.notifier).setShowSpoilers(true);
    await tester.pump();
    expect(find.text('Blasted Tokyo'), findsOneWidget);
    expect(find.textContaining('late-game area hidden'), findsNothing);
  });

  testWidgets('a fusion-only demon says to fuse it', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await load(tester, c);

    await pumpDemon(tester, c, 'lilith');
    await scrollTo(tester, find.textContaining('Not found in the wild'));
    expect(find.textContaining('Not found in the wild'), findsOneWidget);
  });

  testWidgets('recruit flag follows the spoiler setting', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await load(tester, c);

    expect(c.read(recruitableProvider), contains('Pixie'));
    // Chi You is only recruitable in Lucifer's Palace, a late-game area.
    expect(c.read(recruitableProvider), isNot(contains('Chi You')));
    c.read(settingsProvider.notifier).setShowSpoilers(true);
    expect(c.read(recruitableProvider), contains('Chi You'));
  });
}
