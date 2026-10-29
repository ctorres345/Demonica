import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';

/// Reverse skill lookup: pick a skill, see who learns it.
class SkillsScreen extends ConsumerStatefulWidget {
  const SkillsScreen({super.key});

  @override
  ConsumerState<SkillsScreen> createState() => _SkillsScreenState();
}

class _SkillsScreenState extends ConsumerState<SkillsScreen> {
  String _q = '';
  String? _element;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(gameDataProvider).value;
    if (data == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    final q = _q.toLowerCase();
    final skills =
        data.skills.values
            .where(
              (s) =>
                  (q.isEmpty || s.name.toLowerCase().contains(q)) &&
                  (_element == null || s.element == _element),
            )
            .toList()
          ..sort((a, b) {
            final e = a.element.compareTo(b.element);
            return e != 0 ? e : a.rank.compareTo(b.rank);
          });
    final learnerCount = data.learnerCounts;
    return Scaffold(
      appBar: AppBar(title: const Text('SKILLS')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.x4, Space.x3, Space.x4, 0),
            child: TextField(
              onChanged: (v) => setState(() => _q = v),
              decoration: const InputDecoration(
                hintText: 'Search skills',
                prefixIcon: Icon(Icons.search, size: 18),
              ),
            ),
          ),
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x2),
              children: [
                for (final e in elementLabels.keys)
                  Padding(
                    padding: const EdgeInsets.only(right: Space.x2),
                    child: FilterChip(
                      avatar: ElementDot(e),
                      label: Text(elementLabels[e]!),
                      selected: _element == e,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _element = _element == e ? null : e),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x8),
              itemCount: skills.length,
              itemBuilder: (context, i) {
                final s = skills[i];
                final n = learnerCount[s.name] ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: Space.x1),
                  child: SkillRow(
                    skill: s,
                    learnedAt: null,
                    trailing: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Text(
                        n == 1 ? '1 demon' : '$n demons',
                        style: context.tt.labelMedium?.copyWith(
                          color: n == 0 ? context.dc.outline : null,
                        ),
                      ),
                    ),
                    onTap: n == 0
                        ? null
                        : () {
                            ref.read(compendiumFilterProvider.notifier).setSkill(s.name);
                            context.go('/smt4/demons');
                          },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
