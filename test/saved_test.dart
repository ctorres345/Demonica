import 'package:demonica/app/providers.dart';
import 'package:demonica/design_system/theme.dart';
import 'package:demonica/features/recipes/tree_state.dart';
import 'package:demonica/features/saved/saved_model.dart';
import 'package:demonica/features/saved/saved_screen.dart';
import 'package:demonica/features/saved/saved_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fusion_core/fusion_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<GameData> loadData(WidgetTester tester, ProviderContainer c) async {
    final data = await tester.runAsync(() => c.read(gameDataProvider.future));
    c.read(savedProvider);
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    return data!;
  }

  const nyxRecipe = Recipe(
    result: 'Lilith',
    ingredients: ['Nyx', 'Succubus'],
    kind: RecipeKind.normal,
  );

  group('SavedFile', () {
    test('round-trips entries with steps, notes and ticks', () {
      final e = SavedEntry.recipe(nyxRecipe, 1234).copyWith(note: 'for Mediarahan').withDone(true);
      final back = SavedFile.decode(SavedFile.encode([e])).items.single;
      expect(back.id, e.id);
      expect(back.type, SavedType.recipe);
      expect(back.note, 'for Mediarahan');
      expect(back.done, isTrue);
      expect(back.steps.single.done, isTrue);
      expect(back.steps.single.recipe, nyxRecipe);
      expect(back.macca, 1234);
    });

    test('rejects other files and newer versions', () {
      expect(() => SavedFile.decode('nope'), throwsFormatException);
      expect(() => SavedFile.decode('{"format":"other","version":1}'), throwsFormatException);
      expect(
        () => SavedFile.decode('{"format":"demonica.saved","version":99,"items":[]}'),
        throwsFormatException,
      );
    });

    test('skips broken entries and unknown demons', () {
      final good = SavedEntry.demon('Lilith').toJson();
      final unknown = SavedEntry.demon('Not A Demon').toJson();
      final text =
          '{"format":"demonica.saved","version":1,"items":[${_json(good)},${_json(unknown)},{"id":1}]}';
      final r = SavedFile.decode(text, knownDemon: (n) => n == 'Lilith');
      expect(r.items.map((e) => e.result), ['Lilith']);
      expect(r.skipped, 2);
    });

    test('ticking every step ticks the plan', () {
      final plan = SavedEntry.path([
        SavedStep.fromRecipe(
          const Recipe(result: 'Nyx', ingredients: ['A', 'B'], kind: RecipeKind.normal),
          10,
        ),
        SavedStep.fromRecipe(nyxRecipe, 5),
      ]);
      expect(plan.type, SavedType.path);
      expect(plan.macca, 15);
      final half = plan.withStepDone(0, true);
      expect(half.done, isFalse);
      expect(half.withStepDone(1, true).done, isTrue);
    });
  });

  testWidgets('the open tree path becomes a plan and back', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final data = await loadData(tester, c);
    final rules = c.read(rulesProvider)!;
    final settings = c.read(settingsProvider).fusion;

    // A normal-fusion target whose first ingredient has recipes of its own.
    final target = data.demonsByLevel.firstWhere(
      (d) =>
          d.level > 40 &&
          d.fusion == FusionKind.normal &&
          rules.reverseRecipes(d, settings).length > 1 &&
          rules
              .reverseRecipes(
                data.demon(rules.reverseRecipes(d, settings).first.ingredients.first),
                settings,
              )
              .isNotEmpty,
    );
    final root = target.name;
    final top = rules.reverseRecipes(target, settings).first;
    final ing = data.demon(top.ingredients.first);
    final sub = rules.reverseRecipes(ing, settings).first;

    final tree = c.read(treeExpansionProvider(root).notifier);
    tree.toggleRecipe(root, top);
    final topKey = TreeExpansion.recipeKey(root, top);
    final ingKey = TreeExpansion.childKey(topKey, ing.name);
    tree.toggleDemon(ingKey);
    tree.toggleRecipe(ingKey, sub);

    final steps = c.read(treeExpansionProvider(root)).plan(root, data);
    expect(steps.map((s) => s.result), [ing.name, root]);
    // The fused ingredient is not bought, so it is not counted.
    final other = top.ingredients.last;
    expect(steps.last.macca, data.demon(other).price);
    expect(steps.first.macca, rules.recipeCost(sub));

    // Opening a sibling recipe closes the first one and everything under it.
    final sibling = rules.reverseRecipes(target, settings).firstWhere((r) => r != top);
    tree.toggleRecipe(root, sibling);
    expect(c.read(treeExpansionProvider(root)).isOpen(topKey), isFalse);
    expect(c.read(treeExpansionProvider(root)).isOpen(ingKey), isFalse);

    // Restoring the saved steps reopens the same path.
    tree.showSteps(steps);
    final restored = c.read(treeExpansionProvider(root));
    expect(restored.isOpen(topKey), isTrue);
    expect(restored.isOpen(TreeExpansion.recipeKey(ingKey, sub)), isTrue);
    expect(restored.plan(root, data).map((s) => s.recipe), steps.map((s) => s.recipe));
  });

  testWidgets('bookmarks persist and import merges by id', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    final data = await loadData(tester, c);
    final saved = c.read(savedProvider.notifier);
    final rules = c.read(rulesProvider)!;
    final nyxRecipe = rules
        .reverseRecipes(data.demon('Lilith'), c.read(settingsProvider).fusion)
        .first;

    saved.toggleRecipe(nyxRecipe, 100);
    saved.toggleDemon('Lilith');
    expect(c.read(savedIdsProvider), contains(SavedEntry.recipeId(nyxRecipe)));
    saved.setNote(SavedEntry.demonId('Lilith'), '  later  ');
    expect(c.read(savedProvider).first.note, 'later');

    final file = saved.export();
    saved.toggleRecipe(nyxRecipe, 100);
    expect(c.read(savedProvider).length, 1);

    final r = saved.import(file);
    expect(r.added, 1);
    expect(r.updated, 1);
    expect(c.read(savedProvider).length, 2);

    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    final prefs = await tester.runAsync(SharedPreferences.getInstance);
    final stored = SavedFile.decode(prefs!.getString('demonica.saved.v1')!).items;
    expect(stored.length, 2);
  });

  testWidgets('Saved screen shows the empty state, then a plan with steps', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await loadData(tester, c);

    Future<void> pump() async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: c,
          child: MaterialApp(theme: demonicaTheme(Brightness.dark), home: const SavedScreen()),
        ),
      );
      await tester.pump();
    }

    await pump();
    expect(find.text('Nothing saved yet'), findsOneWidget);

    c
        .read(savedProvider.notifier)
        .add(
          SavedEntry.path([
            SavedStep.fromRecipe(
              const Recipe(result: 'Nyx', ingredients: ['Lilim', 'Pixie'], kind: RecipeKind.normal),
              300,
            ),
            SavedStep.fromRecipe(nyxRecipe, 200),
          ]),
        );
    await pump();
    expect(find.textContaining('Plan · 2 fusions · 0/2 done'), findsOneWidget);
    expect(find.textContaining('Total 500'), findsOneWidget);

    // Tick both steps; the plan ticks itself.
    final boxes = find.byType(Checkbox);
    expect(boxes, findsNWidgets(3));
    await tester.tap(boxes.at(1));
    await tester.pump();
    await tester.tap(find.byType(Checkbox).at(2));
    await tester.pump();
    expect(c.read(savedProvider).single.done, isTrue);
    expect(find.textContaining('2/2 done'), findsOneWidget);
  });
}

String _json(Map<String, dynamic> m) =>
    SavedFile.encode([SavedEntry.fromJson(m)])
        .split('"items":[')
        .last
        .replaceFirst(RegExp(r'\]\}$'), '');
