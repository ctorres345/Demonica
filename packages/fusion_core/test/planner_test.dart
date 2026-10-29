import 'package:fusion_core/fusion_core.dart';
import 'package:test/test.dart';

import 'smt4_rules_test.dart' show loadSmt4;

void main() {
  final data = loadSmt4();
  final rules = Smt4Rules(data);
  final settings = data.defaultSettings;
  Planner planner() => Planner(rules, settings: settings);

  /// Replays [plan] step by step, the way a player would, and fails on
  /// anything the game would not allow.
  void expectPlayable(Plan plan, List<String> wanted) {
    // Skills each demon holds when it is used as an ingredient.
    final made = <String, Set<String>>{};
    Set<String> holds(String name, int levelTo) => {
      ...?made[name],
      for (final l in data.demon(name).skills)
        if (l.innate || l.level <= levelTo) l.name,
    };
    for (final s in plan.steps) {
      expect(rules.reverseRecipes(data.demon(s.result), settings), contains(s.recipe));
      final pool = {for (final i in s.ingredients) ...holds(i, s.levelUps[i] ?? 0)};
      for (final k in s.skillsToPick) {
        expect(pool, contains(k), reason: '${s.result} cannot inherit $k from ${s.ingredients}');
        expect(rules.canInherit(data.skill(k)), isTrue);
      }
      final result = data.demon(s.result);
      final extra = s.skillsToPick.where((k) => !result.skills.any((l) => l.name == k));
      expect(extra.length, lessThanOrEqualTo(rules.freeSkillSlots(result)));
      for (final i in s.ingredients) {
        expect(data.demon(i).isEnemyOnly, isFalse);
      }
      made[s.result] = {...s.skillsToPick};
    }
    expect(plan.steps.last.result, plan.target);
    final end = {...plan.steps.last.skillsToPick, ...plan.learnedByTarget.keys};
    expect(end, containsAll(wanted));
  }

  test('a skill the target knows needs no inheritance', () {
    final r = planner().plan(data.demon('Pixie'), ['Dia']);
    expect(r.found, isTrue);
    expect(r.plans.first.learnedByTarget, {'Dia': 0});
    expect(r.plans.first.steps.last.skillsToPick, isEmpty);
  });

  test('skills learned by leveling are reported with their level', () {
    final r = planner().plan(data.demon('Pixie'), ['Mazan']);
    expect(r.plans.first.learnedByTarget, {'Mazan': 10});
  });

  test('unique skills are refused', () {
    final r = planner().plan(data.demon('Pixie'), ['Lightning of God', 'Agi']);
    expect(r.failure, PlanFailure.uniqueSkill);
    expect(r.failedSkills, ['Lightning of God']);
  });

  test('more skills than free slots are refused', () {
    final trumpeter = data.demon('Trumpeter');
    expect(rules.freeSkillSlots(trumpeter), 4);
    final r = planner().plan(trumpeter, ['Agi', 'Bufu', 'Zio', 'Zan', 'Dia']);
    expect(r.failure, PlanFailure.notEnoughSlots);
    expect(r.freeSlots, 4);
  });

  test('fusion accidents cannot be planned', () {
    expect(planner().plan(data.demon('Yoshitsune'), ['Agi']).failure, PlanFailure.notFusable);
  });

  test('the depth limit is reported when no chain is short enough', () {
    final r = Planner(
      rules,
      settings: settings,
      maxDepth: 1,
    ).plan(data.demon('Jack Frost'), ['Mediarahan']);
    expect(r.failure, PlanFailure.depthLimit);
  });

  final cases = <(String, List<String>)>[
    ('Scathach', ['Mediarama']),
    ('Pixie', ['Agi', 'Zio', 'Dia']),
    ('Cu Chulainn', ['Mabufula', 'Mediarama', 'Life Bonus']),
    ('Lilith', ['Mamudoon', 'Mazionga', 'Mediarama']),
    ('Jack Frost', ['Agi']),
    ('Thor', ['Megidolaon', 'Victory Cry']),
    ('Mot', ['Mediarahan', 'Repel Phys', 'Concentrate']),
  ];
  for (final (target, wanted) in cases) {
    test('$target with ${wanted.join(', ')} is playable', () {
      final r = planner().plan(data.demon(target), wanted);
      expect(r.found, isTrue, reason: '${r.failure}');
      expect(r.plans.length, lessThanOrEqualTo(3));
      for (final p in r.plans) {
        expectPlayable(p, wanted);
      }
      // Cheapest first, and the total is what the steps say.
      final totals = [for (final p in r.plans) p.totalMacca];
      expect(totals, orderedEquals([...totals]..sort()));
      expect(r.plans.first.totalMacca, r.plans.first.steps.fold(0, (a, s) => a + s.macca));
    });
  }

  test('each step pays only for ingredients no earlier step makes', () {
    final r = planner().plan(data.demon('Cu Chulainn'), ['Mabufula', 'Mediarama', 'Life Bonus']);
    final made = <String>{};
    for (final s in r.plans.first.steps) {
      final bought = s.ingredients.where((i) => !made.contains(i));
      expect(s.macca, bought.fold(0, (a, i) => a + data.demon(i).price));
      made.add(s.result);
    }
  });

  test('with level-ups off, every skill comes from innate skills', () {
    final r = Planner(
      rules,
      settings: settings,
      allowLevelUps: false,
    ).plan(data.demon('Cu Chulainn'), ['Mabufula', 'Mediarama', 'Life Bonus']);
    expect(r.found, isTrue);
    for (final s in r.plans.first.steps) {
      expect(s.levelUps, isEmpty);
    }
    expectPlayable(r.plans.first, ['Mabufula', 'Mediarama', 'Life Bonus']);
  });

  test('fusion accidents are never ingredients', () {
    final r = planner().plan(data.demon('Thor'), ['Megidolaon', 'Victory Cry']);
    for (final p in r.plans) {
      for (final s in p.steps) {
        for (final i in s.ingredients) {
          expect(data.demon(i).fusion, isNot(FusionKind.accident));
        }
      }
    }
  });
}
