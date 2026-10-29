import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_core/fusion_core.dart';

import '../saved/saved_model.dart';

/// Which nodes of a recipe tree are open, keyed by a path from the root:
/// a demon node is `Lilith`, one of its recipes `Lilith#Nyx+Succubus`, and an
/// ingredient under it `Lilith#Nyx+Succubus/Nyx`.
///
/// Only one recipe per demon can be open at a time, so the open part of the
/// tree is always a single fusion path that can be saved as a plan.
class TreeExpansion {
  const TreeExpansion(this.open);

  /// Open node keys. Recipe keys map to their recipe, demon keys to null.
  final Map<String, Recipe?> open;

  static String recipeKey(String demonKey, Recipe r) => '$demonKey#${r.ingredients.join('+')}';
  static String childKey(String recipeKey, String name) => '$recipeKey/$name';

  bool isOpen(String key) => open.containsKey(key);

  /// The open recipe directly under a demon node, if any.
  MapEntry<String, Recipe>? openRecipe(String demonKey) {
    final prefix = '$demonKey#';
    for (final e in open.entries) {
      if (e.value != null &&
          e.key.startsWith(prefix) &&
          !e.key.substring(prefix.length).contains('/')) {
        return MapEntry(e.key, e.value!);
      }
    }
    return null;
  }

  /// The open path as plan steps, leaves first. A step's macca counts only
  /// the ingredients that are bought, not the ones fused earlier in the plan.
  List<SavedStep> plan(String rootKey, GameData data) {
    final out = <SavedStep>[];
    bool walk(String demonKey) {
      if (!isOpen(demonKey)) return false;
      final r = openRecipe(demonKey);
      if (r == null) return false;
      var bought = 0;
      for (final name in r.value.ingredients) {
        if (!walk(childKey(r.key, name))) bought += data.demons[name]?.price ?? 0;
      }
      out.add(SavedStep.fromRecipe(r.value, bought));
      return true;
    }

    walk(rootKey);
    return out;
  }

  /// The open map that shows [steps] (leaves first, target last) expanded
  /// under [rootKey].
  static Map<String, Recipe?> fromSteps(String rootKey, List<SavedStep> steps) {
    final open = <String, Recipe?>{rootKey: null};
    final used = List.filled(steps.length, false);
    void place(String demonKey, String name) {
      // The target is the last step; ingredients come before their parent.
      final i = steps.lastIndexWhere((s) => s.result == name);
      if (i < 0 || used[i]) return;
      used[i] = true;
      final r = steps[i].recipe;
      final rk = recipeKey(demonKey, r);
      open[demonKey] = null;
      open[rk] = r;
      for (final ing in r.ingredients) {
        final ck = childKey(rk, ing);
        if (steps.indexed.any((e) => !used[e.$1] && e.$2.result == ing)) {
          place(ck, ing);
        }
      }
    }

    if (steps.isNotEmpty) place(rootKey, steps.last.result);
    return open;
  }
}

class TreeExpansionNotifier extends Notifier<TreeExpansion> {
  TreeExpansionNotifier(this.root);

  /// The root demon's name, which is also the root node's key.
  final String root;

  @override
  TreeExpansion build() => TreeExpansion({root: null});

  void toggleDemon(String key) {
    final next = {...state.open};
    if (next.containsKey(key)) {
      next.removeWhere((k, _) => k == key || k.startsWith('$key#'));
    } else {
      next[key] = null;
    }
    state = TreeExpansion(next);
  }

  /// Opens [r] under [demonKey] and closes its sibling recipes.
  void toggleRecipe(String demonKey, Recipe r) {
    final key = TreeExpansion.recipeKey(demonKey, r);
    final wasOpen = state.isOpen(key);
    final next = {...state.open}..removeWhere((k, _) => k.startsWith('$demonKey#'));
    if (!wasOpen) next[key] = r;
    state = TreeExpansion(next);
  }

  void collapseAll() => state = TreeExpansion({root: null});

  void showSteps(List<SavedStep> steps) =>
      state = TreeExpansion(TreeExpansion.fromSteps(root, steps));
}

final treeExpansionProvider = NotifierProvider.family<TreeExpansionNotifier, TreeExpansion, String>(
  TreeExpansionNotifier.new,
);
