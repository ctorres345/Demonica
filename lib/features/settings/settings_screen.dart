import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_core/fusion_core.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/version.dart';
import '../../design_system/components.dart';
import '../../design_system/palette_card.dart';
import '../../design_system/tokens.dart';
import 'unlocks_screen.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(gameDataProvider).value;
    final loc = ref.watch(locationsProvider).value;
    final settings = ref.watch(settingsProvider);
    final fusion = ref.watch(fusionSettingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final dc = context.dc;

    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.x4, Space.x2, Space.x4, Space.x8),
        children: [
          const SectionHeader('Palette'),
          Text(
            'Which game\'s menu colors the app uses. Every palette works in dark and light.',
            style: context.tt.bodySmall,
          ),
          const SizedBox(height: Space.x2),
          PalettePicker(
            selected: settings.palette,
            brightness: brightnessFor(context, settings.themeMode),
            onChanged: notifier.setPalette,
          ),
          const SectionHeader('Dark or light'),
          ThemeModePicker(selected: settings.themeMode, onChanged: notifier.setThemeMode),
          const SizedBox(height: Space.x2),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => context.go('/welcome'),
              icon: const Icon(Icons.replay, size: 18),
              label: const Text('Open the welcome screen again'),
            ),
          ),
          SectionHeader('Where to find', trailing: loc == null ? null : _coverage(loc, data)),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('Show late-game areas', style: context.tt.bodyMedium),
            subtitle: Text(
              'Blasted Tokyo, Infernal Tokyo and the final dungeons. Off keeps story spoilers out of "Where to find".',
              style: context.tt.bodySmall,
            ),
            value: settings.showSpoilers,
            onChanged: notifier.setShowSpoilers,
          ),
          const SectionHeader('Prices'),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('Show macca prices', style: context.tt.bodyMedium),
            subtitle: Text(
              'The cost to re-summon the ingredients from the Compendium, before any in-game '
              'discount. Off by default because discounts change the real numbers. '
              '"Cheapest first" sorting works either way.',
              style: context.tt.bodySmall,
            ),
            value: settings.showPrices,
            onChanged: notifier.setShowPrices,
          ),
          const SectionHeader('Unlocks'),
          ListTile(
            key: const Key('settings-unlocks'),
            contentPadding: EdgeInsets.zero,
            title: Text('What you have unlocked in your game', style: context.tt.bodyMedium),
            subtitle: Text(
              '${data == null ? '' : '${unlockSummary(data, fusion)}. '}'
              'Demons behind bosses, quests, New Game+ or DLC stay out of recipes until you tick them.',
              style: context.tt.bodySmall,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/unlocks'),
          ),
          const SectionHeader('Help'),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const Key('settings-tutorial'),
              onPressed: () => context.push('/tutorial'),
              icon: const Icon(Icons.school_outlined, size: 18),
              label: const Text('Show the tutorial again'),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => launchUrl(_reportUrl(data?.sourceCommit)),
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text('Report a wrong recipe'),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => launchUrl(_contactUrl),
              icon: const Icon(Icons.mail_outline, size: 18),
              label: const Text('Contact: demonica@cjtech.dev'),
            ),
          ),
          const SectionHeader('About'),
          Text(
            'Demonica is an unofficial fan tool for Shin Megami Tensei IV. It is not affiliated with Atlus or Sega. '
            'Demon names and numbers belong to their owners; no game art is included.',
            style: context.tt.bodySmall,
          ),
          const SizedBox(height: Space.x2),
          Text(
            'Privacy: your settings and saved recipes stay on this device. Demonica sends nothing anywhere.',
            style: context.tt.bodySmall,
          ),
          const SizedBox(height: Space.x2),
          Text(
            'Fusion data comes from aqiu384\'s megaten-fusion-tool (public domain, Unlicense)'
            '${data == null ? '' : ', commit ${data.sourceCommit.substring(0, 8)}'}.',
            style: context.tt.bodySmall,
          ),
          if (loc != null) ...[
            const SizedBox(height: Space.x2),
            Text(
              'Demon locations were compiled by hand, using the ${loc.sourceName} as a reference (facts only).',
              style: context.tt.bodySmall,
            ),
          ],
          const SizedBox(height: Space.x2),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => showLicensePage(
                context: context,
                applicationName: 'Demonica',
                applicationVersion: appVersion,
                applicationLegalese:
                    'MIT License. Fusion data: Unlicense. Fonts: SIL Open Font License 1.1.',
              ),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Open source licences'),
            ),
          ),
          const SizedBox(height: Space.x4),
          Text(
            'demonica · v$appVersion',
            style: context.tt.labelSmall?.copyWith(color: dc.textMuted),
          ),
        ],
      ),
    );
  }
}

/// "190 of 426 recruitable". The second number counts every demon that is not
/// enemy-only, so the gap is demons you can only fuse.
String _coverage(LocationData loc, GameData? data) {
  final n = loc.recruitable().length;
  final total = data?.demons.values.where((d) => !d.isEnemyOnly).length;
  return 'areas known for ${total == null ? n : '$n of $total'} demons';
}

/// A pre-filled GitHub issue so a report carries the data version.
final _contactUrl = Uri(
  scheme: 'mailto',
  path: 'demonica@cjtech.dev',
  query: 'subject=Demonica v$appVersion',
);

Uri _reportUrl(String? commit) => Uri.https('github.com', '/ctorres345/Demonica/issues/new', {
  'title': 'Wrong recipe: <demon name>',
  'body':
      'Demon:\nRecipe shown in Demonica:\nWhat the game does instead:\n\n'
      'Data commit: ${commit ?? 'unknown'}',
});
