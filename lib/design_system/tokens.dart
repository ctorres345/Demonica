import 'package:flutter/material.dart';

/// Design tokens for the "Terminal" direction (dark-first) and its light twin.
/// Screens never use these directly; they read [DemonicaColors] and
/// [ElementColors] from the theme so a direction swap is one file.
abstract final class Fonts {
  static const display = 'ChakraPetch';
  static const body = 'Inter';
  static const mono = 'JetBrainsMono';
}

abstract final class Space {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 20;
  static const double x6 = 24;
  static const double x8 = 32;
}

abstract final class Radii {
  static const small = Radius.circular(4);
  static const medium = Radius.circular(8);
  static final borderSmall = BorderRadius.circular(4);
  static final borderMedium = BorderRadius.circular(8);
}

/// Layout breakpoint: at or above this width the app uses a rail and two panes.
const double wideBreakpoint = 840;

@immutable
class DemonicaColors extends ThemeExtension<DemonicaColors> {
  const DemonicaColors({
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.outline,
    required this.text,
    required this.textMuted,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.ok,
    required this.law,
    required this.neutral,
    required this.chaos,
  });

  final Color bg, surface, surfaceHigh, outline, text, textMuted;
  final Color accent, onAccent, danger, ok;
  final Color law, neutral, chaos;

  static const dark = DemonicaColors(
    bg: Color(0xFF0B0D10),
    surface: Color(0xFF12161B),
    surfaceHigh: Color(0xFF1A2028),
    outline: Color(0xFF2A323D),
    text: Color(0xFFE6EDF3),
    textMuted: Color(0xFF8B98A5),
    accent: Color(0xFF3DDCFF),
    onAccent: Color(0xFF061A20),
    danger: Color(0xFFFF4D6D),
    ok: Color(0xFF3DDC97),
    law: Color(0xFF5B8DEF),
    neutral: Color(0xFF9AA7B4),
    chaos: Color(0xFFFF6B57),
  );

  static const light = DemonicaColors(
    bg: Color(0xFFF4F6F8),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFECEFF3),
    outline: Color(0xFFD6DCE3),
    text: Color(0xFF14181D),
    textMuted: Color(0xFF5B6672),
    accent: Color(0xFF0A7EA4),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFC62F3F),
    ok: Color(0xFF2F7D4F),
    law: Color(0xFF2F5FD0),
    neutral: Color(0xFF6B7684),
    chaos: Color(0xFFC8451F),
  );

  Color alignmentColor(String alignment) {
    final lawChaos = alignment.split('-').last;
    return switch (lawChaos) {
      'Law' => law,
      'Chaos' => chaos,
      _ => neutral,
    };
  }

  @override
  DemonicaColors copyWith() => this;

  @override
  DemonicaColors lerp(DemonicaColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return DemonicaColors(
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      outline: l(outline, other.outline),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      danger: l(danger, other.danger),
      ok: l(ok, other.ok),
      law: l(law, other.law),
      neutral: l(neutral, other.neutral),
      chaos: l(chaos, other.chaos),
    );
  }
}

/// One color per skill/resist element. Keys are the short codes used by the
/// data: phy, gun, fir, ice, ele, for, lig, dar, alm, rec, ail, sup, spe, pas.
@immutable
class ElementColors extends ThemeExtension<ElementColors> {
  const ElementColors(this.colors);
  final Map<String, Color> colors;

  Color of(String element) => colors[element] ?? colors['pas']!;

  static const dark = ElementColors({
    'phy': Color(0xFFC9A27A),
    'gun': Color(0xFFA3A6AB),
    'fir': Color(0xFFFF7A45),
    'ice': Color(0xFF5FC9FF),
    'ele': Color(0xFFFFD84D),
    'for': Color(0xFF8FE388),
    'lig': Color(0xFFFFF0A8),
    'dar': Color(0xFFB48CFF),
    'alm': Color(0xFFFFFFFF),
    'rec': Color(0xFF7EE0B8),
    'ail': Color(0xFFE08AD6),
    'sup': Color(0xFF9FB4FF),
    'spe': Color(0xFF9FB4FF),
    'pas': Color(0xFF8B98A5),
  });

  static const light = ElementColors({
    'phy': Color(0xFF8A6A46),
    'gun': Color(0xFF6B6F75),
    'fir': Color(0xFFC84F1E),
    'ice': Color(0xFF1F7FB0),
    'ele': Color(0xFFA98400),
    'for': Color(0xFF3E8A3A),
    'lig': Color(0xFF9C8A1E),
    'dar': Color(0xFF6B4FA8),
    'alm': Color(0xFF1D1A14),
    'rec': Color(0xFF2F8A66),
    'ail': Color(0xFF9B3F8F),
    'sup': Color(0xFF3F58B0),
    'spe': Color(0xFF3F58B0),
    'pas': Color(0xFF6B6457),
  });

  @override
  ElementColors copyWith() => this;

  @override
  ElementColors lerp(ElementColors? other, double t) {
    if (other == null) return this;
    return ElementColors({
      for (final e in colors.entries)
        e.key: Color.lerp(e.value, other.colors[e.key] ?? e.value, t)!
    });
  }
}

/// Human labels for element codes.
const elementLabels = {
  'phy': 'Phys',
  'gun': 'Gun',
  'fir': 'Fire',
  'ice': 'Ice',
  'ele': 'Elec',
  'for': 'Force',
  'lig': 'Light',
  'dar': 'Dark',
  'alm': 'Almighty',
  'rec': 'Recovery',
  'ail': 'Ailment',
  'sup': 'Support',
  'spe': 'Special',
  'pas': 'Passive',
};

extension DemonicaTheme on BuildContext {
  DemonicaColors get dc => Theme.of(this).extension<DemonicaColors>()!;
  ElementColors get ec => Theme.of(this).extension<ElementColors>()!;
  TextTheme get tt => Theme.of(this).textTheme;
}
