import 'dart:convert';

import 'package:fusion_core/fusion_core.dart';

/// What a saved entry holds.
enum SavedType {
  /// Just the demon: "I want this one later", no recipe picked yet.
  demon,

  /// One recipe for the demon.
  recipe,

  /// A whole fusion path: every recipe needed, leaves first.
  path,
}

/// One fusion in a saved recipe or plan.
class SavedStep {
  const SavedStep({
    required this.result,
    required this.ingredients,
    required this.kind,
    required this.macca,
    this.done = false,
  });

  factory SavedStep.fromRecipe(Recipe r, int macca) =>
      SavedStep(result: r.result, ingredients: r.ingredients, kind: r.kind, macca: macca);

  final String result;
  final List<String> ingredients;
  final RecipeKind kind;

  /// Macca to buy the ingredients of this step that no earlier step makes.
  final int macca;
  final bool done;

  Recipe get recipe => Recipe(result: result, ingredients: ingredients, kind: kind);

  SavedStep copyWith({bool? done}) => SavedStep(
    result: result,
    ingredients: ingredients,
    kind: kind,
    macca: macca,
    done: done ?? this.done,
  );

  Map<String, dynamic> toJson() => {
    'result': result,
    'ingredients': ingredients,
    'kind': kind.name,
    'macca': macca,
    'done': done,
  };

  static SavedStep fromJson(Map<String, dynamic> j) => SavedStep(
    result: j['result'] as String,
    ingredients: (j['ingredients'] as List).cast<String>(),
    kind: RecipeKind.values.byName(j['kind'] as String),
    macca: (j['macca'] as num?)?.toInt() ?? 0,
    done: j['done'] as bool? ?? false,
  );
}

/// A bookmark on the Saved screen.
class SavedEntry {
  const SavedEntry({
    required this.id,
    required this.type,
    required this.result,
    required this.savedAt,
    this.steps = const [],
    this.note = '',
    this.done = false,
  });

  factory SavedEntry.demon(String name, {DateTime? at}) => SavedEntry(
    id: demonId(name),
    type: SavedType.demon,
    result: name,
    savedAt: at ?? DateTime.now(),
  );

  factory SavedEntry.recipe(Recipe r, int macca, {DateTime? at}) => SavedEntry(
    id: recipeId(r),
    type: SavedType.recipe,
    result: r.result,
    savedAt: at ?? DateTime.now(),
    steps: [SavedStep.fromRecipe(r, macca)],
  );

  /// [steps] are in fusion order: leaves first, the target last.
  factory SavedEntry.path(List<SavedStep> steps, {DateTime? at}) {
    if (steps.length == 1) {
      return SavedEntry.recipe(steps.single.recipe, steps.single.macca, at: at);
    }
    return SavedEntry(
      id: pathId(steps),
      type: SavedType.path,
      result: steps.last.result,
      savedAt: at ?? DateTime.now(),
      steps: steps,
    );
  }

  /// Ids are built from the content, so saving the same thing twice, or
  /// importing a file with it, lands on the same entry.
  static String demonId(String name) => 'd:$name';
  static String recipeId(Recipe r) => 'r:${r.result}:${r.ingredients.join('+')}';
  static String pathId(List<SavedStep> steps) =>
      'p:${steps.last.result}:${steps.map((s) => s.ingredients.join('+')).join('|')}';

  final String id;
  final SavedType type;

  /// The target demon's name.
  final String result;
  final DateTime savedAt;
  final List<SavedStep> steps;
  final String note;
  final bool done;

  /// Total macca to buy every ingredient the plan does not fuse itself.
  int get macca => steps.fold(0, (a, s) => a + s.macca);
  int get stepsDone => steps.where((s) => s.done).length;

  SavedEntry copyWith({String? note, bool? done, List<SavedStep>? steps}) => SavedEntry(
    id: id,
    type: type,
    result: result,
    savedAt: savedAt,
    steps: steps ?? this.steps,
    note: note ?? this.note,
    done: done ?? this.done,
  );

  /// Ticking the entry ticks every step; ticking the last step ticks the entry.
  SavedEntry withDone(bool v) => copyWith(
    done: v,
    steps: [for (final s in steps) s.copyWith(done: v)],
  );

  SavedEntry withStepDone(int index, bool v) {
    final next = [...steps];
    next[index] = next[index].copyWith(done: v);
    return copyWith(steps: next, done: next.every((s) => s.done));
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'result': result,
    'savedAt': savedAt.toUtc().toIso8601String(),
    'note': note,
    'done': done,
    if (steps.isNotEmpty) 'steps': [for (final s in steps) s.toJson()],
  };

  static SavedEntry fromJson(Map<String, dynamic> j) => SavedEntry(
    id: j['id'] as String,
    type: SavedType.values.byName(j['type'] as String),
    result: j['result'] as String,
    savedAt: DateTime.parse(j['savedAt'] as String),
    note: j['note'] as String? ?? '',
    done: j['done'] as bool? ?? false,
    steps: [
      for (final s in (j['steps'] as List?) ?? const [])
        SavedStep.fromJson(s as Map<String, dynamic>),
    ],
  );
}

/// The file format for storage and export.
abstract final class SavedFile {
  static const format = 'demonica.saved';
  static const version = 1;

  static String encode(List<SavedEntry> items, {String game = 'smt4', bool pretty = false}) {
    final map = {
      'format': format,
      'version': version,
      'game': game,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'items': [for (final e in items) e.toJson()],
    };
    return pretty ? const JsonEncoder.withIndent('  ').convert(map) : jsonEncode(map);
  }

  /// Reads a saved file. Throws [FormatException] with a readable message
  /// when the file is not one of ours or is from a newer version. Entries
  /// that do not parse, or name a demon [knownDemon] rejects, are skipped
  /// and counted.
  static ({List<SavedEntry> items, int skipped}) decode(
    String text, {
    bool Function(String name)? knownDemon,
  }) {
    final Object? raw;
    try {
      raw = jsonDecode(text);
    } on FormatException {
      throw const FormatException('This file is not JSON.');
    }
    if (raw is! Map<String, dynamic> || raw['format'] != format) {
      throw const FormatException('This is not a Demonica saved-recipes file.');
    }
    final v = raw['version'];
    if (v is! int || v > version) {
      throw const FormatException(
        'This file was made by a newer version of Demonica. Update the app and try again.',
      );
    }
    final items = <SavedEntry>[];
    var skipped = 0;
    for (final j in (raw['items'] as List?) ?? const []) {
      try {
        final e = SavedEntry.fromJson(j as Map<String, dynamic>);
        final names = [e.result, for (final s in e.steps) ...s.ingredients];
        if (knownDemon != null && !names.every(knownDemon)) {
          skipped++;
          continue;
        }
        items.add(e);
      } catch (_) {
        skipped++;
      }
    }
    return (items: items, skipped: skipped);
  }
}
