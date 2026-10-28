import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/tokens.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider).value;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final dc = context.dc;

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, Space.x8),
        children: [
          const SectionHeader('Theme'),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (s) => notifier.setThemeMode(s.first),
          ),
          const SectionHeader('Demons that count for fusion'),
          Text(
            'Turn off demons you have not unlocked yet. They disappear from recipes and from the tree.',
            style: context.tt.bodySmall,
          ),
          if (data != null)
            for (final cat in data.unlocks) ...[
              Padding(
                padding: const EdgeInsets.only(top: Space.x4, bottom: Space.x1),
                child: Row(
                  children: [
                    Expanded(child: Text(cat.category, style: context.tt.titleMedium)),
                    TextButton(
                      onPressed: () => notifier.setDemonsEnabled([for (final e in cat.entries) ...e.demons], true),
                      child: const Text('All on'),
                    ),
                    TextButton(
                      onPressed: () => notifier.setDemonsEnabled([for (final e in cat.entries) ...e.demons], false),
                      child: const Text('All off'),
                    ),
                  ],
                ),
              ),
              for (final e in cat.entries)
                SwitchListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(e.demons.join(', '), style: context.tt.bodyMedium),
                  subtitle: Text(e.condition, style: context.tt.bodySmall),
                  value: e.demons.every(settings.fusion.isEnabled),
                  onChanged: (v) => notifier.setDemonsEnabled(e.demons, v),
                ),
            ],
          const SectionHeader('About'),
          Text(
            'Demonica is an unofficial fan tool for Shin Megami Tensei IV. It is not affiliated with Atlus or Sega. '
            'Demon names and numbers belong to their owners; no game art is included.',
            style: context.tt.bodySmall,
          ),
          const SizedBox(height: Space.x2),
          Text(
            'Fusion data comes from aqiu384\'s megaten-fusion-tool (public domain, Unlicense)'
            '${data == null ? '' : ', commit ${data.sourceCommit.substring(0, 8)}'}.',
            style: context.tt.bodySmall,
          ),
          const SizedBox(height: Space.x4),
          Text('demonica · MVP', style: context.tt.labelSmall?.copyWith(color: dc.textMuted)),
        ],
      ),
    );
  }
}
