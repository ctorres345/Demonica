import 'package:demonica/app/providers.dart';
import 'package:demonica/design_system/theme.dart';
import 'package:demonica/features/planner/planner_screen.dart';
import 'package:demonica/features/planner/planner_store.dart';
import 'package:demonica/features/saved/saved_model.dart';
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

  Future<void> runPlanner(WidgetTester tester, ProviderContainer c) =>
      tester.runAsync(() => c.read(plannerProvider.notifier).run());

  group('saved plans', () {
    const step = SavedStep(
      result: 'Bilwis',
      ingredients: ['Melchom', 'Mokoi'],
      kind: RecipeKind.normal,
      macca: 1562,
      skills: ['Agi', 'Zio'],
      levelUps: {'Mokoi': 12},
    );

    test('skills and level-ups survive the file round trip', () {
      final e = SavedEntry.path([step]);
      final back = SavedFile.decode(SavedFile.encode([e])).items.single;
      expect(back.type, SavedType.path, reason: 'a one-step plan with skills stays a plan');
      expect(back.steps.single.skills, ['Agi', 'Zio']);
      expect(back.steps.single.levelUps, {'Mokoi': 12});
    });

    test('steps without planner fields are written as before', () {
      final json = SavedStep.fromRecipe(step.recipe, 10).toJson();
      expect(json.containsKey('skills'), isFalse);
      expect(json.containsKey('levelUps'), isFalse);
    });

    test('the same fusions keeping other skills are a different plan', () {
      final other = SavedStep(
        result: step.result,
        ingredients: step.ingredients,
        kind: step.kind,
        macca: step.macca,
        skills: const ['Agi'],
      );
      expect(SavedEntry.pathId([step]), isNot(SavedEntry.pathId([other])));
    });
  });

  testWidgets('the planner finds a plan and ticking a step saves it', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await loadData(tester, c);
    final planner = c.read(plannerProvider.notifier);

    planner.setTarget('Pixie');
    planner.addSkill('Agi');
    planner.addSkill('Zio');
    planner.addSkill('Dia');
    await runPlanner(tester, c);
    final s = c.read(plannerProvider);
    expect(s.result?.found, isTrue);
    expect(s.plan!.learnedByTarget, {'Dia': 0});

    // Changing an input clears the old result.
    planner.removeSkill('Dia');
    expect(c.read(plannerProvider).result, isNull);
    await runPlanner(tester, c);
    final plan = c.read(plannerProvider).plan!;

    final entry = SavedEntry.fromPlan(plan);
    expect(entry.steps.last.skills, containsAll(['Agi', 'Zio']));
    expect(entry.macca, plan.totalMacca);
  });

  testWidgets('the Plan screen shows steps, then explains a failure', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await loadData(tester, c);
    tester.view
      ..physicalSize = const Size(900, 2000)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(theme: demonicaTheme(Brightness.dark), home: const PlannerScreen()),
      ),
    );
    await tester.pump();
    expect(find.text('PICK A DEMON'), findsOneWidget);

    c.read(plannerProvider.notifier)
      ..setTarget('Pixie')
      ..addSkill('Agi');
    await runPlanner(tester, c);
    await tester.pump();
    expect(find.text('STEP 1'), findsOneWidget);
    expect(find.textContaining('Total'), findsOneWidget);

    // Ticking a step saves the plan with that step done.
    await tester.ensureVisible(find.byType(Checkbox).first);
    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();
    final saved = c.read(savedProvider).single;
    expect(saved.type, SavedType.path);
    expect(saved.steps.first.done, isTrue);

    c.read(plannerProvider.notifier).addSkill('Lightning of God');
    await runPlanner(tester, c);
    await tester.pump();
    expect(find.text('No plan found'), findsOneWidget);
    expect(find.textContaining('unique skill'), findsOneWidget);
  });

  testWidgets('a link fills the inputs and runs the search', (tester) async {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    await loadData(tester, c);
    await tester.runAsync(
      () => c.read(plannerProvider.notifier).openLink('pixie', 'Agi, Zio,Not A Skill'),
    );
    final s = c.read(plannerProvider);
    expect(s.target, 'Pixie');
    expect(s.skills, ['Agi', 'Zio']);
    expect(s.result?.found, isTrue);
  });
}
