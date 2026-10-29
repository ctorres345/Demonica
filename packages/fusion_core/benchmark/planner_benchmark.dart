// Times the skill planner on the real SMT IV data and prints the cheapest
// plan for each case. Run from packages/fusion_core:
//
//   dart run benchmark/planner_benchmark.dart
import 'dart:io';

import 'package:fusion_core/fusion_core.dart';

void main() {
  final dir = Directory('../../assets/data/smt4');
  String read(String f) => File('${dir.path}/$f').readAsStringSync();
  final data = GameData.fromJsonStrings(
    meta: read('meta.json'),
    demons: read('demons.json'),
    skills: read('skills.json'),
    fusionChart: read('fusion_chart.json'),
    elementChart: read('element_chart.json'),
    unlocks: read('unlocks.json'),
  );
  final rules = Smt4Rules(data);
  final cases = [
    ('Scathach', ['Mediarama']),
    ('Pixie', ['Agi', 'Zio', 'Dia']),
    ('Cu Chulainn', ['Mabufula', 'Mediarama', 'Life Bonus']),
    ('Lilith', ['Mamudoon', 'Mazionga', 'Mediarama']),
    ('Thor', ['Megidolaon', 'Victory Cry']),
    ('Mot', ['Mediarahan', 'Repel Phys', 'Mamudoon', 'Concentrate', 'Life Bonus', 'Mana Bonus']),
    ('Pixie', ['Mediarahan', 'Repel Phys', 'Mamudoon', 'Concentrate', 'Life Bonus', 'Mana Bonus']),
  ];
  for (final (target, wanted) in cases) {
    final sw = Stopwatch()..start();
    final r = Planner(rules, settings: data.defaultSettings).plan(data.demon(target), wanted);
    stdout.writeln('$target + ${wanted.join(', ')}: ${sw.elapsedMilliseconds} ms');
    if (!r.found) {
      stdout.writeln('  no plan: ${r.failure}');
      continue;
    }
    final p = r.plans.first;
    for (final s in p.steps) {
      final lv = s.levelUps.entries.map((e) => ' (level ${e.key} to ${e.value})').join();
      stdout.writeln(
        '  ${s.ingredients.join(' x ')} -> ${s.result}, keep ${s.skillsToPick.join(', ')}$lv',
      );
    }
    stdout.writeln('  total ${p.totalMacca} macca');
  }
}
