import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_core/fusion_core.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';

/// A checklist of the things in the game that unlock demons for fusion.
/// Demons behind an unticked row are left out of recipes and the tree, so
/// the app never suggests a fusion the player cannot do yet.
class UnlocksScreen extends ConsumerWidget {
  const UnlocksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider).value;
    final fusion = ref.watch(fusionSettingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('UNLOCKS')),
      body: data == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, Space.x8),
              children: [
                Text(
                  'Tick what you have done in your game. Demons behind an unticked row are '
                  'hidden from recipes and the tree, so you only see fusions you can do now.',
                  style: context.tt.bodyMedium,
                ),
                for (final cat in data.unlocks) ...[
                  SectionHeader(cat.category, trailing: _progress(cat, fusion)),
                  Text(_categoryHelp(cat.category), style: context.tt.bodySmall),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => notifier.setDemonsEnabled(_demonsOf(cat), true),
                        child: const Text('All done'),
                      ),
                      TextButton(
                        onPressed: () => notifier.setDemonsEnabled(_demonsOf(cat), false),
                        child: const Text('None yet'),
                      ),
                    ],
                  ),
                  for (final e in cat.entries)
                    CheckboxListTile(
                      key: Key('unlock-${e.demons.first}'),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(e.condition, style: context.tt.bodyMedium),
                      subtitle: Text('Unlocks ${e.demons.join(', ')}', style: context.tt.bodySmall),
                      value: e.demons.every(fusion.isEnabled),
                      onChanged: (v) => notifier.setDemonsEnabled(e.demons, v ?? false),
                    ),
                ],
              ],
            ),
    );
  }
}

Iterable<String> _demonsOf(UnlockCategory cat) => [for (final e in cat.entries) ...e.demons];

String _progress(UnlockCategory cat, FusionSettings fusion) {
  final done = cat.entries.where((e) => e.demons.every(fusion.isEnabled)).length;
  return '$done of ${cat.entries.length} done';
}

/// "12 of 57 done" for the Settings row.
String unlockSummary(GameData data, FusionSettings fusion) {
  var done = 0;
  var total = 0;
  for (final cat in data.unlocks) {
    for (final e in cat.entries) {
      total++;
      if (e.demons.every(fusion.isEnabled)) done++;
    }
  }
  return '$done of $total done';
}

String _categoryHelp(String category) => switch (category) {
  'Story Progression' =>
    'Bosses and story events. Each one unlocks its demon for fusion afterwards.',
  'Challenge Quests' => 'Optional quests from the Hunter Association bulletin boards.',
  'New Game+' => 'Quests that only appear on a second playthrough.',
  'Fiend Encounters' => 'Rare demons that spawn in fixed places. Beat one to unlock it.',
  'Downloadable Content' => 'Paid DLC quests. Off by default.',
  _ => '',
};
