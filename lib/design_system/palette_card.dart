import 'package:flutter/material.dart';

import 'tokens.dart';

/// A tappable preview of one [Palette] in the given brightness: a tiny
/// screen with a header bar, two list rows and the accent, danger and ok
/// colors, with the palette name below. Used by the welcome screen and by
/// Settings so both show the same thing.
class PaletteCard extends StatelessWidget {
  const PaletteCard({
    super.key,
    required this.palette,
    required this.brightness,
    required this.selected,
    required this.onTap,
  });

  final Palette palette;
  final Brightness brightness;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = DemonicaColors.of(palette, brightness);
    final current = context.dc;
    return Semantics(
      button: true,
      selected: selected,
      label: '${palette.label} palette',
      child: InkWell(
        onTap: onTap,
        borderRadius: Radii.borderMedium,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 150,
          padding: const EdgeInsets.all(Space.x2),
          decoration: BoxDecoration(
            color: current.surface,
            borderRadius: Radii.borderMedium,
            border: Border.all(
              color: selected ? current.accent : current.outline,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _Preview(c),
              const SizedBox(height: Space.x2),
              Row(
                children: [
                  Expanded(child: Text(palette.label, style: context.tt.titleSmall)),
                  if (selected) Icon(Icons.check_circle, size: 16, color: current.accent),
                ],
              ),
              Text(palette.blurb, style: context.tt.bodySmall?.copyWith(fontSize: 11)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview(this.c);
  final DemonicaColors c;

  @override
  Widget build(BuildContext context) {
    Widget row(bool hi) => Container(
      height: 14,
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: hi ? c.surfaceHigh : c.surface,
        borderRadius: Radii.borderSmall,
        border: Border.all(color: c.outline),
      ),
      child: Row(
        children: [
          Container(width: 10, height: 6, color: hi ? c.accent : c.textMuted),
          const SizedBox(width: 4),
          Container(width: 36, height: 4, color: c.text),
          const Spacer(),
          Container(width: 14, height: 4, color: c.textMuted),
        ],
      ),
    );
    return Container(
      height: 84,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(color: c.bg, borderRadius: Radii.borderSmall),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 40, height: 6, color: c.accent),
              const Spacer(),
              _dot(c.danger),
              const SizedBox(width: 3),
              _dot(c.ok),
            ],
          ),
          row(false),
          row(true),
          row(false),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 6,
    height: 6,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}

/// The three palette cards in a wrap, bound to the current selection.
class PalettePicker extends StatelessWidget {
  const PalettePicker({
    super.key,
    required this.selected,
    required this.brightness,
    required this.onChanged,
  });

  final Palette selected;
  final Brightness brightness;
  final ValueChanged<Palette> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: Space.x3,
      runSpacing: Space.x3,
      children: [
        for (final p in Palette.values)
          PaletteCard(
            palette: p,
            brightness: brightness,
            selected: p == selected,
            onTap: () => onChanged(p),
          ),
      ],
    );
  }
}

/// Dark / Light / System, shared by the welcome screen and Settings.
class ThemeModePicker extends StatelessWidget {
  const ThemeModePicker({super.key, required this.selected, required this.onChanged});
  final ThemeMode selected;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text('Dark'),
          icon: Icon(Icons.dark_mode_outlined),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          label: Text('Light'),
          icon: Icon(Icons.light_mode_outlined),
        ),
        ButtonSegment(
          value: ThemeMode.system,
          label: Text('System'),
          icon: Icon(Icons.phone_android_outlined),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

/// Resolves [mode] to the brightness the app is actually showing.
Brightness brightnessFor(BuildContext context, ThemeMode mode) => switch (mode) {
  ThemeMode.dark => Brightness.dark,
  ThemeMode.light => Brightness.light,
  ThemeMode.system => MediaQuery.platformBrightnessOf(context),
};
