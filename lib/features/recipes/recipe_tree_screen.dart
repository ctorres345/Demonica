import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_core/fusion_core.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';
import '../saved/save_button.dart';
import '../saved/saved_model.dart';
import '../saved/saved_store.dart';
import 'recipe_row.dart';
import 'tree_state.dart';

/// The expandable recipe tree: target at the top, its recipes below, and any
/// ingredient can be expanded into its own recipes in place.
class RecipeTreeScreen extends ConsumerWidget {
  const RecipeTreeScreen({super.key, required this.demonId, this.embedded = false});
  final String demonId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider).value;
    if (data == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final demon = data.demonsById[demonId];
    if (demon == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('No demon called "$demonId".')),
      );
    }
    final prefs = ref.watch(treePrefsProvider);
    final notifier = ref.read(treePrefsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/smt4/demon/${demon.id}'),
        ),
        title: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: 'Tree / ', style: context.tt.labelMedium),
              TextSpan(text: demon.name),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Save this path',
            icon: const Icon(Icons.bookmark_add_outlined),
            onPressed: () => _savePath(context, ref, demon),
          ),
          IconButton(
            tooltip: 'Open demon page',
            icon: const Icon(Icons.info_outline),
            onPressed: () => context.go('/smt4/demon/${demon.id}'),
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x2),
              children: [
                _chip(
                  'Cheapest first',
                  prefs.sort == RecipeSort.cheapest,
                  () => notifier.setSort(RecipeSort.cheapest),
                ),
                _chip(
                  'Lowest level first',
                  prefs.sort == RecipeSort.lowestLevel,
                  () => notifier.setSort(RecipeSort.lowestLevel),
                ),
                _chip(
                  'Hide element recipes',
                  prefs.hideElement,
                  () => notifier.setHideElement(!prefs.hideElement),
                ),
                _chip(
                  prefs.maxLevel == null
                      ? 'Max ingredient level'
                      : 'Ingredients ≤ Lv ${prefs.maxLevel}',
                  prefs.maxLevel != null,
                  () => _pickMaxLevel(context, prefs.maxLevel, notifier.setMaxLevel),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.x4, Space.x1, Space.x4, Space.x8),
              children: [
                _DemonNode(demon: demon, root: demon.name, nodeKey: demon.name, depth: 0),
                const SizedBox(height: Space.x4),
                Text(
                  'Tap a recipe to expand its ingredients. Tap an ingredient to expand its own recipes. '
                  'Only one recipe per demon stays open, so what you see is one fusion path: '
                  'save it with the bookmark button at the top. '
                  'Costs are the macca to re-summon both ingredients from the Compendium.',
                  style: context.tt.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _savePath(BuildContext context, WidgetRef ref, Demon demon) {
    final data = ref.read(gameDataProvider).value!;
    final steps = ref.read(treeExpansionProvider(demon.name)).plan(demon.name, data);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (steps.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Open a recipe first. The open recipes are what gets saved.')),
      );
      return;
    }
    final entry = SavedEntry.path(steps);
    ref.read(savedProvider.notifier).add(entry);
    final what = steps.length == 1
        ? 'Saved this recipe for ${demon.name}'
        : 'Saved a ${steps.length}-step plan for ${demon.name} · ${macca(entry.macca)}';
    messenger.showSnackBar(
      SnackBar(
        content: Text(what),
        action: SnackBarAction(label: 'VIEW', onPressed: () => context.go('/saved')),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => Padding(
    padding: const EdgeInsets.only(right: Space.x2),
    child: FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
    ),
  );

  Future<void> _pickMaxLevel(BuildContext context, int? current, ValueChanged<int?> onChanged) {
    return showModalBottomSheet(
      context: context,
      builder: (ctx) => _MaxLevelSheet(initial: current ?? 99, onChanged: onChanged),
    );
  }
}

/// A demon in the tree. Expanding it lists its recipes.
class _DemonNode extends ConsumerStatefulWidget {
  const _DemonNode({
    required this.demon,
    required this.root,
    required this.nodeKey,
    required this.depth,
  });
  final Demon demon;

  /// The tree's root demon, which names the expansion state.
  final String root;
  final String nodeKey;
  final int depth;

  @override
  ConsumerState<_DemonNode> createState() => _DemonNodeState();
}

class _DemonNodeState extends ConsumerState<_DemonNode> {
  int _shown = 8;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final d = widget.demon;
    final recipes = ref.watch(recipesProvider(d.name));
    final tree = ref.watch(treeExpansionProvider(widget.root));
    final open = tree.isOpen(widget.nodeKey);
    final canExpand = recipes.isNotEmpty;
    final countLabel = switch (d.fusion) {
      FusionKind.special => 'special',
      FusionKind.accident => 'accident',
      FusionKind.enemy => 'enemy only',
      FusionKind.normal => '${recipes.length} recipes',
    };
    // A recipe opened from the Saved screen stays visible even when it sits
    // past the first rows or the current filters hide it.
    final chosen = tree.openRecipe(widget.nodeKey)?.value;
    final visible = recipes.take(_shown).toList();
    if (chosen != null && !visible.contains(chosen)) visible.insert(0, chosen);
    final header = InkWell(
      onTap: canExpand
          ? () => ref.read(treeExpansionProvider(widget.root).notifier).toggleDemon(widget.nodeKey)
          : null,
      borderRadius: Radii.borderSmall,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: widget.depth == 0 ? dc.accent.withValues(alpha: 0.10) : dc.surface,
          border: Border.all(color: widget.depth == 0 ? dc.accent : dc.outline),
          borderRadius: Radii.borderSmall,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: Text(
                canExpand ? (open ? '▾' : '▸') : '·',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: Fonts.mono,
                  color: open && canExpand ? dc.accent : dc.textMuted,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: d.name,
                      style: context.tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: '  ${d.race} ${d.level}', style: context.tt.labelMedium),
                  ],
                ),
              ),
            ),
            if (d.fusion != FusionKind.normal || d.unlockCategory != null) ...[
              FusionTag(d),
              const SizedBox(width: 8),
            ],
            Text(countLabel, style: context.tt.labelMedium),
            IconButton(
              tooltip: 'Open ${d.name}',
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.open_in_new, size: 16, color: dc.textMuted),
              onPressed: () => context.go('/smt4/demon/${d.id}'),
            ),
          ],
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (open && canExpand)
          _Indent(
            accent: widget.depth.isOdd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final r in visible)
                  Padding(
                    padding: const EdgeInsets.only(top: Space.x1),
                    child: _RecipeNode(
                      recipe: r,
                      root: widget.root,
                      demonKey: widget.nodeKey,
                      depth: widget.depth + 1,
                    ),
                  ),
                if (recipes.length > _shown)
                  TextButton(
                    onPressed: () => setState(() => _shown += 10),
                    style: TextButton.styleFrom(alignment: Alignment.centerLeft),
                    child: Text('+${recipes.length - _shown} more recipes'),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A recipe row. Expanding it shows each ingredient as a demon node.
class _RecipeNode extends ConsumerWidget {
  const _RecipeNode({
    required this.recipe,
    required this.root,
    required this.demonKey,
    required this.depth,
  });
  final Recipe recipe;
  final String root;
  final String demonKey;
  final int depth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rules = ref.watch(rulesProvider)!;
    final data = rules.data;
    final key = TreeExpansion.recipeKey(demonKey, recipe);
    final open = ref.watch(treeExpansionProvider(root).select((t) => t.isOpen(key)));
    // Stop the tree at a sensible depth so it cannot recurse forever.
    final canExpand = depth < 8;
    final cost = rules.recipeCost(recipe);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RecipeRow(
          recipe: recipe,
          data: data,
          cost: cost,
          highlight: open,
          expanded: canExpand ? open : null,
          onTap: canExpand
              ? () => ref.read(treeExpansionProvider(root).notifier).toggleRecipe(demonKey, recipe)
              : null,
          trailing: SaveRecipeButton(recipe: recipe, cost: cost),
        ),
        if (open && canExpand)
          _Indent(
            accent: depth.isOdd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final name in recipe.ingredients)
                  if (data.demons[name] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: Space.x1),
                      child: _DemonNode(
                        demon: data.demon(name),
                        root: root,
                        nodeKey: TreeExpansion.childKey(key, name),
                        depth: depth + 1,
                      ),
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Indent extends StatelessWidget {
  const _Indent({required this.child, required this.accent});
  final Widget child;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.only(left: 10),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: accent ? dc.accent.withValues(alpha: 0.5) : dc.outline, width: 2),
        ),
      ),
      child: child,
    );
  }
}

class _MaxLevelSheet extends StatefulWidget {
  const _MaxLevelSheet({required this.initial, required this.onChanged});
  final int initial;
  final ValueChanged<int?> onChanged;

  @override
  State<_MaxLevelSheet> createState() => _MaxLevelSheetState();
}

class _MaxLevelSheetState extends State<_MaxLevelSheet> {
  late double _v = widget.initial.toDouble();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.x4, Space.x3, Space.x2, 0),
            child: Row(
              children: [
                Text('Max ingredient level', style: context.tt.titleLarge),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    widget.onChanged(null);
                    Navigator.pop(context);
                  },
                  child: const Text('Clear'),
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x4),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _v,
                    min: 1,
                    max: 99,
                    divisions: 98,
                    onChanged: (v) => setState(() => _v = v),
                    onChangeEnd: (v) => widget.onChanged(v.round()),
                  ),
                ),
                SizedBox(width: 56, child: LevelBadge(_v.round(), size: 22)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(Space.x4),
            child: Text(
              'Hides recipes that need an ingredient above this level. Set it to your level.',
              style: context.tt.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
