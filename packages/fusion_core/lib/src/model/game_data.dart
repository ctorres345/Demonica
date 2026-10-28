import 'dart:convert';

import 'models.dart';

/// Everything the engine needs for one game, loaded from the decoded JSON
/// written by `tool/import_<game>.dart`.
class GameData {
  GameData({
    required this.gameId,
    required this.title,
    required this.sourceCommit,
    required this.races,
    required this.resistElements,
    required this.elementDemons,
    required this.maxSkillSlots,
    required List<Demon> demons,
    required List<Skill> skills,
    required this.fusionTable,
    required this.elementModifiers,
    required this.unlocks,
  })  : demons = {for (final d in demons) d.name: d},
        skills = {for (final s in skills) s.name: s},
        demonsById = {for (final d in demons) d.id: d},
        skillsById = {for (final s in skills) s.id: s};

  final String gameId;
  final String title;
  final String sourceCommit;
  final List<String> races;
  final List<String> resistElements;
  final List<String> elementDemons;
  final int maxSkillSlots;
  final Map<String, Demon> demons;
  final Map<String, Skill> skills;
  final Map<String, Demon> demonsById;
  final Map<String, Skill> skillsById;

  /// fusionTable[raceA][raceB] = result race (symmetric). The diagonal gives
  /// the Element demon produced by two demons of the same race.
  final Map<String, Map<String, String>> fusionTable;

  /// elementModifiers[race][elementDemon] = +1 (rank up) or -1 (rank down).
  final Map<String, Map<String, int>> elementModifiers;
  final List<UnlockCategory> unlocks;

  Demon demon(String name) =>
      demons[name] ?? (throw ArgumentError('unknown demon "$name"'));
  Skill skill(String name) =>
      skills[name] ?? (throw ArgumentError('unknown skill "$name"'));

  /// Demon names that are toggled by an unlock category, with their default.
  Map<String, bool> get unlockDefaults => {
        for (final cat in unlocks)
          for (final e in cat.entries)
            for (final d in e.demons) d: cat.enabledByDefault,
      };

  FusionSettings get defaultSettings => FusionSettings(
        disabledDemons: {
          for (final e in unlockDefaults.entries)
            if (!e.value) e.key,
        },
      );

  /// Demons sorted by level, then race order, then name.
  late final List<Demon> demonsByLevel = demons.values.toList()
    ..sort((a, b) {
      final l = a.level.compareTo(b.level);
      if (l != 0) return l;
      final r = raceOrder(a.race).compareTo(raceOrder(b.race));
      if (r != 0) return r;
      return a.name.compareTo(b.name);
    });

  late final Map<String, int> _raceOrder = {
    for (var i = 0; i < races.length; i++) races[i]: i
  };
  int raceOrder(String race) => _raceOrder[race] ?? 999;

  /// Builds GameData from the JSON strings of the asset files.
  factory GameData.fromJsonStrings({
    required String meta,
    required String demons,
    required String skills,
    required String fusionChart,
    required String elementChart,
    required String unlocks,
  }) {
    final m = jsonDecode(meta) as Map<String, dynamic>;
    final fc = jsonDecode(fusionChart) as Map<String, dynamic>;
    final ec = jsonDecode(elementChart) as Map<String, dynamic>;
    return GameData(
      gameId: m['game'] as String,
      title: m['title'] as String,
      sourceCommit: m['sourceCommit'] as String,
      races: (m['races'] as List).cast<String>(),
      resistElements: (m['resistElements'] as List).cast<String>(),
      elementDemons: (m['elementDemons'] as List).cast<String>(),
      maxSkillSlots: m['maxSkillSlots'] as int,
      demons: [
        for (final d in jsonDecode(demons) as List)
          Demon.fromJson(d as Map<String, dynamic>)
      ],
      skills: [
        for (final s in jsonDecode(skills) as List)
          Skill.fromJson(s as Map<String, dynamic>)
      ],
      fusionTable: (fc['table'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as Map<String, dynamic>).cast<String, String>())),
      elementModifiers: (ec['modifiers'] as Map<String, dynamic>).map(
          (k, v) => MapEntry(k, (v as Map<String, dynamic>).cast<String, int>())),
      unlocks: [
        for (final c in jsonDecode(unlocks) as List)
          UnlockCategory(
            c['category'] as String,
            c['enabledByDefault'] as bool,
            [
              for (final e in c['entries'] as List)
                UnlockEntry((e['demons'] as List).cast<String>(), e['condition'] as String)
            ],
          )
      ],
    );
  }
}
