import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_core/fusion_core.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';
import '../recipes/recipe_row.dart';
import '../saved/save_button.dart';

class DemonDetailScreen extends ConsumerWidget {
  const DemonDetailScreen({super.key, required this.demonId, this.embedded = false});
  final String demonId;
  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider).value;
    final rules = ref.watch(rulesProvider);
    if (data == null || rules == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final demon = data.demonsById[demonId];
    if (demon == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('No demon called "$demonId".')),
      );
    }
    final dc = context.dc;
    final settings = ref.watch(settingsProvider);
    final recipes = ref.watch(recipesProvider(demon.name));
    final enabled = settings.fusion.isEnabled(demon.name);
    final freeSlots = rules.freeSkillSlots(demon);
    final usedIn = demon.isEnemyOnly
        ? const <Recipe>[]
        : rules.forwardRecipes(demon, settings.fusion);

    final overview = ListView(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x3, Space.x4, Space.x8),
      children: [
        _StatusLine(demon),
        if (demon.fusion != FusionKind.normal || demon.unlockCategory != null || !enabled) ...[
          const SizedBox(height: Space.x2),
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x1,
            children: [
              FusionTag(demon),
              if (!enabled) Tag('Disabled in settings', color: dc.danger),
            ],
          ),
        ],
        const SizedBox(height: Space.x3),
        _StatsGrid(demon.stats),
        const SizedBox(height: Space.x3),
        ResistRow(resists: demon.resists, order: data.resistElements),
        if (demon.ailments.values.any((r) => r != Resist.none)) ...[
          const SizedBox(height: Space.x2),
          _AilmentLine(demon.ailments),
        ],
        SectionHeader(
          'Skills',
          trailing: demon.isEnemyOnly
              ? null
              : '${demon.innateSkillCount} innate · $freeSlots free slots',
        ),
        for (final s in demon.skills)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.x1),
            child: SkillRow(
              skill: data.skill(s.name),
              learnedAt: s.level,
              onTap: () {
                ref.read(compendiumFilterProvider.notifier).setSkill(s.name);
                context.go('/smt4/demons');
              },
            ),
          ),
        SectionHeader('How to get', trailing: _howToGetTrailing(demon, recipes.length)),
        if (demon.prereq != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.x2),
            child: _Note(demon.prereq!),
          ),
        if (demon.fusion == FusionKind.accident)
          const _Note(
            'Fusion accidents are random. They cannot be planned, so this demon has no recipe tree.',
          )
        else if (demon.isEnemyOnly)
          const _Note('This demon only appears as an enemy. It cannot be fused or recruited.')
        else if (recipes.isEmpty)
          const _Note('No recipe with the current settings. Enable more demons in Settings.')
        else ...[
          for (final r in recipes.take(5))
            Padding(
              padding: const EdgeInsets.only(bottom: Space.x1),
              child: RecipeRow(
                recipe: r,
                data: data,
                cost: rules.recipeCost(r),
                trailing: SaveRecipeButton(recipe: r, cost: rules.recipeCost(r)),
              ),
            ),
          if (recipes.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: Space.x1, bottom: Space.x2),
              child: Text(
                '+${recipes.length - 5} more in the tree',
                style: context.tt.labelMedium?.copyWith(color: dc.accent),
              ),
            ),
          const SizedBox(height: Space.x2),
          FilledButton.icon(
            onPressed: () => context.go('/smt4/demon/${demon.id}/tree'),
            icon: const Icon(Icons.account_tree_outlined, size: 18),
            label: const Text('OPEN RECIPE TREE'),
          ),
        ],
        if (demon.evolvesFrom != null || demon.evolvesTo != null) ...[
          const SectionHeader('Evolution'),
          if (demon.evolvesFrom != null)
            _LinkLine(
              'Evolves from ${demon.evolvesFrom}',
              () => context.go('/smt4/demon/${slugify(demon.evolvesFrom!)}'),
            ),
          if (demon.evolvesTo != null)
            _LinkLine(
              'Evolves into ${demon.evolvesTo} at level ${demon.evolvesAtLevel}',
              () => context.go('/smt4/demon/${slugify(demon.evolvesTo!)}'),
            ),
        ],
        const SizedBox(height: Space.x4),
        Text('Re-summon from Compendium: ${macca(demon.price)}', style: context.tt.labelMedium),
      ],
    );

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          leading: embedded
              ? null
              : BackButton(
                  onPressed: () => context.canPop() ? context.pop() : context.go('/smt4/demons'),
                ),
          automaticallyImplyLeading: !embedded,
          title: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: 'Compendium / ', style: context.tt.labelMedium),
                TextSpan(text: demon.name),
              ],
            ),
          ),
          actions: [if (!demon.isEnemyOnly) SaveDemonButton(name: demon.name)],
          bottom: TabBar(
            tabs: [
              const Tab(text: 'OVERVIEW'),
              Tab(text: 'USED IN (${usedIn.length})'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            overview,
            _UsedInTab(demon: demon, recipes: usedIn),
          ],
        ),
      ),
    );
  }

  String? _howToGetTrailing(Demon d, int count) => switch (d.fusion) {
    FusionKind.special => 'special fusion',
    FusionKind.accident => 'fusion accident',
    FusionKind.enemy => null,
    FusionKind.normal => '$count recipes',
  };
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid(this.s);
  final Stats s;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final cells = [
      ('HP', s.hp),
      ('MP', s.mp),
      ('ST', s.st),
      ('DX', s.dx),
      ('MA', s.ma),
      ('AG', s.ag),
      ('LU', s.lu),
    ];
    return Row(
      children: [
        for (final (label, v) in cells)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: dc.surface,
                  border: Border.all(color: dc.outline),
                  borderRadius: Radii.borderSmall,
                ),
                child: Column(
                  children: [
                    Text(label, style: context.tt.labelSmall?.copyWith(fontSize: 9)),
                    Text(
                      '$v',
                      style: TextStyle(
                        fontFamily: Fonts.mono,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: dc.text,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AilmentLine extends StatelessWidget {
  const _AilmentLine(this.ailments);
  final Map<String, Resist> ailments;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[];
    for (final e in ailments.entries) {
      if (e.value == Resist.none) continue;
      final label = switch (e.value) {
        Resist.weak => 'weak',
        Resist.resist => 'resists',
        Resist.nullify => 'nulls',
        _ => e.value.name,
      };
      parts.add('$label ${e.key}');
    }
    return Text('Ailments: ${parts.join(', ')}', style: context.tt.bodySmall);
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      border: Border.all(color: context.dc.outline, style: BorderStyle.solid),
      borderRadius: Radii.borderSmall,
    ),
    child: Text(text, style: context.tt.bodySmall),
  );
}

class _LinkLine extends StatelessWidget {
  const _LinkLine(this.text, this.onTap);
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(text, style: context.tt.bodyMedium)),
          Icon(Icons.chevron_right, size: 18, color: context.dc.textMuted),
        ],
      ),
    ),
  );
}

/// "LV 75  NIGHT  Lilith  [NEUTRAL-CHAOS]" in one line, like the status
/// screen in the game.
class _StatusLine extends StatelessWidget {
  const _StatusLine(this.demon);
  final Demon demon;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Wrap(
      spacing: Space.x3,
      runSpacing: Space.x1,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'LV ',
                style: context.tt.labelSmall?.copyWith(color: dc.accent),
              ),
              TextSpan(
                text: '${demon.level}',
                style: TextStyle(
                  fontFamily: Fonts.mono,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  color: dc.text,
                ),
              ),
            ],
          ),
        ),
        Text(demon.race.toUpperCase(), style: context.tt.labelLarge?.copyWith(color: dc.textMuted)),
        Text(demon.name, style: context.tt.displaySmall),
        AlignmentTag(demon.alignment, full: true),
      ],
    );
  }
}

/// Forward fusions: every demon this one makes, with which partner.
class _UsedInTab extends ConsumerStatefulWidget {
  const _UsedInTab({required this.demon, required this.recipes});
  final Demon demon;
  final List<Recipe> recipes;

  @override
  ConsumerState<_UsedInTab> createState() => _UsedInTabState();
}

class _UsedInTabState extends ConsumerState<_UsedInTab> {
  bool _highestFirst = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(gameDataProvider).value!;
    final rules = ref.watch(rulesProvider)!;
    final dc = context.dc;
    if (widget.recipes.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(Space.x4),
        child: Text(
          widget.demon.isEnemyOnly
              ? 'Enemy-only demons cannot be used in fusions.'
              : 'No fusion uses ${widget.demon.name} with the current settings.',
          style: context.tt.bodySmall,
        ),
      );
    }
    final sorted = [...widget.recipes]
      ..sort((a, b) {
        final c = data.demon(a.result).level.compareTo(data.demon(b.result).level);
        return _highestFirst ? -c : c;
      });
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, Space.x8),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${sorted.length} fusions use ${widget.demon.name}.',
                style: context.tt.bodySmall,
              ),
            ),
            FilterChip(
              label: Text(_highestFirst ? 'Highest result first' : 'Lowest result first'),
              selected: true,
              showCheckmark: false,
              avatar: Icon(
                _highestFirst ? Icons.arrow_downward : Icons.arrow_upward,
                size: 14,
                color: dc.accent,
              ),
              onSelected: (_) => setState(() => _highestFirst = !_highestFirst),
            ),
          ],
        ),
        const SizedBox(height: Space.x2),
        for (final r in sorted)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.x1),
            child: _ForwardRow(
              partner: data.demon(r.ingredients.firstWhere((n) => n != widget.demon.name)),
              result: data.demon(r.result),
              cost: rules.recipeCost(r),
            ),
          ),
      ],
    );
  }
}

/// "+ Partner (Race 12)  →  Result (Race 20)   1 020 ¥".
class _ForwardRow extends StatelessWidget {
  const _ForwardRow({required this.partner, required this.result, required this.cost});
  final Demon partner;
  final Demon result;
  final int cost;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    Widget name(Demon d) => InkWell(
      onTap: () => context.go('/smt4/demon/${d.id}'),
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: d.name,
              style: context.tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: ' ${d.race} ${d.level}', style: context.tt.labelMedium),
          ],
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: dc.surface,
        border: Border.all(color: dc.outline),
        borderRadius: Radii.borderSmall,
      ),
      child: Row(
        children: [
          Text('+ ', style: context.tt.labelMedium),
          Flexible(child: name(partner)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.x2),
            child: Icon(Icons.arrow_forward, size: 14, color: dc.accent),
          ),
          Expanded(child: name(result)),
          Text(macca(cost), style: context.tt.labelMedium),
        ],
      ),
    );
  }
}
