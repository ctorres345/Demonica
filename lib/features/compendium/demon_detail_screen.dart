import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_core/fusion_core.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';
import '../recipes/recipe_row.dart';

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
      return Scaffold(appBar: AppBar(), body: Center(child: Text('No demon called "$demonId".')));
    }
    final dc = context.dc;
    final settings = ref.watch(settingsProvider);
    final recipes = ref.watch(recipesProvider(demon.name));
    final enabled = settings.fusion.isEnabled(demon.name);
    final freeSlots = rules.freeSkillSlots(demon);
    final usedIn = rules.forwardRecipes(demon, settings.fusion).length;

    return Scaffold(
      appBar: AppBar(
        leading: embedded ? null : BackButton(onPressed: () => context.canPop() ? context.pop() : context.go('/smt4/demons')),
        automaticallyImplyLeading: !embedded,
        title: Text.rich(TextSpan(children: [
          TextSpan(text: 'Compendium / ', style: context.tt.labelMedium),
          TextSpan(text: demon.name),
        ])),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.x4, Space.x3, Space.x4, Space.x8),
        children: [
          Wrap(
            spacing: Space.x2,
            runSpacing: Space.x1,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text('${demon.race} · Lv ${demon.level}'.toUpperCase(), style: context.tt.labelSmall),
              AlignmentTag(demon.alignment, full: true),
              FusionTag(demon),
              if (!enabled) Tag('Disabled in settings', color: dc.danger),
            ],
          ),
          const SizedBox(height: Space.x2),
          Text(demon.name, style: context.tt.displaySmall),
          const SizedBox(height: Space.x3),
          _StatsGrid(demon.stats),
          const SizedBox(height: Space.x3),
          ResistRow(resists: demon.resists, order: data.resistElements),
          if (demon.ailments.values.any((r) => r != Resist.none)) ...[
            const SizedBox(height: Space.x2),
            _AilmentLine(demon.ailments),
          ],
          SectionHeader('Skills',
              trailing: demon.isEnemyOnly ? null : '${demon.innateSkillCount} innate · $freeSlots free slots'),
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
            const _Note('Fusion accidents are random. They cannot be planned, so this demon has no recipe tree.')
          else if (demon.isEnemyOnly)
            const _Note('This demon only appears as an enemy. It cannot be fused or recruited.')
          else if (recipes.isEmpty)
            const _Note('No recipe with the current settings. Enable more demons in Settings.')
          else ...[
            for (final r in recipes.take(5))
              Padding(
                padding: const EdgeInsets.only(bottom: Space.x1),
                child: RecipeRow(recipe: r, data: data, cost: rules.recipeCost(r)),
              ),
            if (recipes.length > 5)
              Padding(
                padding: const EdgeInsets.only(top: Space.x1, bottom: Space.x2),
                child: Text('+${recipes.length - 5} more in the tree', style: context.tt.labelMedium?.copyWith(color: dc.accent)),
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
              _LinkLine('Evolves from ${demon.evolvesFrom}', () => context.go('/smt4/demon/${slugify(demon.evolvesFrom!)}')),
            if (demon.evolvesTo != null)
              _LinkLine('Evolves into ${demon.evolvesTo} at level ${demon.evolvesAtLevel}',
                  () => context.go('/smt4/demon/${slugify(demon.evolvesTo!)}')),
          ],
          if (!demon.isEnemyOnly) ...[
            const SectionHeader('Used in fusions'),
            Text('$usedIn fusions use ${demon.name} as an ingredient.', style: context.tt.bodySmall),
          ],
          const SizedBox(height: Space.x4),
          Text('Re-summon from Compendium: ${macca(demon.price)}', style: context.tt.labelMedium),
        ],
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
    final cells = [('HP', s.hp), ('MP', s.mp), ('ST', s.st), ('DX', s.dx), ('MA', s.ma), ('AG', s.ag), ('LU', s.lu)];
    return Row(
      children: [
        for (final (label, v) in cells)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(color: dc.surface, border: Border.all(color: dc.outline), borderRadius: Radii.borderSmall),
                child: Column(
                  children: [
                    Text(label, style: context.tt.labelSmall?.copyWith(fontSize: 9)),
                    Text('$v', style: TextStyle(fontFamily: Fonts.mono, fontSize: 14, fontWeight: FontWeight.w500, color: dc.text)),
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
          child: Row(children: [
            Expanded(child: Text(text, style: context.tt.bodyMedium)),
            Icon(Icons.chevron_right, size: 18, color: context.dc.textMuted),
          ]),
        ),
      );
}
