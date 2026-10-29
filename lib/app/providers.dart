import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_core/fusion_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../design_system/tokens.dart';

/// Loads the bundled SMT IV data once.
final gameDataProvider = FutureProvider<GameData>((ref) async {
  const base = 'assets/data/smt4';
  Future<String> load(String f) => rootBundle.loadString('$base/$f');
  final parts = await Future.wait([
    load('meta.json'),
    load('demons.json'),
    load('skills.json'),
    load('fusion_chart.json'),
    load('element_chart.json'),
    load('unlocks.json'),
  ]);
  return GameData.fromJsonStrings(
    meta: parts[0],
    demons: parts[1],
    skills: parts[2],
    fusionChart: parts[3],
    elementChart: parts[4],
    unlocks: parts[5],
  );
});

final rulesProvider = Provider<Smt4Rules?>((ref) {
  final data = ref.watch(gameDataProvider).value;
  return data == null ? null : Smt4Rules(data);
});

/// Settings persisted on the device: theme and which optional demons count.
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.dark,
    this.palette = Palette.strangeJourney,
    this.disabledDemons = const {},
    this.onboarded = false,
    this.loaded = false,
  });

  final ThemeMode themeMode;
  final Palette palette;

  /// True once the user has been through the welcome screen.
  final bool onboarded;
  final Set<String> disabledDemons;
  final bool loaded;

  FusionSettings get fusion => FusionSettings(disabledDemons: disabledDemons);

  AppSettings copyWith({
    ThemeMode? themeMode,
    Palette? palette,
    Set<String>? disabledDemons,
    bool? onboarded,
    bool? loaded,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    palette: palette ?? this.palette,
    onboarded: onboarded ?? this.onboarded,
    disabledDemons: disabledDemons ?? this.disabledDemons,
    loaded: loaded ?? this.loaded,
  );
}

class SettingsNotifier extends Notifier<AppSettings> {
  static const _key = 'demonica.settings.v1';

  @override
  AppSettings build() {
    _load();
    return const AppSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    final data = await ref.read(gameDataProvider.future);
    if (raw == null) {
      state = AppSettings(disabledDemons: data.defaultSettings.disabledDemons, loaded: true);
      return;
    }
    final j = jsonDecode(raw) as Map<String, dynamic>;
    state = AppSettings(
      themeMode: ThemeMode.values.byName(j['themeMode'] as String? ?? 'dark'),
      palette: Palette.values.byName(j['palette'] as String? ?? Palette.strangeJourney.name),
      onboarded:
          j['onboarded'] as bool? ?? true, // settings saved before the welcome screen existed
      disabledDemons: ((j['disabledDemons'] as List?) ?? const []).cast<String>().toSet(),
      loaded: true,
    );
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode({
        'themeMode': state.themeMode.name,
        'palette': state.palette.name,
        'onboarded': state.onboarded,
        'disabledDemons': state.disabledDemons.toList(),
      }),
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _save();
  }

  void setPalette(Palette palette, {ThemeMode? mode}) {
    state = state.copyWith(palette: palette, themeMode: mode);
    _save();
  }

  void setOnboarded(bool v) {
    state = state.copyWith(onboarded: v);
    _save();
  }

  void setDemonsEnabled(Iterable<String> names, bool enabled) {
    final set = {...state.disabledDemons};
    for (final n in names) {
      enabled ? set.remove(n) : set.add(n);
    }
    state = state.copyWith(disabledDemons: set);
    _save();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// Just the fusion part of the settings. Anything that computes recipes
/// watches this instead of [settingsProvider], so changing the palette or
/// the theme does not recompute recipes.
final fusionSettingsProvider = Provider<FusionSettings>(
  (ref) =>
      FusionSettings(disabledDemons: ref.watch(settingsProvider.select((s) => s.disabledDemons))),
);

/// Compendium filters.
class CompendiumFilter {
  const CompendiumFilter({
    this.query = '',
    this.races = const {},
    this.maxLevel,
    this.skill,
    this.showDisabled = false,
  });

  final String query;
  final Set<String> races;
  final int? maxLevel;

  /// Only demons that learn this skill (natively).
  final String? skill;
  final bool showDisabled;

  bool get isActive => races.isNotEmpty || maxLevel != null || skill != null;

  CompendiumFilter copyWith({
    String? query,
    Set<String>? races,
    int? Function()? maxLevel,
    String? Function()? skill,
    bool? showDisabled,
  }) => CompendiumFilter(
    query: query ?? this.query,
    races: races ?? this.races,
    maxLevel: maxLevel != null ? maxLevel() : this.maxLevel,
    skill: skill != null ? skill() : this.skill,
    showDisabled: showDisabled ?? this.showDisabled,
  );
}

class CompendiumFilterNotifier extends Notifier<CompendiumFilter> {
  @override
  CompendiumFilter build() => const CompendiumFilter();

  void setQuery(String q) => state = state.copyWith(query: q);
  void toggleRace(String race) {
    final s = {...state.races};
    s.contains(race) ? s.remove(race) : s.add(race);
    state = state.copyWith(races: s);
  }

  void setRaces(Set<String> races) => state = state.copyWith(races: races);
  void setMaxLevel(int? lvl) => state = state.copyWith(maxLevel: () => lvl);
  void setSkill(String? skill) => state = state.copyWith(skill: () => skill);
  void setShowDisabled(bool v) => state = state.copyWith(showDisabled: v);
  void clear() => state = CompendiumFilter(query: state.query);
}

final compendiumFilterProvider = NotifierProvider<CompendiumFilterNotifier, CompendiumFilter>(
  CompendiumFilterNotifier.new,
);

/// Demons matching the current filter, sorted by level.
final filteredDemonsProvider = Provider<List<Demon>>((ref) {
  final data = ref.watch(gameDataProvider).value;
  if (data == null) return const [];
  final f = ref.watch(compendiumFilterProvider);
  final fusion = ref.watch(fusionSettingsProvider);
  final q = f.query.trim().toLowerCase();
  return [
    for (final d in data.demonsByLevel)
      if ((f.showDisabled || fusion.isEnabled(d.name)) &&
          (q.isEmpty || d.name.toLowerCase().contains(q) || d.race.toLowerCase().contains(q)) &&
          (f.races.isEmpty || f.races.contains(d.race)) &&
          (f.maxLevel == null || d.level <= f.maxLevel!) &&
          (f.skill == null || d.skills.any((s) => s.name == f.skill)))
        d,
  ];
});

/// Tree view preferences.
enum RecipeSort { cheapest, lowestLevel }

class TreePrefs {
  const TreePrefs({this.sort = RecipeSort.cheapest, this.hideElement = false, this.maxLevel});
  final RecipeSort sort;
  final bool hideElement;
  final int? maxLevel;

  TreePrefs copyWith({RecipeSort? sort, bool? hideElement, int? Function()? maxLevel}) => TreePrefs(
    sort: sort ?? this.sort,
    hideElement: hideElement ?? this.hideElement,
    maxLevel: maxLevel != null ? maxLevel() : this.maxLevel,
  );
}

class TreePrefsNotifier extends Notifier<TreePrefs> {
  @override
  TreePrefs build() => const TreePrefs();
  void setSort(RecipeSort s) => state = state.copyWith(sort: s);
  void setHideElement(bool v) => state = state.copyWith(hideElement: v);
  void setMaxLevel(int? v) => state = state.copyWith(maxLevel: () => v);
}

final treePrefsProvider = NotifierProvider<TreePrefsNotifier, TreePrefs>(TreePrefsNotifier.new);

/// Recipes for a demon, filtered and sorted by the tree prefs. The engine
/// caches the raw list; this provider caches the filtered, sorted copy per
/// demon name while the fusion settings and prefs stay the same.
final recipesProvider = Provider.family<List<Recipe>, String>((ref, demonName) {
  final rules = ref.watch(rulesProvider);
  if (rules == null) return const [];
  final settings = ref.watch(fusionSettingsProvider);
  final prefs = ref.watch(treePrefsProvider);
  final data = rules.data;
  final demon = data.demons[demonName];
  if (demon == null) return const [];
  final maxPref = prefs.maxLevel;
  int topLevel(Recipe r) =>
      r.ingredients.map((n) => data.demons[n]?.level ?? 0).fold(0, (a, b) => a > b ? a : b);
  // Work out each recipe's sort keys once instead of inside the comparator.
  final keyed = [
    for (final r in rules.reverseRecipes(demon, settings))
      if (!(prefs.hideElement && r.kind == RecipeKind.element))
        (recipe: r, cost: rules.recipeCost(r), level: topLevel(r)),
  ];
  if (maxPref != null) keyed.removeWhere((k) => k.level > maxPref);
  keyed.sort((a, b) {
    final (first, second) = switch (prefs.sort) {
      RecipeSort.cheapest => (a.cost.compareTo(b.cost), a.level.compareTo(b.level)),
      RecipeSort.lowestLevel => (a.level.compareTo(b.level), a.cost.compareTo(b.cost)),
    };
    return first != 0 ? first : second;
  });
  return [for (final k in keyed) k.recipe];
});

/// Every fusion that uses a demon as an ingredient ("Used in" tab).
final usedInProvider = Provider.family<List<Recipe>, String>((ref, demonName) {
  final rules = ref.watch(rulesProvider);
  final demon = rules?.data.demons[demonName];
  if (rules == null || demon == null) return const [];
  return rules.forwardRecipes(demon, ref.watch(fusionSettingsProvider));
});
