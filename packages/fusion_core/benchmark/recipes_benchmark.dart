// Times the engine on the real SMT IV data, to catch slowdowns before they
// reach the app. Run from packages/fusion_core:
//
//   dart run benchmark/recipes_benchmark.dart
import 'dart:io';

import 'package:fusion_core/fusion_core.dart';

void main() {
  final dir = Directory('../../assets/data/smt4');
  String read(String f) => File('${dir.path}/$f').readAsStringSync();

  final load = Stopwatch()..start();
  final data = GameData.fromJsonStrings(
    meta: read('meta.json'),
    demons: read('demons.json'),
    skills: read('skills.json'),
    fusionChart: read('fusion_chart.json'),
    elementChart: read('element_chart.json'),
    unlocks: read('unlocks.json'),
  );
  load.stop();
  final rules = Smt4Rules(data);
  final settings = data.defaultSettings;
  final demons = data.demons.values.toList();

  int time(void Function() f) {
    final sw = Stopwatch()..start();
    f();
    return sw.elapsedMilliseconds;
  }

  var recipes = 0;
  final reverseCold = time(() {
    for (final d in demons) {
      recipes += rules.reverseRecipes(d, settings).length;
    }
  });
  final reverseWarm = time(() {
    for (final d in demons) {
      rules.reverseRecipes(d, settings);
    }
  });
  final forward = time(() {
    for (final d in demons) {
      rules.forwardRecipes(d, settings);
    }
  });

  stdout.writeln('parse data            ${load.elapsedMilliseconds} ms');
  stdout.writeln('reverse, all demons   $reverseCold ms ($recipes recipes)');
  stdout.writeln('reverse, again        $reverseWarm ms');
  stdout.writeln('forward, all demons   $forward ms');
}
