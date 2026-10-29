import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_core/fusion_core.dart';

import '../../design_system/tokens.dart';
import 'saved_model.dart';
import 'saved_store.dart';

/// Bookmark toggle for one recipe. Filled when the recipe is saved.
class SaveRecipeButton extends ConsumerWidget {
  const SaveRecipeButton({super.key, required this.recipe, required this.cost});
  final Recipe recipe;
  final int cost;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(
      savedIdsProvider.select((s) => s.contains(SavedEntry.recipeId(recipe))),
    );
    return _BookmarkIcon(
      saved: saved,
      tooltip: saved ? 'Remove from Saved' : 'Save this recipe',
      size: 18,
      onPressed: () => ref.read(savedProvider.notifier).toggleRecipe(recipe, cost),
    );
  }
}

/// Bookmark toggle for a demon, without a recipe picked yet.
class SaveDemonButton extends ConsumerWidget {
  const SaveDemonButton({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedIdsProvider.select((s) => s.contains(SavedEntry.demonId(name))));
    return _BookmarkIcon(
      saved: saved,
      tooltip: saved ? 'Remove $name from Saved' : 'Bookmark $name',
      onPressed: () => ref.read(savedProvider.notifier).toggleDemon(name),
    );
  }
}

class _BookmarkIcon extends StatelessWidget {
  const _BookmarkIcon({
    required this.saved,
    required this.tooltip,
    required this.onPressed,
    this.size,
  });
  final bool saved;
  final String tooltip;
  final VoidCallback onPressed;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return IconButton(
      tooltip: tooltip,
      visualDensity: size == null ? null : VisualDensity.compact,
      isSelected: saved,
      icon: Icon(Icons.bookmark_border, size: size, color: dc.textMuted),
      selectedIcon: Icon(Icons.bookmark, size: size, color: dc.accent),
      onPressed: onPressed,
    );
  }
}
