import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_core/fusion_core.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/pixel_icon.dart';
import '../../design_system/tokens.dart';
import 'filter_sheets.dart';

/// The demon list with search and filters. On wide screens it is the left pane.
class CompendiumScreen extends ConsumerStatefulWidget {
  const CompendiumScreen({super.key, this.selectedId, this.embedded = false});

  final String? selectedId;

  /// True when shown as the left pane next to a detail view.
  final bool embedded;

  @override
  ConsumerState<CompendiumScreen> createState() => _CompendiumScreenState();
}

class _CompendiumScreenState extends ConsumerState<CompendiumScreen> {
  late final TextEditingController _search;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _search = TextEditingController(text: ref.read(compendiumFilterProvider).query);
  }

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(gameDataProvider);
    final filter = ref.watch(compendiumFilterProvider);
    final demons = ref.watch(filteredDemonsProvider);
    final recruitable = ref.watch(recruitableProvider);
    final dc = context.dc;

    return Scaffold(
      appBar: widget.embedded
          ? null
          : AppBar(
              title: const Row(
                children: [
                  PixelHelmet(size: 24),
                  SizedBox(width: Space.x2),
                  Text('COMPENDIUM'),
                ],
              ),
            ),
      body: data.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(Space.x6),
            child: Text(
              'Could not load the demon data. Reload the page or reinstall the app.\n\n$e',
              style: context.tt.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (gd) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.x4, Space.x3, Space.x4, 0),
              child: TextField(
                controller: _search,
                focusNode: _focus,
                onChanged: ref.read(compendiumFilterProvider.notifier).setQuery,
                decoration: InputDecoration(
                  hintText: 'Search demons or races',
                  prefixIcon: Icon(Icons.search, size: 18, color: dc.textMuted),
                  suffixIcon: filter.query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close, size: 16),
                          onPressed: () {
                            _search.clear();
                            ref.read(compendiumFilterProvider.notifier).setQuery('');
                          },
                        ),
                ),
              ),
            ),
            SizedBox(
              height: 46,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: Space.x4, vertical: Space.x2),
                children: [
                  _chip(
                    label: filter.skill == null ? 'Skill' : 'Skill: ${filter.skill}',
                    selected: filter.skill != null,
                    onTap: () => showSkillPicker(context, ref),
                    onClear: filter.skill == null
                        ? null
                        : () => ref.read(compendiumFilterProvider.notifier).setSkill(null),
                  ),
                  _chip(
                    label: filter.maxLevel == null ? 'Level' : 'Lv ≤ ${filter.maxLevel}',
                    selected: filter.maxLevel != null,
                    onTap: () => showLevelPicker(context, ref, filter.maxLevel),
                    onClear: filter.maxLevel == null
                        ? null
                        : () => ref.read(compendiumFilterProvider.notifier).setMaxLevel(null),
                  ),
                  _chip(
                    label: filter.races.isEmpty
                        ? 'Race'
                        : filter.races.length == 1
                        ? filter.races.first
                        : '${filter.races.length} races',
                    selected: filter.races.isNotEmpty,
                    onTap: () => showRacePicker(context, ref, [...gd.races]..sort()),
                    onClear: filter.races.isEmpty
                        ? null
                        : () => ref.read(compendiumFilterProvider.notifier).setRaces({}),
                  ),
                  if (ref.watch(fusionSettingsProvider).disabledDemons.isNotEmpty)
                    _chip(
                      label: 'Show locked demons',
                      selected: filter.showDisabled,
                      onTap: () => ref
                          .read(compendiumFilterProvider.notifier)
                          .setShowDisabled(!filter.showDisabled),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(Space.x4, Space.x1, Space.x4, Space.x1),
              child: Row(
                children: [
                  Text('${demons.length} demons'.toUpperCase(), style: context.tt.labelSmall),
                  const SizedBox(width: Space.x2),
                  _SortButton(
                    sort: filter.sort,
                    onSelected: ref.read(compendiumFilterProvider.notifier).setSort,
                  ),
                  const Spacer(),
                  if (filter.isActive)
                    TextButton(
                      onPressed: ref.read(compendiumFilterProvider.notifier).clear,
                      child: const Text('Clear filters'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: demons.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(Space.x6),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              filter.query.isEmpty
                                  ? 'No demon matches these filters.'
                                  : 'No demon matches "${filter.query}".',
                              style: context.tt.bodySmall,
                            ),
                            const SizedBox(height: Space.x2),
                            TextButton(
                              onPressed: () {
                                _search.clear();
                                ref.read(compendiumFilterProvider.notifier).clearAll();
                              },
                              child: const Text('Clear search and filters'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: demons.length,
                      itemExtent: 60,
                      itemBuilder: (context, i) {
                        final d = demons[i];
                        return DemonTile(
                          demon: d,
                          selected: d.id == widget.selectedId,
                          subtitle: _subtitle(d, filter.skill),
                          recruitable: recruitable.contains(d.name),
                          onTap: () => context.go('/smt4/demon/${d.id}'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(Demon d, String? skill) {
    if (skill != null) {
      final s = d.skills.firstWhere((s) => s.name == skill);
      return '${d.race} · ${s.innate ? '$skill innate' : '$skill at ${s.level}'}';
    }
    return d.race;
  }

  Widget _chip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: Space.x2),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => onTap(),
        deleteIcon: onClear == null ? null : const Icon(Icons.close, size: 14),
        onDeleted: onClear,
      ),
    );
  }
}

/// "Sort: Level ▾" next to the count line. Opens a menu of [DemonSort]s.
class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onSelected});
  final DemonSort sort;
  final ValueChanged<DemonSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return PopupMenuButton<DemonSort>(
      tooltip: 'Change sort order',
      initialValue: sort,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final s in DemonSort.values) PopupMenuItem(value: s, child: Text(s.label)),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Space.x2, vertical: Space.x1),
        decoration: BoxDecoration(
          border: Border.all(color: dc.outline),
          borderRadius: Radii.borderSmall,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sort: ${sort.label}'.toUpperCase(), style: context.tt.labelSmall),
            Icon(Icons.arrow_drop_down, size: 16, color: dc.textMuted),
          ],
        ),
      ),
    );
  }
}
