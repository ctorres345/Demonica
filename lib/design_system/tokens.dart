import 'package:flutter/material.dart';

/// Design tokens for the "Demonica" direction (dark-first) and its light twin.
/// The dark palette follows the Strange Journey / SMT I menus: deep navy
/// panels, light-blue outlines, white text, red for the selected command,
/// orange HP and green MP.
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

/// Which game's menu colors the app imitates. Each palette has a dark and a
/// light variant; the theme mode picks between them.
enum Palette {
  /// Strange Journey / SMT I: navy panels, light-blue outlines, white text.
  strangeJourney('Strange Journey'),

  /// SMT IV: black and grey panels, orange headers, yellow stat labels,
  /// green bars, a red line under the selected item.
  smt4('SMT IV');

  const Palette(this.label);
  final String label;
}

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
    bg: Color(0xFF050B16),
    surface: Color(0xFF0C1C36),
    surfaceHigh: Color(0xFF173159),
    outline: Color(0xFF3F74B4),
    text: Color(0xFFF4F7FF),
    textMuted: Color(0xFF92B4E0),
    accent: Color(0xFF5CC8FF),
    onAccent: Color(0xFF03101F),
    danger: Color(0xFFE63946),
    ok: Color(0xFF4FE06A),
    law: Color(0xFF6FA3FF),
    neutral: Color(0xFFA9C0DE),
    chaos: Color(0xFFFF7A4A),
  );

  static const smt4Dark = DemonicaColors(
    bg: Color(0xFF0D0D0D),
    surface: Color(0xFF1E1E1E),
    surfaceHigh: Color(0xFF333333),
    outline: Color(0xFF4A4A4A),
    text: Color(0xFFFAFAFA),
    textMuted: Color(0xFFA9A9A9),
    accent: Color(0xFFF7941D),
    onAccent: Color(0xFF1A0E00),
    danger: Color(0xFFD8232F),
    ok: Color(0xFF6FD621),
    law: Color(0xFF7AA6FF),
    neutral: Color(0xFFBDBDBD),
    chaos: Color(0xFFFF6A3D),
  );

  static const smt4Light = DemonicaColors(
    bg: Color(0xFFF2F2F2),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFE3E3E3),
    outline: Color(0xFFBDBDBD),
    text: Color(0xFF141414),
    textMuted: Color(0xFF5F5F5F),
    accent: Color(0xFFD97706),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFB91C1C),
    ok: Color(0xFF2E8B1E),
    law: Color(0xFF2F5FD0),
    neutral: Color(0xFF6B6B6B),
    chaos: Color(0xFFC8451F),
  );

  static DemonicaColors of(Palette palette, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (palette) {
      Palette.strangeJourney => dark ? DemonicaColors.dark : DemonicaColors.light,
      Palette.smt4 => dark ? smt4Dark : smt4Light,
    };
  }

  static const light = DemonicaColors(
    bg: Color(0xFFEEF3FA),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFDCE7F5),
    outline: Color(0xFF9DB7D8),
    text: Color(0xFF0A1A33),
    textMuted: Color(0xFF4A6A94),
    accent: Color(0xFF1F6FD0),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFC8252C),
    ok: Color(0xFF1F8A3A),
    law: Color(0xFF2F5FD0),
    neutral: Color(0xFF5E7596),
    chaos: Color(0xFFC84A1F),
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
    'pas': Color(0xFF92B4E0),
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
        e.key: Color.lerp(e.value, other.colors[e.key] ?? e.value, t)!,
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
