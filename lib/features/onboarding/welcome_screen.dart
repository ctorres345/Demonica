import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/components.dart';
import '../../design_system/palette_card.dart';
import '../../design_system/tokens.dart';

/// First-start screen: pick a palette and dark or light, then enter the app.
/// The whole app repaints live as the user taps, so the choice is never a
/// guess. Settings can reopen it at any time. The first time, START
/// continues to the tutorial.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final dc = context.dc;
    final brightness = brightnessFor(context, settings.themeMode);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(Space.x4, Space.x8, Space.x4, Space.x8),
              children: [
                Text('DEMONICA', style: context.tt.labelSmall?.copyWith(color: dc.accent)),
                const SizedBox(height: Space.x2),
                Text('Pick your look', style: context.tt.displaySmall),
                const SizedBox(height: Space.x2),
                Text(
                  'Fusion recipes, recipe trees and skill plans for Shin Megami Tensei IV.',
                  style: context.tt.bodyMedium,
                ),
                const SizedBox(height: Space.x2),
                Text(
                  'Each palette copies the menus of one game. Tap one to try it; '
                  'the screen changes right away. You can change it later in Settings.',
                  style: context.tt.bodyMedium?.copyWith(color: dc.textMuted),
                ),
                const SectionHeader('Palette'),
                PalettePicker(
                  selected: settings.palette,
                  brightness: brightness,
                  onChanged: (p) => notifier.setPalette(p, mode: p.preferredMode),
                ),
                const SectionHeader('Dark or light'),
                ThemeModePicker(selected: settings.themeMode, onChanged: notifier.setThemeMode),
                const SizedBox(height: Space.x8),
                FilledButton.icon(
                  key: const Key('welcome-start'),
                  onPressed: () {
                    notifier.setOnboarded(true);
                    context.go(settings.tutorialSeen ? '/smt4/demons' : '/tutorial');
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('START'),
                ),
                const SizedBox(height: Space.x4),
                Text(
                  'Unofficial fan tool for Shin Megami Tensei IV. Not affiliated with Atlus or Sega.',
                  style: context.tt.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
