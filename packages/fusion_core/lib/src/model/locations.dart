import 'dart:convert';

/// How a demon shows up in an area.
enum EncounterKind {
  /// Appears as a normal enemy and can be talked into joining.
  recruit,

  /// A horde: a group enemy that never joins.
  horde,

  /// Appears as an enemy but cannot be recruited there (zombies, Purgatorium angels).
  enemy,
}

/// A place in the game where demons appear, such as Naraku or Shinjuku.
class Area {
  const Area({
    required this.id,
    required this.name,
    required this.phase,
    required this.phaseName,
    this.routes = const {},
    this.spoiler = false,
  });

  final String id;
  final String name;

  /// Story phase as an index into [LocationData.phases], so areas sort in the
  /// order the player reaches them.
  final int phase;
  final String phaseName;

  /// Alignment routes that can reach this area. Empty means every route.
  final Set<String> routes;

  /// Late-game area, hidden unless the user turns spoilers on.
  final bool spoiler;
}

/// One demon appearing in one area.
class Encounter {
  const Encounter({required this.demon, required this.kind, required this.area});
  final String demon;
  final EncounterKind kind;
  final Area area;
}

/// Where demons can be found, from the curated `locations.json`. Unlike the
/// other game files it is not imported from upstream, which has no location
/// data for SMT IV.
class LocationData {
  LocationData({
    required this.sourceName,
    required this.sourceUrl,
    required this.phases,
    required this.areas,
    required this.encounters,
  });

  final String sourceName;
  final String sourceUrl;
  final List<String> phases;
  final List<Area> areas;

  /// Sorted by story phase, then area, then demon name.
  final List<Encounter> encounters;

  /// Encounters per demon name, in story order.
  late final Map<String, List<Encounter>> byDemon = () {
    final out = <String, List<Encounter>>{};
    for (final e in encounters) {
      (out[e.demon] ??= []).add(e);
    }
    return out;
  }();

  List<Encounter> forDemon(String name) => byDemon[name] ?? const [];

  /// Demons that can be recruited somewhere. With [includeSpoilers] false,
  /// only areas that are not late-game count.
  Set<String> recruitable({bool includeSpoilers = true}) => {
    for (final e in encounters)
      if (e.kind == EncounterKind.recruit && (includeSpoilers || !e.area.spoiler)) e.demon,
  };

  factory LocationData.fromJsonString(String json) {
    final j = jsonDecode(json) as Map<String, dynamic>;
    final source = j['source'] as Map<String, dynamic>;
    final phases = (j['phases'] as List).cast<String>();
    final areas = [
      for (final a in (j['areas'] as List).cast<Map<String, dynamic>>())
        Area(
          id: a['id'] as String,
          name: a['name'] as String,
          phase: a['phase'] as int,
          phaseName: phases[a['phase'] as int],
          routes: (a['routes'] as List).cast<String>().toSet(),
          spoiler: a['spoiler'] as bool,
        ),
    ];
    final areaById = {for (final a in areas) a.id: a};
    final areaOrder = {for (var i = 0; i < areas.length; i++) areas[i].id: i};
    final encounters =
        [
          for (final e in (j['encounters'] as List).cast<Map<String, dynamic>>())
            Encounter(
              demon: e['demon'] as String,
              kind: EncounterKind.values.byName(e['kind'] as String),
              area:
                  areaById[e['area']] ??
                  (throw FormatException('unknown area "${e['area']}" for ${e['demon']}')),
            ),
        ]..sort((a, b) {
          final p = a.area.phase.compareTo(b.area.phase);
          if (p != 0) return p;
          final o = areaOrder[a.area.id]!.compareTo(areaOrder[b.area.id]!);
          return o != 0 ? o : a.demon.compareTo(b.demon);
        });
    return LocationData(
      sourceName: source['name'] as String,
      sourceUrl: source['url'] as String,
      phases: phases,
      areas: areas,
      encounters: encounters,
    );
  }
}
