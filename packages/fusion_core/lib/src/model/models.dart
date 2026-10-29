/// Core data models shared by every game adapter.
library;

/// How a demon can be obtained.
enum FusionKind { normal, special, accident, enemy }

enum Resist { none, weak, resist, nullify, repel, drain }

Resist resistFromString(String s) => switch (s) {
  'weak' => Resist.weak,
  'resist' => Resist.resist,
  'null' => Resist.nullify,
  'repel' => Resist.repel,
  'drain' => Resist.drain,
  _ => Resist.none,
};

class Stats {
  const Stats({
    required this.hp,
    required this.mp,
    required this.st,
    required this.dx,
    required this.ma,
    required this.ag,
    required this.lu,
  });

  final int hp, mp, st, dx, ma, ag, lu;

  factory Stats.fromJson(Map<String, dynamic> j) => Stats(
    hp: j['hp'] as int,
    mp: j['mp'] as int,
    st: j['st'] as int,
    dx: j['dx'] as int,
    ma: j['ma'] as int,
    ag: j['ag'] as int,
    lu: j['lu'] as int,
  );
}

/// A skill a demon knows, and the level it is learned at (0 = innate).
class LearnedSkill {
  const LearnedSkill(this.name, this.level);
  final String name;
  final int level;
  bool get innate => level == 0;
}

class Demon {
  Demon({
    required this.name,
    required this.race,
    required this.level,
    required this.alignment,
    required this.stats,
    required this.resists,
    required this.ailments,
    required this.skills,
    required this.price,
    required this.fusion,
    this.prereq,
    this.unlockCategory,
    this.specialRecipe = const [],
    this.evolvesTo,
    this.evolvesAtLevel,
    this.evolvesFrom,
  });

  final String name;
  final String race;
  final int level;

  /// e.g. "Light-Law", "Neutral-Chaos".
  final String alignment;
  final Stats stats;
  final Map<String, Resist> resists;
  final Map<String, Resist> ailments;
  final List<LearnedSkill> skills;

  /// Macca cost to re-summon from the Compendium.
  final int price;
  final FusionKind fusion;
  final String? prereq;
  final String? unlockCategory;
  final List<String> specialRecipe;
  final String? evolvesTo;
  final int? evolvesAtLevel;
  final String? evolvesFrom;

  String get id => slugify(name);
  bool get isSpecial => fusion == FusionKind.special;
  bool get isEnemyOnly => fusion == FusionKind.enemy;
  int get innateSkillCount => skills.where((s) => s.innate).length;

  factory Demon.fromJson(Map<String, dynamic> j) => Demon(
    name: j['name'] as String,
    race: j['race'] as String,
    level: j['level'] as int,
    alignment: j['alignment'] as String,
    stats: Stats.fromJson(j['stats'] as Map<String, dynamic>),
    resists: (j['resists'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, resistFromString(v as String)),
    ),
    ailments: (j['ailments'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, resistFromString(v as String)),
    ),
    skills: [
      for (final s in j['skills'] as List) LearnedSkill(s['name'] as String, s['level'] as int),
    ],
    price: j['price'] as int,
    fusion: FusionKind.values.byName(j['fusion'] as String),
    prereq: j['prereq'] as String?,
    unlockCategory: j['unlockCategory'] as String?,
    specialRecipe: (j['specialRecipe'] as List?)?.cast<String>() ?? const [],
    evolvesTo: j['evolvesTo'] as String?,
    evolvesAtLevel: j['evolvesAtLevel'] as int?,
    evolvesFrom: j['evolvesFrom'] as String?,
  );
}

class Skill {
  const Skill({
    required this.name,
    required this.element,
    required this.target,
    required this.rank,
    required this.unique,
    required this.costMp,
    required this.power,
    required this.accuracy,
    required this.effect,
    required this.condition,
    this.skillCard,
  });

  final String name;

  /// Short element code: phy, gun, fir, ice, ele, for, lig, dar, alm, rec,
  /// ail, sup, spe, pas.
  final String element;
  final String target;
  final int rank;

  /// Unique skills cannot be inherited through fusion.
  final bool unique;
  final int costMp;
  final int power;
  final int accuracy;
  final String effect;
  final String condition;
  final String? skillCard;

  String get id => slugify(name);
  bool get isPassive => element == 'pas';

  factory Skill.fromJson(Map<String, dynamic> j) => Skill(
    name: j['name'] as String,
    element: j['element'] as String,
    target: j['target'] as String,
    rank: j['rank'] as int,
    unique: j['unique'] as bool,
    costMp: j['costMp'] as int,
    power: j['power'] as int,
    accuracy: j['accuracy'] as int,
    effect: j['effect'] as String,
    condition: j['condition'] as String,
    skillCard: j['skillCard'] as String?,
  );
}

class UnlockEntry {
  const UnlockEntry(this.demons, this.condition);
  final List<String> demons;
  final String condition;
}

class UnlockCategory {
  const UnlockCategory(this.category, this.enabledByDefault, this.entries);
  final String category;
  final bool enabledByDefault;
  final List<UnlockEntry> entries;
}

/// Which optional demons are enabled, keyed by demon name.
/// Demons that are not in any unlock category are always enabled.
class FusionSettings {
  const FusionSettings({this.disabledDemons = const {}});
  final Set<String> disabledDemons;

  bool isEnabled(String demon) => !disabledDemons.contains(demon);

  FusionSettings copyWith({Set<String>? disabledDemons}) =>
      FusionSettings(disabledDemons: disabledDemons ?? this.disabledDemons);
}

/// One way to produce a demon. Normal and element recipes have two
/// ingredients; special recipes may have 2 to 4.
class Recipe {
  const Recipe({required this.result, required this.ingredients, required this.kind});

  final String result;
  final List<String> ingredients;
  final RecipeKind kind;

  @override
  String toString() => '${ingredients.join(' x ')} -> $result ($kind)';

  @override
  bool operator ==(Object other) =>
      other is Recipe &&
      other.result == result &&
      other.kind == kind &&
      _sameList(other.ingredients, ingredients);

  @override
  int get hashCode => Object.hash(result, kind, Object.hashAll(ingredients));
}

enum RecipeKind {
  /// Two demons of different races.
  normal,

  /// An Element demon plus a demon, shifting it up or down one rank.
  element,

  /// Two demons of the same race producing an Element demon.
  sameRace,

  /// Fixed named ingredients.
  special,
}

bool _sameList(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

String slugify(String name) =>
    name.toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), '-').replaceAll(RegExp(r'^-+|-+$'), '');
