import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_core/fusion_core.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';
import '../recipes/tree_state.dart';
import '../saved/saved_model.dart';
import '../saved/saved_store.dart';
import 'planner_store.dart';

/// Pick a target and the skills it should end with; get numbered fusion
/// steps with tick boxes. Nothing about the player's game is asked.
/// [demonId] and [skills] come from a shared link and fill the inputs once.
class PlannerScreen extends ConsumerStatefulWidget {
  const PlannerScreen({super.key, this.demonId, this.skills});
  final String? demonId;
  final String? skills;

  @override
  ConsumerState<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends ConsumerState<PlannerScreen> {
  bool _linkApplied = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(gameDataProvider).value;
    if (data != null && !_linkApplied) {
      _linkApplied = true;
      if (widget.demonId != null) {
        Future.microtask(
          () => ref.read(plannerProvider.notifier).openLink(widget.demonId, widget.skills),
        );
      }
    }
    final rules = ref.watch(rulesProvider);
    if (data == null || rules == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final s = ref.watch(plannerProvider);
    final notifier = ref.read(plannerProvider.notifier);
    final target = data.demons[s.target];
    final dc = context.dc;

    return Scaffold(
      appBar: AppBar(title: const Text('PLAN')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, Space.x8),
            children: [
              Text(
                'Pick a demon and the skills it should end with. Demonica finds the fusions '
                'and tells you which skills to keep at each step.',
                style: context.tt.bodySmall,
              ),
              const SectionHeader('1 · Target demon'),
              if (target == null)
                OutlinedButton.icon(
                  onPressed: () => _pickDemon(context, ref, data),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('PICK A DEMON'),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: dc.surface,
                    border: Border.all(color: dc.outline),
                    borderRadius: Radii.borderSmall,
                  ),
                  child: DemonTile(
                    demon: target,
                    subtitle: '${target.race} · tap to change',
                    onTap: () => _pickDemon(context, ref, data),
                  ),
                ),
              SectionHeader(
                '2 · Wanted skills',
                trailing: target == null ? null : _slotText(rules, target, s.skills),
              ),
              Wrap(
                spacing: Space.x2,
                runSpacing: Space.x2,
                children: [
                  for (final name in s.skills)
                    _SkillChip(
                      skill: data.skill(name),
                      learnedAt: target?.skills.where((l) => l.name == name).firstOrNull?.level,
                      onDeleted: () => notifier.removeSkill(name),
                    ),
                  ActionChip(
                    avatar: Icon(Icons.add, size: 16, color: dc.accent),
                    label: const Text('Add skill'),
                    onPressed: () => _pickSkill(context, ref, data, target),
                  ),
                ],
              ),
              const SizedBox(height: Space.x2),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Allow leveling ingredients', style: context.tt.bodyMedium),
                        Text(
                          'Some skills are only learned by leveling up. Turn off to use only '
                          'skills demons know when summoned.',
                          style: context.tt.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: Space.x3),
                  Switch(value: s.allowLevelUps, onChanged: notifier.setAllowLevelUps),
                ],
              ),
              const SizedBox(height: Space.x2),
              FilledButton.icon(
                onPressed: target == null || s.running ? null : notifier.run,
                icon: const Icon(Icons.route_outlined, size: 18),
                label: const Text('FIND FUSIONS'),
              ),
              const SizedBox(height: Space.x4),
              if (s.running)
                const Padding(
                  padding: EdgeInsets.all(Space.x6),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (s.result != null && target != null)
                _ResultView(state: s, target: target, data: data),
            ],
          ),
        ),
      ),
    );
  }

  String _slotText(GameRules rules, Demon target, List<String> skills) {
    final own = {for (final l in target.skills) l.name};
    final inherit = skills.where((k) => !own.contains(k)).length;
    return '$inherit to inherit · ${rules.freeSkillSlots(target)} slots free';
  }

  Future<void> _pickDemon(BuildContext context, WidgetRef ref, GameData data) async {
    final settings = ref.read(fusionSettingsProvider);
    final demons = [
      for (final d in data.demonsByLevel)
        if ((d.fusion == FusionKind.normal || d.fusion == FusionKind.special) &&
            settings.isEnabled(d.name))
          d,
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SearchSheet(
        title: 'Target demon',
        hint: 'Search demons',
        count: demons.length,
        filter: (q, i) =>
            demons[i].name.toLowerCase().contains(q) || demons[i].race.toLowerCase().contains(q),
        itemBuilder: (ctx, i) =>
            DemonTile(demon: demons[i], onTap: () => Navigator.pop(ctx, demons[i].name)),
      ),
    );
    if (picked != null) ref.read(plannerProvider.notifier).setTarget(picked);
  }

  Future<void> _pickSkill(BuildContext context, WidgetRef ref, GameData data, Demon? target) async {
    final chosen = ref.read(plannerProvider).skills.toSet();
    final skills = data.skills.values.where((s) => !chosen.contains(s.name)).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SearchSheet(
        title: 'Add a skill',
        hint: 'Search skills',
        count: skills.length,
        filter: (q, i) => skills[i].name.toLowerCase().contains(q),
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x1),
          child: SkillRow(
            skill: skills[i],
            learnedAt: target?.skills.where((l) => l.name == skills[i].name).firstOrNull?.level,
            onTap: () => Navigator.pop(ctx, skills[i].name),
          ),
        ),
      ),
    );
    if (picked != null) ref.read(plannerProvider.notifier).addSkill(picked);
  }
}

/// A wanted skill. Skills the target learns itself say so.
class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.skill, required this.learnedAt, required this.onDeleted});
  final Skill skill;
  final int? learnedAt;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    final own = switch (learnedAt) {
      null => '',
      0 => ' · knows it',
      final l => ' · learns at Lv $l',
    };
    return InputChip(
      avatar: ElementDot(skill.element),
      label: Text('${skill.name}$own'),
      deleteButtonTooltipMessage: 'Remove ${skill.name}',
      onDeleted: onDeleted,
    );
  }
}

/// A bottom sheet with a search field over a list.
class _SearchSheet extends StatefulWidget {
  const _SearchSheet({
    required this.title,
    required this.hint,
    required this.count,
    required this.filter,
    required this.itemBuilder,
  });
  final String title;
  final String hint;
  final int count;
  final bool Function(String query, int index) filter;
  final IndexedWidgetBuilder itemBuilder;

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.trim().toLowerCase();
    final shown = [
      for (var i = 0; i < widget.count; i++)
        if (q.isEmpty || widget.filter(q, i)) i,
    ];
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.x4, Space.x3, Space.x2, 0),
              child: Row(
                children: [
                  Text(widget.title, style: context.tt.titleLarge),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(Space.x4),
              child: TextField(
                autofocus: true,
                onChanged: (v) => setState(() => _q = v),
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.search, size: 18),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: shown.length,
                itemBuilder: (ctx, i) => widget.itemBuilder(ctx, shown[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The plan, or a plain explanation of why there is none.
class _ResultView extends ConsumerWidget {
  const _ResultView({required this.state, required this.target, required this.data});
  final PlannerState state;
  final Demon target;
  final GameData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = state.result!;
    final dc = context.dc;
    if (!result.found) {
      return Container(
        padding: const EdgeInsets.all(Space.x4),
        decoration: BoxDecoration(
          color: dc.surface,
          border: Border.all(color: dc.danger),
          borderRadius: Radii.borderSmall,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No plan found', style: context.tt.titleMedium?.copyWith(color: dc.danger)),
            const SizedBox(height: Space.x2),
            Text(_why(result), style: context.tt.bodySmall),
          ],
        ),
      );
    }
    final plan = state.plan!;
    final entry = SavedEntry.fromPlan(plan);
    final saved = ref.watch(
      savedProvider.select((l) => l.where((e) => e.id == entry.id).firstOrNull),
    );
    final notifier = ref.read(savedProvider.notifier);
    void tick(int i, bool v) {
      if (saved == null) notifier.add(entry);
      notifier.setStepDone(entry.id, i, v);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (result.plans.length > 1)
          Wrap(
            spacing: Space.x2,
            children: [
              for (final (i, p) in result.plans.indexed)
                ChoiceChip(
                  label: Text(
                    ref.watch(showPricesProvider)
                        ? 'Option ${i + 1} · ${macca(p.totalMacca)}'
                        : 'Option ${i + 1}',
                  ),
                  selected: state.option == i,
                  showCheckmark: false,
                  onSelected: (_) => ref.read(plannerProvider.notifier).showOption(i),
                ),
            ],
          ),
        const SizedBox(height: Space.x3),
        Container(
          decoration: BoxDecoration(
            color: dc.surface,
            border: Border.all(color: dc.outline),
            borderRadius: Radii.borderSmall,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x1, Space.x2),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.steps.length == 1 ? '1 fusion' : '${plan.steps.length} fusions',
                            style: context.tt.titleMedium,
                          ),
                          if (ref.watch(showPricesProvider))
                            Text('Total ${macca(plan.totalMacca)}', style: context.tt.labelMedium),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(treeExpansionProvider(target.name).notifier)
                            .showSteps(entry.steps);
                        context.go('/smt4/demon/${target.id}/tree');
                      },
                      child: const Text('SHOW IN TREE'),
                    ),
                    IconButton(
                      tooltip: saved == null ? 'Save this plan' : 'Remove from Saved',
                      isSelected: saved != null,
                      icon: Icon(Icons.bookmark_border, color: dc.textMuted),
                      selectedIcon: Icon(Icons.bookmark, color: dc.accent),
                      onPressed: () =>
                          saved == null ? notifier.add(entry) : notifier.remove(entry.id),
                    ),
                  ],
                ),
              ),
              if (plan.learnedByTarget.isNotEmpty)
                _Line(
                  icon: Icons.school_outlined,
                  text:
                      '${target.name} learns by itself: ${[for (final e in plan.learnedByTarget.entries) e.value == 0 ? '${e.key} (knows it)' : '${e.key} (Lv ${e.value})'].join(', ')}',
                ),
              for (final (i, step) in plan.steps.indexed)
                _PlanStep(
                  index: i,
                  step: step,
                  data: data,
                  done: saved?.steps[i].done ?? false,
                  onChanged: (v) => tick(i, v),
                ),
            ],
          ),
        ),
        const SizedBox(height: Space.x2),
        Text(
          saved == null
              ? 'Ticking a step saves the plan, so your ticks stay in the Saved tab.'
              : 'Saved. Ticks are kept in the Saved tab.',
          style: context.tt.bodySmall,
        ),
      ],
    );
  }

  String _why(PlanResult r) => switch (r.failure!) {
    PlanFailure.notFusable =>
      '${target.name} cannot be made by fusion with your current Settings '
          '(it is a fusion accident, enemy-only, or turned off).',
    PlanFailure.uniqueSkill =>
      '${r.failedSkills.join(', ')} '
          '${r.failedSkills.length == 1 ? 'is a unique skill' : 'are unique skills'} '
          'and cannot be passed on by fusion.',
    PlanFailure.notEnoughSlots =>
      '${target.name} has ${r.freeSlots} free skill slots, but ${r.failedSkills.length} '
          'of these skills would have to be inherited. Remove some skills.',
    PlanFailure.depthLimit =>
      'No chain of up to 3 fusions carries all of these skills. Try fewer skills, '
          '${state.allowLevelUps ? '' : 'allow leveling ingredients, '}or another target.',
  };
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, Space.x2),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: dc.outline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: dc.accent),
          const SizedBox(width: Space.x2),
          Expanded(child: Text(text, style: context.tt.bodySmall)),
        ],
      ),
    );
  }
}

/// "2. Fuse Nyx × Succubus → Lilith", what to level first, which skills to keep.
class _PlanStep extends ConsumerWidget {
  const _PlanStep({
    required this.index,
    required this.step,
    required this.data,
    required this.done,
    required this.onChanged,
  });
  final int index;
  final FusionStep step;
  final GameData data;
  final bool done;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dc = context.dc;
    String name(String n) {
      final d = data.demons[n];
      return d == null ? n : '$n (${d.race} ${d.level})';
    }

    final muted = done ? dc.textMuted : dc.text;
    final strike = done ? TextDecoration.lineThrough : null;
    return InkWell(
      onTap: () => onChanged(!done),
      child: Container(
        padding: const EdgeInsets.fromLTRB(Space.x2, Space.x1, Space.x4, Space.x2),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: dc.outline)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(value: done, onChanged: (v) => onChanged(v ?? false)),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STEP ${index + 1}',
                      style: context.tt.labelSmall?.copyWith(color: dc.accent),
                    ),
                    for (final e in step.levelUps.entries)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'First level ${e.key} to Lv ${e.value}',
                          style: context.tt.bodySmall?.copyWith(color: muted, decoration: strike),
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(text: step.ingredients.map(name).join(' × ')),
                          TextSpan(
                            text: '  →  ',
                            style: TextStyle(color: dc.accent),
                          ),
                          TextSpan(
                            text: step.result,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                      style: context.tt.bodyMedium?.copyWith(color: muted, decoration: strike),
                    ),
                    if (step.skillsToPick.isNotEmpty) ...[
                      const SizedBox(height: Space.x1),
                      Wrap(
                        spacing: Space.x1,
                        runSpacing: Space.x1,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text('Keep', style: context.tt.labelSmall),
                          for (final k in step.skillsToPick) Tag(k, color: dc.accent),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, left: Space.x2),
              child: Text(
                step.macca > 0 && ref.watch(showPricesProvider) ? macca(step.macca) : '',
                style: context.tt.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
