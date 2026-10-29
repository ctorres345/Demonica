import 'package:demonica/app/providers.dart';
import 'package:demonica/design_system/components.dart';
import 'package:demonica/design_system/theme.dart';
import 'package:demonica/design_system/tokens.dart';
import 'package:demonica/features/compendium/demon_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion_core/fusion_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Asset loading is real I/O, so it has to run outside the test's fake clock.
  Future<GameData> loadData(WidgetTester tester, ProviderContainer c) async {
    final data = await tester.runAsync(() => c.read(gameDataProvider.future));
    // Let the settings notifier pick up its defaults.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    return data!;
  }

  testWidgets('bundled data loads and the detail screen renders Lilith', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final data = await loadData(tester, container);
    expect(data.demons['Lilith'], isNotNull);
    expect(data.demons.length, 454);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: demonicaTheme(Brightness.dark),
          home: const DemonDetailScreen(demonId: 'lilith'),
        ),
      ),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Lilith'), findsWidgets);
    expect(find.text('Lullaby'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('OPEN RECIPE TREE'),
      200,
      scrollable: find
          .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
          .first,
    );
    expect(find.text('OPEN RECIPE TREE'), findsOneWidget);
    expect(find.textContaining('Black Maria'), findsWidgets);

    // Forward fusions live in their own tab.
    await tester.tap(find.textContaining('USED IN'));
    await tester.pumpAndSettle();
    expect(find.textContaining('fusions use Lilith'), findsOneWidget);
    expect(find.text('Lowest result first'), findsOneWidget);
  });

  testWidgets('filtered demons react to the skill filter', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await loadData(tester, container);

    container.read(compendiumFilterProvider.notifier).setSkill('Mediarahan');
    final list = container.read(filteredDemonsProvider);
    expect(list, isNotEmpty);
    expect(list.every((d) => d.skills.any((s) => s.name == 'Mediarahan')), isTrue);
  });

  testWidgets('changing the palette does not recompute recipes', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await loadData(tester, container);

    final before = container.read(recipesProvider('Lilith'));
    final usedBefore = container.read(usedInProvider('Lilith'));
    expect(before, isNotEmpty);
    container.read(settingsProvider.notifier).setPalette(Palette.smt4, mode: ThemeMode.light);
    expect(identical(container.read(recipesProvider('Lilith')), before), isTrue);
    expect(identical(container.read(usedInProvider('Lilith')), usedBefore), isTrue);

    // Turning a demon off does recompute.
    container.read(settingsProvider.notifier).setDemonsEnabled(['Pixie'], false);
    expect(identical(container.read(recipesProvider('Lilith')), before), isFalse);
  });

  test('macca formatting groups thousands', () {
    expect(macca(36710), '36 710 ¥');
    expect(macca(587), '587 ¥');
  });
}
