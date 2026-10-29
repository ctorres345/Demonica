import 'package:demonica/app/providers.dart';
import 'package:demonica/design_system/components.dart';
import 'package:demonica/design_system/theme.dart';
import 'package:demonica/features/onboarding/tutorial_screen.dart';
import 'package:demonica/features/recipes/recipe_tree_screen.dart';
import 'package:demonica/features/recipes/tree_state.dart';
import 'package:demonica/features/saved/saved_model.dart';
import 'package:demonica/features/saved/saved_screen.dart';
import 'package:demonica/features/saved/saved_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion_core/fusion_core.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tests for the v1.1 polish stories: tree path strip (DEM-23), Saved ticks
/// (DEM-24), compendium sort and level input (DEM-25), tutorial story
/// question (DEM-26).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> container(WidgetTester tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await tester.runAsync(() => c.read(gameDataProvider.future));
    c.read(savedProvider);
    await tester.runAsync(() async {
      for (var i = 0; i < 40 && !c.read(settingsProvider).loaded; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    return c;
  }

  Widget app(ProviderContainer c, Widget home) => UncontrolledProviderScope(
    container: c,
    child: MaterialApp.router(
      theme: demonicaTheme(Brightness.dark),
      routerConfig: GoRouter(
        routes: [
          GoRoute(path: '/', builder: (_, _) => home),
          GoRoute(path: '/smt4/demons', builder: (_, _) => const SizedBox()),
        ],
      ),
    ),
  );

  testWidgets('compendium sorts by level, name or race', (tester) async {
    final c = await container(tester);
    List<Demon> list() => c.read(filteredDemonsProvider);
    final byLevel = list();
    for (var i = 1; i < byLevel.length; i++) {
      expect(byLevel[i - 1].level, lessThanOrEqualTo(byLevel[i].level));
    }

    c.read(compendiumFilterProvider.notifier).setSort(DemonSort.name);
    final names = list().map((d) => d.name.toLowerCase()).toList();
    expect(names, [...names]..sort());

    c.read(compendiumFilterProvider.notifier).setSort(DemonSort.race);
    final byRace = list();
    for (var i = 1; i < byRace.length; i++) {
      final (a, b) = (byRace[i - 1], byRace[i]);
      final cmp = a.race.compareTo(b.race);
      expect(cmp <= 0, isTrue, reason: '${a.race} before ${b.race}');
      if (cmp == 0) expect(a.level, lessThanOrEqualTo(b.level));
    }

    // Clearing filters keeps the chosen sort.
    c.read(compendiumFilterProvider.notifier).clearAll();
    expect(c.read(compendiumFilterProvider).sort, DemonSort.race);
  });

  testWidgets('level sheet takes -/+ taps and a typed level', (tester) async {
    int? picked = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: demonicaTheme(Brightness.dark),
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showLevelSheet(
              context,
              title: 'Level',
              help: 'help',
              current: 40,
              onChanged: (v) => picked = v,
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Level up'));
    await tester.pump();
    expect(picked, 41);
    await tester.tap(find.byTooltip('Level down'));
    await tester.tap(find.byTooltip('Level down'));
    await tester.pump();
    expect(picked, 39);

    await tester.enterText(find.byKey(const Key('level-field')), '72');
    await tester.pump();
    expect(picked, 72);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 72);

    // Letters are ignored and the level stays in range.
    await tester.enterText(find.byKey(const Key('level-field')), 'ab');
    await tester.pump();
    expect(picked, 72);
  });

  testWidgets('tree strip shows the open path and saves it', (tester) async {
    final c = await container(tester);
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(c, const RecipeTreeScreen(demonId: 'scathach')));
    await tester.pump();

    expect(find.textContaining('No recipe open yet'), findsOneWidget);
    expect(find.text('SAVE PATH'), findsNothing);

    final data = c.read(gameDataProvider).value!;
    final recipe = c.read(recipesProvider('Scathach')).first;
    c.read(treeExpansionProvider('Scathach').notifier).toggleRecipe('Scathach', recipe);
    await tester.pump();
    expect(find.text('Path: 1 step'), findsOneWidget);
    expect(data.demons['Scathach'], isNotNull);

    await tester.tap(find.text('SAVE PATH'));
    await tester.pump();
    expect(c.read(savedProvider).single.result, 'Scathach');
  });

  testWidgets('Saved steps tick only from the box or the text', (tester) async {
    final c = await container(tester);
    c
        .read(savedProvider.notifier)
        .add(
          SavedEntry.path([
            SavedStep.fromRecipe(
              const Recipe(result: 'Nyx', ingredients: ['Lilim', 'Pixie'], kind: RecipeKind.normal),
              300,
            ),
            SavedStep.fromRecipe(
              const Recipe(
                result: 'Lilith',
                ingredients: ['Nyx', 'Succubus'],
                kind: RecipeKind.normal,
              ),
              200,
            ),
          ]),
        );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: demonicaTheme(Brightness.dark), home: const SavedScreen()),
      ),
    );
    await tester.pump();

    // The step number is not a toggle.
    await tester.tap(find.text('1.'));
    await tester.pump();
    expect(c.read(savedProvider).single.steps.first.done, isFalse);

    // The step text is.
    await tester.tap(find.textContaining('Lilim (', findRichText: true));
    await tester.pump();
    expect(c.read(savedProvider).single.steps.first.done, isTrue);

    // Note and tree actions are visible buttons, not hidden in a menu.
    expect(find.text('Add note'), findsOneWidget);
    expect(find.text('Open in tree'), findsOneWidget);
  });

  testWidgets('tutorial asks if the player is early in the story', (tester) async {
    final c = await container(tester);
    tester.view.physicalSize = const Size(1200, 2400);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app(c, const TutorialScreen()));
    await tester.pump();
    for (var i = 1; i < tutorialPages.length; i++) {
      await tester.tap(find.byKey(const Key('tutorial-next')));
      await tester.pumpAndSettle();
    }

    final story = c
        .read(gameDataProvider)
        .value!
        .unlocks
        .firstWhere((u) => u.category == storyCategory);
    final demons = [for (final e in story.entries) ...e.demons];
    bool enabled(String d) => c.read(fusionSettingsProvider).isEnabled(d);
    expect(demons.every(enabled), isTrue);

    await tester.ensureVisible(find.byKey(const Key('story-early')));
    await tester.tap(find.byKey(const Key('story-early')));
    await tester.pump();
    expect(demons.any(enabled), isFalse);
    expect(tester.widget<ChoiceChip>(find.byKey(const Key('story-early'))).selected, isTrue);

    await tester.tap(find.byKey(const Key('story-late')));
    await tester.pump();
    expect(demons.every(enabled), isTrue);
  });
}
