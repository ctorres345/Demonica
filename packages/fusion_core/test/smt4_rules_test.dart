import 'dart:convert';
import 'dart:io';

import 'package:fusion_core/fusion_core.dart';
import 'package:test/test.dart';

/// Loads the real SMT IV assets from the app's assets folder.
GameData loadSmt4() {
  final dir = Directory('../../assets/data/smt4');
  String read(String f) => File('${dir.path}/$f').readAsStringSync();
  return GameData.fromJsonStrings(
    meta: read('meta.json'),
    demons: read('demons.json'),
    skills: read('skills.json'),
    fusionChart: read('fusion_chart.json'),
    elementChart: read('element_chart.json'),
    unlocks: read('unlocks.json'),
  );
}

void main() {
  final data = loadSmt4();
  final rules = Smt4Rules(data);
  final settings = data.defaultSettings;

  group('data', () {
    test('loads every demon and skill', () {
      expect(data.demons.length, 454);
      expect(data.skills.length, 261);
      expect(data.races.length, greaterThan(40));
    });

    test('DLC demons are disabled by default, story demons enabled', () {
      expect(settings.isEnabled('Oread'), isFalse);
      expect(settings.isEnabled('Minotaur'), isTrue);
      expect(settings.isEnabled('Pixie'), isTrue);
    });

    test('unique skills cannot be inherited, normal ones can', () {
      expect(rules.canInherit(data.skill('Lightning of God')), isFalse);
      expect(rules.canInherit(data.skill('Die For Me!')), isFalse);
      expect(rules.canInherit(data.skill('Mediarahan')), isTrue);
      expect(data.skills.values.where((s) => s.unique).length, 18);
    });

    test('free skill slots are 8 minus innate skills', () {
      expect(rules.freeSkillSlots(data.demon('Lilith')), 5); // 3 innate
      expect(rules.freeSkillSlots(data.demon('Pixie')), 6); // 2 innate
    });

    test('macca price matches upstream (price is doubled json value)', () {
      expect(data.demon('Lilith').price, 36710);
      expect(data.demon('Pixie').price, 1172);
    });
  });

  group('forward fusion', () {
    Demon d(String n) => data.demon(n);

    test('different races: ceil of average + 1, lowest demon at or above', () {
      // Pixie (Fairy 7) + Angel (Divine 3): Fairy x Divine = Nymph, level 7 -> Apsaras (8).
      expect(rules.fuse(d('Pixie'), d('Angel'), settings)?.name, 'Apsaras');
      expect(rules.fuse(d('Angel'), d('Pixie'), settings)?.name, 'Apsaras');
      expect(rules.fuse(d('Pixie'), d('Cerberus'), settings)?.name, 'Rukh');
    });

    test('same race gives the Element demon on the chart diagonal', () {
      expect(rules.fuse(d('Pixie'), d('Jack Frost'), settings)?.name, 'Aeros');
      expect(rules.fuse(d('Pixie'), d('Napaea'), settings)?.name, 'Aeros');
    });

    test('element shifts a demon one rank inside its race', () {
      expect(rules.fuse(d('Erthys'), d('Pixie'), settings)?.name, 'Napaea'); // down
      expect(rules.fuse(d('Aeros'), d('Pixie'), settings)?.name, 'Spriggan'); // up
      expect(rules.fuse(d('Erthys'), d('Napaea'), settings), isNull); // nothing below
      expect(rules.fuse(d('Erthys'), d('Aeros'), settings), isNull); // two elements
    });

    test('matches the Python port for sampled pairs', () {
      final golden = jsonDecode(File('test/smt4_forward_golden.json').readAsStringSync())
          as Map<String, dynamic>;
      for (final a in golden.entries) {
        for (final b in (a.value as Map<String, dynamic>).entries) {
          final got = rules.fuse(d(a.key), d(b.key), settings)?.name;
          expect(got, b.value, reason: '${a.key} + ${b.key}');
        }
      }
    });
  });

  group('reverse recipes', () {
    test('special demons return their fixed recipe', () {
      final r = rules.reverseRecipes(data.demon('Lilith'), settings);
      expect(r.length, 1);
      expect(r.single.kind, RecipeKind.special);
      expect(r.single.ingredients, ['Black Maria', 'Cherub', 'Asmodeus']);
    });

    test('accident and enemy-only demons have no recipes', () {
      expect(rules.reverseRecipes(data.demon('Siegfried'), settings), isEmpty);
      expect(rules.reverseRecipes(data.demon('Ashura Man'), settings), isEmpty);
    });

    test('every normal recipe fuses back to its result', () {
      for (final name in ['Pixie', 'Jack Frost', 'Cerberus', 'Kali', 'Metatron']) {
        final target = data.demon(name);
        for (final r in rules.reverseRecipes(target, settings)) {
          final a = data.demon(r.ingredients[0]);
          final b = data.demon(r.ingredients[1]);
          expect(rules.fuse(a, b, settings)?.name, name, reason: '$r');
        }
      }
    });

    test('match the Python port for 20 demons (normal + same-race pairs)', () {
      final golden = jsonDecode(File('test/smt4_golden.json').readAsStringSync())
          as Map<String, dynamic>;
      for (final e in golden.entries) {
        final target = data.demon(e.key);
        final expected = {
          for (final p in (e.value['recipes'] as List))
            ([...(p as List).cast<String>()]..sort()).join('|')
        };
        final got = {
          for (final r in rules.reverseRecipes(target, settings))
            if (r.kind == RecipeKind.normal || r.kind == RecipeKind.sameRace)
              ([...r.ingredients]..sort()).join('|')
        };
        expect(got, expected, reason: e.key);
      }
    });

    test('element recipes exist for a mid-rank demon', () {
      final r = rules.reverseRecipes(data.demon('Jack Frost'), settings);
      final elem = r.where((x) => x.kind == RecipeKind.element).toList();
      expect(elem, isNotEmpty);
      for (final x in elem) {
        expect(data.demon(x.ingredients[1]).race, 'Element');
      }
    });

    test('disabling a demon removes it from recipes', () {
      final r1 = rules.reverseRecipes(data.demon('Pixie'), settings);
      expect(r1.any((r) => r.ingredients.contains('Dwarf')), isTrue);
      final r2 = rules.reverseRecipes(
          data.demon('Pixie'), settings.copyWith(disabledDemons: {...settings.disabledDemons, 'Dwarf'}));
      expect(r2.any((r) => r.ingredients.contains('Dwarf')), isFalse);
    });

    test('is fast enough for the UI', () {
      final sw = Stopwatch()..start();
      for (final d in data.demons.values) {
        rules.reverseRecipes(d, settings);
      }
      sw.stop();
      // 454 demons, every recipe, in well under a few seconds on CI.
      expect(sw.elapsedMilliseconds, lessThan(10000));
    });
  });
}
