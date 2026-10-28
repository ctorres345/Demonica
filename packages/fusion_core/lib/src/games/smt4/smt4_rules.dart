import '../../engine/game_rules.dart';
import '../../model/game_data.dart';
import '../../model/models.dart';

/// Shin Megami Tensei IV fusion rules, ported from aqiu384's megaten-fusion-tool
/// (smt-nonelem-fusions.ts, smt-nonelem-fissions.ts, smt-element-fusions.ts).
///
/// Rules in plain words:
/// 1. Two demons of different races: the chart gives the result race. The
///    result level is ceil((a + b) / 2) + 1, and the result is the lowest demon
///    of that race at or above that level.
/// 2. Two demons of the same race give an Element demon (chart diagonal).
/// 3. An Element demon plus a normal demon moves the result one rank up or
///    down inside the normal demon's race, per the element chart.
/// 4. Special demons only come from their fixed ingredient list.
/// 5. Fusion accidents and enemy-only demons cannot be produced.
class Smt4Rules implements GameRules {
  Smt4Rules(this.data);

  @override
  final GameData data;

  static const _elementRace = 'Element';

  /// Level sentinel meaning "above the race's top fusable demon".
  static const _overflow = 100;

  // Caches keyed by the settings' disabled set, so toggling rebuilds once.
  Set<String>? _cacheKey;
  late Map<String, List<Demon>> _ingredientsByRace;
  late Map<String, List<int>> _resultLevelsByRace;
  late Map<String, Map<int, Demon>> _resultByRaceLevel;

  void _prepare(FusionSettings settings) {
    if (_cacheKey != null && _setEquals(_cacheKey!, settings.disabledDemons)) {
      return;
    }
    _cacheKey = Set.of(settings.disabledDemons);
    final ingredients = <String, List<Demon>>{};
    final results = <String, List<Demon>>{};
    for (final d in data.demons.values) {
      if (!settings.isEnabled(d.name)) continue;
      if (d.isEnemyOnly) continue;
      if (d.race != _elementRace) {
        ingredients.putIfAbsent(d.race, () => []).add(d);
      }
      if (d.fusion == FusionKind.normal) {
        results.putIfAbsent(d.race, () => []).add(d);
      }
    }
    for (final l in ingredients.values) {
      l.sort((a, b) => a.level.compareTo(b.level));
    }
    _ingredientsByRace = ingredients;
    _resultLevelsByRace = {};
    _resultByRaceLevel = {};
    for (final e in results.entries) {
      e.value.sort((a, b) => a.level.compareTo(b.level));
      final levels = [for (final d in e.value) d.level];
      // Upstream (smt4f): if the strongest ingredient of a race is not also a
      // result (it is a special fusion), fusions that land above the top
      // result produce nothing instead of wrapping to the top result.
      final ing = ingredients[e.key];
      if (ing != null && ing.isNotEmpty && ing.last.level != levels.last) {
        levels.add(_overflow);
      }
      _resultLevelsByRace[e.key] = levels;
      _resultByRaceLevel[e.key] = {for (final d in e.value) d.level: d};
    }
  }

  List<Demon> ingredientsOfRace(String race, FusionSettings settings) {
    _prepare(settings);
    return _ingredientsByRace[race] ?? const [];
  }

  /// The fusable demons of [race] in level order (no specials, no accidents).
  List<Demon> resultsOfRace(String race, FusionSettings settings) {
    _prepare(settings);
    return [
      for (final l in _resultLevelsByRace[race] ?? const <int>[])
        if (l != _overflow) _resultByRaceLevel[race]![l]!
    ];
  }

  @override
  Demon? fuse(Demon a, Demon b, FusionSettings settings) {
    _prepare(settings);
    if (a.name == b.name) return null;
    if (!settings.isEnabled(a.name) || !settings.isEnabled(b.name)) return null;
    if (a.isEnemyOnly || b.isEnemyOnly) return null;
    final aElem = a.race == _elementRace;
    final bElem = b.race == _elementRace;
    if (aElem && bElem) return null;
    if (aElem || bElem) {
      final elem = aElem ? a : b;
      final other = aElem ? b : a;
      return _fuseWithElement(elem, other, settings);
    }
    final resultRace = data.fusionTable[a.race]?[b.race];
    if (resultRace == null) return null;
    if (a.race == b.race) {
      // Same race -> Element demon named on the chart diagonal.
      final elem = data.demons[resultRace];
      if (elem == null || !settings.isEnabled(elem.name)) return null;
      return elem;
    }
    final levels = _resultLevelsByRace[resultRace];
    if (levels == null) return null;
    final target = (a.level + b.level + 1) ~/ 2 + 1;
    for (var i = 0; i < levels.length; i++) {
      if (levels[i] >= target) {
        if (levels[i] == _overflow) return null;
        var result = _resultByRaceLevel[resultRace]![levels[i]]!;
        // Fusing a demon into its own race/level slot yields the next one up.
        if (result.name == a.name || result.name == b.name) {
          if (i + 1 >= levels.length || levels[i + 1] == _overflow) return null;
          result = _resultByRaceLevel[resultRace]![levels[i + 1]]!;
        }
        return result;
      }
    }
    return null;
  }

  Demon? _fuseWithElement(Demon elem, Demon other, FusionSettings settings) {
    final modifier = data.elementModifiers[other.race]?[elem.name];
    if (modifier == null) return null;
    final base = _resultLevelsByRace[other.race];
    if (base == null) return null;
    // Upstream pads the list so that shifting off either end lands on a
    // sentinel, and inserts the ingredient's own level if it is not a result.
    final levels = <int>[0, 0, ...base.where((l) => l != _overflow), 100, 100];
    if (!levels.contains(other.level)) {
      levels.add(other.level);
      levels.sort();
    }
    final idx = levels.indexOf(other.level) + modifier;
    if (idx < 0 || idx >= levels.length) return null;
    final lvl = levels[idx];
    if (lvl == 0 || lvl == 100) return null;
    return _resultByRaceLevel[other.race]![lvl];
  }

  @override
  List<Recipe> reverseRecipes(Demon target, FusionSettings settings) {
    _prepare(settings);
    if (!settings.isEnabled(target.name)) return const [];
    switch (target.fusion) {
      case FusionKind.special:
        return [
          Recipe(result: target.name, ingredients: target.specialRecipe, kind: RecipeKind.special)
        ];
      case FusionKind.accident:
      case FusionKind.enemy:
        return const [];
      case FusionKind.normal:
        break;
    }
    final out = <Recipe>[];
    if (target.race == _elementRace) {
      for (final race in data.races) {
        if (data.fusionTable[race]?[race] != target.name) continue;
        final list = _ingredientsByRace[race] ?? const [];
        for (var i = 0; i < list.length; i++) {
          for (var j = i + 1; j < list.length; j++) {
            out.add(Recipe(
              result: target.name,
              ingredients: [list[i].name, list[j].name],
              kind: RecipeKind.sameRace,
            ));
          }
        }
      }
      return out;
    }
    // Normal: every race pair whose chart result is the target's race.
    final seen = <String>{};
    for (final raceA in data.races) {
      final row = data.fusionTable[raceA];
      if (row == null) continue;
      for (final e in row.entries) {
        final raceB = e.key;
        if (e.value != target.race || raceA == raceB) continue;
        final key = raceA.compareTo(raceB) < 0 ? '$raceA|$raceB' : '$raceB|$raceA';
        if (!seen.add(key)) continue;
        for (final a in _ingredientsByRace[raceA] ?? const <Demon>[]) {
          for (final b in _ingredientsByRace[raceB] ?? const <Demon>[]) {
            if (fuse(a, b, settings)?.name == target.name) {
              out.add(Recipe(
                result: target.name,
                ingredients: _ordered(a, b),
                kind: RecipeKind.normal,
              ));
            }
          }
        }
      }
    }
    // Element + demon of the same race.
    for (final elemName in data.elementDemons) {
      final elem = data.demons[elemName];
      if (elem == null || !settings.isEnabled(elemName)) continue;
      if (data.elementModifiers[target.race]?[elemName] == null) continue;
      for (final d in _ingredientsByRace[target.race] ?? const <Demon>[]) {
        if (fuse(elem, d, settings)?.name == target.name) {
          out.add(Recipe(
            result: target.name,
            ingredients: [d.name, elemName],
            kind: RecipeKind.element,
          ));
        }
      }
    }
    return out;
  }

  @override
  List<Recipe> forwardRecipes(Demon ingredient, FusionSettings settings) {
    _prepare(settings);
    final out = <Recipe>[];
    final candidates = [
      for (final l in _ingredientsByRace.values) ...l,
      for (final e in data.elementDemons)
        if (data.demons[e] != null) data.demons[e]!,
    ];
    for (final other in candidates) {
      if (other.name == ingredient.name) continue;
      final r = fuse(ingredient, other, settings);
      if (r == null) continue;
      final kind = ingredient.race == _elementRace || other.race == _elementRace
          ? RecipeKind.element
          : ingredient.race == other.race
              ? RecipeKind.sameRace
              : RecipeKind.normal;
      out.add(Recipe(result: r.name, ingredients: _ordered(ingredient, other), kind: kind));
    }
    return out;
  }

  @override
  bool canInherit(Skill skill) => !skill.unique;

  @override
  int freeSkillSlots(Demon child) {
    final free = data.maxSkillSlots - child.innateSkillCount;
    return free < 0 ? 0 : free;
  }

  /// Macca to re-summon every ingredient of [recipe] from the Compendium.
  int recipeCost(Recipe recipe) =>
      recipe.ingredients.fold(0, (acc, n) => acc + (data.demons[n]?.price ?? 0));

  List<String> _ordered(Demon a, Demon b) {
    final ra = data.raceOrder(a.race), rb = data.raceOrder(b.race);
    if (ra != rb) return ra < rb ? [a.name, b.name] : [b.name, a.name];
    return a.level <= b.level ? [a.name, b.name] : [b.name, a.name];
  }

  static bool _setEquals(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);
}
