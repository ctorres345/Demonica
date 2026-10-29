import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';

Future<void> showRacePicker(BuildContext context, WidgetRef ref, List<String> races) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      builder: (ctx, scroll) => Consumer(
        builder: (ctx, ref, _) {
          final selected = ref.watch(compendiumFilterProvider).races;
          return Column(
            children: [
              SheetHeader(
                'Race',
                onClear: () => ref.read(compendiumFilterProvider.notifier).setRaces({}),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x6),
                  children: [
                    Wrap(
                      spacing: Space.x2,
                      runSpacing: Space.x2,
                      children: [
                        for (final r in races)
                          FilterChip(
                            label: Text(r),
                            selected: selected.contains(r),
                            onSelected: (_) =>
                                ref.read(compendiumFilterProvider.notifier).toggleRace(r),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    ),
  );
}

Future<void> showLevelPicker(BuildContext context, WidgetRef ref, int? current) => showLevelSheet(
  context,
  title: 'Max level',
  help: 'Shows demons at or below this level. Set it to your current level to see what you can fuse now.',
  current: current,
  onChanged: ref.read(compendiumFilterProvider.notifier).setMaxLevel,
);

Future<void> showSkillPicker(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (ctx, scroll) => _SkillSheet(scroll: scroll),
    ),
  );
}

class _SkillSheet extends ConsumerStatefulWidget {
  const _SkillSheet({required this.scroll});
  final ScrollController scroll;

  @override
  ConsumerState<_SkillSheet> createState() => _SkillSheetState();
}

class _SkillSheetState extends ConsumerState<_SkillSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(gameDataProvider).value;
    if (data == null) return const SizedBox.shrink();
    final q = _q.toLowerCase();
    final skills =
        data.skills.values.where((s) => q.isEmpty || s.name.toLowerCase().contains(q)).toList()
          ..sort((a, b) => a.name.compareTo(b.name));
    return Column(
      children: [
        SheetHeader(
          'Who learns this skill?',
          onClear: () {
            ref.read(compendiumFilterProvider.notifier).setSkill(null);
            Navigator.pop(context);
          },
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x2),
          child: TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _q = v),
            decoration: const InputDecoration(hintText: 'Type a skill, e.g. Mediarahan'),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: widget.scroll,
            padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x6),
            itemCount: skills.length,
            itemBuilder: (ctx, i) {
              final s = skills[i];
              final learners = data.learnerCounts[s.name] ?? 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: Space.x1),
                child: SkillRow(
                  skill: s,
                  learnedAt: null,
                  trailing: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text('$learners', style: context.tt.labelMedium),
                  ),
                  onTap: () {
                    ref.read(compendiumFilterProvider.notifier).setSkill(s.name);
                    Navigator.pop(context);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
