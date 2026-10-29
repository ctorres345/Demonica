import '../model/game_data.dart';
import '../model/models.dart';
import 'game_rules.dart';

/// One fusion in a [Plan].
class FusionStep {
  const FusionStep({
    required this.recipe,
    required this.skillsToPick,
    required this.macca,
    this.levelUps = const {},
  });

  final Recipe recipe;
  String get result => recipe.result;
  List<String> get ingredients => recipe.ingredients;

  /// Skills to tick on the fusion screen so the result inherits them.
  final List<String> skillsToPick;

  /// Macca to summon the ingredients of this step that no earlier step makes.
  final int macca;

  /// Ingredients to level up before this fusion so they learn a skill the
  /// result needs: demon name -> level to reach.
  final Map<String, int> levelUps;

  @override
  String toString() => '$recipe keep ${skillsToPick.join(', ')}';
}

/// A chain of fusions that ends with the target holding every wanted skill.
class Plan {
  const Plan({required this.target, required this.steps, required this.learnedByTarget});

  final String target;

  /// Leaves first; the last step makes the target.
  final List<FusionStep> steps;

  /// Wanted skills the target learns by itself, with the level (0 = knows it
  /// on arrival). These need no inheritance.
  final Map<String, int> learnedByTarget;

  int get totalMacca => steps.fold(0, (a, s) => a + s.macca);
}

/// Why no plan came back.
enum PlanFailure {
  /// The target is a fusion accident, enemy-only or turned off in Settings.
  notFusable,

  /// A wanted skill is unique to other demons and cannot be inherited.
  uniqueSkill,

  /// More skills to inherit than the target has free slots.
  notEnoughSlots,

  /// No chain within the depth limit carries every skill.
  depthLimit,
}

/// What [Planner.plan] returns: up to a few plans, cheapest first, or why
/// there are none.
class PlanResult {
  const PlanResult.found(this.plans) : failure = null, failedSkills = const [], freeSlots = 0;
  const PlanResult.failed(this.failure, {this.failedSkills = const [], this.freeSlots = 0})
    : plans = const [];

  final List<Plan> plans;
  final PlanFailure? failure;

  /// For [PlanFailure.uniqueSkill]: the skills that cannot be inherited. For
  /// [PlanFailure.notEnoughSlots]: every skill that must be inherited.
  final List<String> failedSkills;

  /// For [PlanFailure.notEnoughSlots]: how many the target can take.
  final int freeSlots;

  bool get found => plans.isNotEmpty;
}

/// Finds fusion chains that end with a target demon holding a set of skills.
///
/// How it works, in game terms:
/// - Wanted skills the target learns itself are dropped from the search.
/// - The rest must be inherited: no unique skills, and no more than the
///   target's free slots (8 minus innate skills).
/// - A parent brings its innate skills for free, and the skills it learns by
///   leveling up if the plan says to level it first. A parent can also carry
///   extra skills if it was fused with them, so the search goes down the
///   reverse recipes, splitting the skills still missing between the
///   parents, up to [maxDepth] fusions deep.
/// - Inherited plus level-up skills must fit the parent's free slots.
/// - Parents that carry nothing extra are bought from the Compendium at
///   their price. The cheapest total wins; ties go to fewer fusions, then
///   fewer level-ups.
///
/// Nothing about the player's level, party or Compendium is used: the plan
/// assumes every demon can be summoned. Fusion accidents are left out
/// because nobody can count on getting one.
class Planner {
  Planner(
    this.rules, {
    this.settings = const FusionSettings(),
    this.maxDepth = 3,
    this.allowLevelUps = true,
  });

  final GameRules rules;
  final FusionSettings settings;

  /// Whether an ingredient may be leveled up to learn a skill before it is
  /// fused. Off means every inherited skill comes from innate skills.
  final bool allowLevelUps;

  /// Fusions from the deepest ingredient up to the target, inclusive.
  final int maxDepth;

  GameData get _data => rules.data;

  // Per search: the skills being planned, as bit positions.
  late List<String> _skills;
  final _innateMask = <String, int>{};

  // Per demon: the planned skills it learns by leveling, as (bit, level).
  final _levelSkills = <String, List<(int, int)>>{};
  final _memo = <String, _Node?>{};

  /// Plans for [target] ending with [wanted], cheapest first, at most
  /// [alternatives] of them, each starting from a different last fusion.
  PlanResult plan(Demon target, Iterable<String> wanted, {int alternatives = 3}) {
    if (target.fusion == FusionKind.accident ||
        target.fusion == FusionKind.enemy ||
        !settings.isEnabled(target.name)) {
      return const PlanResult.failed(PlanFailure.notFusable);
    }
    final learned = <String, int>{};
    final toInherit = <String>[];
    for (final s in wanted.toSet()) {
      final own = target.skills.where((l) => l.name == s).firstOrNull;
      own != null ? learned[s] = own.level : toInherit.add(s);
    }
    final unique = [
      for (final s in toInherit)
        if (!rules.canInherit(_data.skill(s))) s,
    ];
    if (unique.isNotEmpty) {
      return PlanResult.failed(PlanFailure.uniqueSkill, failedSkills: unique);
    }
    final free = rules.freeSkillSlots(target);
    if (toInherit.length > free) {
      return PlanResult.failed(
        PlanFailure.notEnoughSlots,
        failedSkills: toInherit,
        freeSlots: free,
      );
    }

    _skills = toInherit;
    _innateMask.clear();
    _levelSkills.clear();
    _memo.clear();
    final mask = (1 << _skills.length) - 1;
    final options = <_Node>[];
    for (final r in rules.reverseRecipes(target, settings)) {
      final n = _bestFor(r, mask, maxDepth - 1);
      if (n != null) options.add(n);
    }
    if (options.isEmpty) return const PlanResult.failed(PlanFailure.depthLimit);
    options.sort(_compare);
    return PlanResult.found([
      for (final n in options.take(alternatives))
        Plan(target: target.name, steps: _steps(n), learnedByTarget: learned),
    ]);
  }

  int _innate(String demon) => _innateMask[demon] ??= () {
    final d = _data.demons[demon];
    var m = 0;
    if (d == null) return m;
    for (var i = 0; i < _skills.length; i++) {
      if (d.skills.any((l) => l.innate && l.name == _skills[i])) m |= 1 << i;
    }
    return m;
  }();

  List<(int, int)> _levelUps(String demon) => _levelSkills[demon] ??= [
    if (allowLevelUps)
      for (var i = 0; i < _skills.length; i++)
        for (final l in _data.demons[demon]?.skills ?? const <LearnedSkill>[])
          if (!l.innate && l.name == _skills[i]) (1 << i, l.level),
  ];

  /// The cheapest way to have [demon] holding the skills in [mask], with at
  /// most [depth] fusions below it. Depth 0 means "summon it as is".
  _Node? _get(String demon, int mask, int depth) {
    final d = _data.demons[demon];
    // Accidents happen by chance and enemy-only demons never join, so a plan
    // cannot count on either.
    if (d == null || d.isEnemyOnly || d.fusion == FusionKind.accident) return null;
    mask &= ~_innate(demon);
    // Skills it learns by leveling come from leveling it, not from parents.
    var levelTo = 0, leveled = 0;
    for (final (bit, level) in _levelUps(demon)) {
      if (mask & bit == 0) continue;
      mask &= ~bit;
      leveled++;
      if (level > levelTo) levelTo = level;
    }
    if (_bitCount(mask) + leveled > rules.freeSkillSlots(d)) return null;
    if (mask == 0) return _Node.leaf(demon, d.price, levelTo);
    if (depth == 0) return null;
    final key = '$demon|$mask|$depth';
    final _Node? best;
    if (_memo.containsKey(key)) {
      best = _memo[key];
    } else {
      _Node? found;
      for (final r in rules.reverseRecipes(d, settings)) {
        final n = _bestFor(r, mask, depth - 1);
        if (n != null && (found == null || _compare(n, found) < 0)) found = n;
      }
      best = _memo[key] = found;
    }
    return best == null || levelTo == 0 ? best : best.leveledTo(levelTo);
  }

  /// The cheapest way to fuse [r] so its result inherits [mask], with each
  /// ingredient at most [depth] fusions deep.
  _Node? _bestFor(Recipe r, int mask, int depth) {
    var covered = 0;
    for (final i in r.ingredients) {
      covered |= _innate(i);
    }
    final pick = mask; // the result inherits all of these
    final rest = mask & ~covered;
    _Node? best;
    // Try every way of handing the skills no parent knows to the parents.
    void assign(int idx, int left, List<_Node> parts) {
      if (idx == r.ingredients.length - 1) {
        final last = _get(r.ingredients[idx], left, depth);
        if (last == null) return;
        final n = _Node.fusion(r, pick, [...parts, last]);
        if (best == null || _compare(n, best!) < 0) best = n;
        return;
      }
      for (var sub = left; ; sub = (sub - 1) & left) {
        final part = _get(r.ingredients[idx], sub, depth);
        if (part != null) assign(idx + 1, left & ~sub, [...parts, part]);
        if (sub == 0) break;
      }
    }

    assign(0, rest, const []);
    return best;
  }

  List<FusionStep> _steps(_Node root) {
    final out = <FusionStep>[];
    void walk(_Node n) {
      if (n.recipe == null) return;
      for (final p in n.parts) {
        walk(p);
      }
      final bought = n.parts.where((p) => p.recipe == null).fold(0, (a, p) => a + p.cost);
      out.add(
        FusionStep(
          recipe: n.recipe!,
          levelUps: {
            for (final p in n.parts)
              if (p.levelTo > 0) p.demon: p.levelTo,
          },
          skillsToPick: [
            for (var i = 0; i < _skills.length; i++)
              if (n.mask & (1 << i) != 0) _skills[i],
          ],
          macca: bought,
        ),
      );
    }

    walk(root);
    return out;
  }

  static int _compare(_Node a, _Node b) {
    final c = a.cost.compareTo(b.cost);
    if (c != 0) return c;
    final f = a.fusions.compareTo(b.fusions);
    return f != 0 ? f : a.levelUps.compareTo(b.levelUps);
  }

  static int _bitCount(int m) {
    var c = 0;
    for (; m != 0; m &= m - 1) {
      c++;
    }
    return c;
  }
}

/// A demon in a plan: summoned as is (a leaf) or fused from [parts].
class _Node {
  _Node.leaf(this.demon, this.cost, this.levelTo)
    : recipe = null,
      mask = 0,
      parts = const [],
      fusions = 0,
      levelUps = levelTo > 0 ? 1 : 0;

  _Node.fusion(Recipe this.recipe, this.mask, this.parts)
    : demon = recipe.result,
      levelTo = 0,
      cost = parts.fold(0, (a, p) => a + p.cost),
      fusions = parts.fold(1, (a, p) => a + p.fusions),
      levelUps = parts.fold(0, (a, p) => a + p.levelUps);

  _Node._copy(_Node n, this.levelTo)
    : demon = n.demon,
      recipe = n.recipe,
      mask = n.mask,
      parts = n.parts,
      cost = n.cost,
      fusions = n.fusions,
      levelUps = n.levelUps + 1;

  /// The same demon, leveled to [level] after it is made.
  _Node leveledTo(int level) => _Node._copy(this, level);

  final String demon;
  final Recipe? recipe;

  /// Skills (as bits) this demon must inherit when fused.
  final int mask;
  final List<_Node> parts;
  final int cost;
  final int fusions;

  /// Level to raise this demon to before using it (0 = use it as made).
  final int levelTo;

  /// Level-ups in this demon's whole sub-plan, for tie-breaks.
  final int levelUps;
}
