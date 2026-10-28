import 'package:demonica/app/providers.dart';
import 'package:demonica/design_system/components.dart';
import 'package:demonica/design_system/theme.dart';
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
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('OPEN RECIPE TREE'), findsOneWidget);
    expect(find.textContaining('Black Maria'), findsWidgets);
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

  test('macca formatting groups thousands', () {
    expect(macca(36710), '36 710 ¥');
    expect(macca(587), '587 ¥');
  });
}
