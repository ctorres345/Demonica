import 'dart:io';

import 'package:fusion_core/fusion_core.dart';
import 'package:test/test.dart';

import 'smt4_rules_test.dart' show loadSmt4;

void main() {
  final data = loadSmt4();
  final raw = File('../../assets/data/smt4/locations.json').readAsStringSync();
  final loc = LocationData.fromJsonString(raw);

  test('every encounter names a demon that exists', () {
    final unknown = [
      for (final e in loc.encounters)
        if (!data.demons.containsKey(e.demon)) e.demon,
    ];
    expect(unknown, isEmpty);
  });

  test('a demon is listed at most once per area', () {
    final keys = [for (final e in loc.encounters) '${e.demon}@${e.area.id}'];
    expect(keys.toSet().length, keys.length);
  });

  test('enemy-only demons are never recruitable', () {
    for (final e in loc.encounters.where((e) => e.kind == EncounterKind.recruit)) {
      expect(data.demon(e.demon).isEnemyOnly, isFalse, reason: e.demon);
    }
  });

  test('hordes are stored as hordes', () {
    for (final e in loc.encounters.where((e) => data.demon(e.demon).race == 'Horde')) {
      expect(e.kind, EncounterKind.horde, reason: e.demon);
    }
  });

  test('area ids are unique and phases are valid', () {
    expect(loc.areas.map((a) => a.id).toSet().length, loc.areas.length);
    for (final a in loc.areas) {
      expect(a.phase, inInclusiveRange(0, loc.phases.length - 1), reason: a.id);
    }
  });

  test('covers the early game and the whole bestiary', () {
    final early = loc.recruitable(includeSpoilers: false);
    expect(early.length, greaterThanOrEqualTo(50));
    expect(early, containsAll(['Pixie', 'Slime', 'Centaur', 'Jack Frost']));
    expect(loc.recruitable().length, greaterThanOrEqualTo(185));
  });

  test('encounters come in story order', () {
    expect(loc.forDemon('Hel').map((e) => e.area.id), ['roppongi', 'blasted-tokyo']);
    final phases = loc.encounters.map((e) => e.area.phase).toList();
    expect(phases, orderedEquals([...phases]..sort()));
  });

  test('route-locked final dungeons carry their routes', () {
    final area = {for (final a in loc.areas) a.id: a};
    expect(area['lucifers-palace']!.routes, {'law', 'neutral'});
    expect(area['purgatorium']!.routes, {'chaos', 'neutral'});
    expect(area['naraku']!.routes, isEmpty);
  });
}
