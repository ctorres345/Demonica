import 'package:flutter/material.dart';

import 'tokens.dart';

ThemeData demonicaTheme(Brightness brightness, {Palette palette = Palette.strangeJourney}) {
  final dark = brightness == Brightness.dark;
  final c = DemonicaColors.of(palette, brightness);
  final e = dark ? ElementColors.dark : ElementColors.light;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: c.accent,
    onPrimary: c.onAccent,
    secondary: c.accent,
    onSecondary: c.onAccent,
    error: c.danger,
    onError: Colors.white,
    surface: c.bg,
    onSurface: c.text,
    surfaceContainerLowest: c.bg,
    surfaceContainerLow: c.surface,
    surfaceContainer: c.surface,
    surfaceContainerHigh: c.surfaceHigh,
    surfaceContainerHighest: c.surfaceHigh,
    onSurfaceVariant: c.textMuted,
    outline: c.outline,
    outlineVariant: c.outline,
  );

  final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
  final text = base.textTheme.apply(
    fontFamily: Fonts.body,
    bodyColor: c.text,
    displayColor: c.text,
  );

  TextStyle display(double size, {FontWeight weight = FontWeight.w600}) => TextStyle(
    fontFamily: Fonts.display,
    fontSize: size,
    fontWeight: weight,
    color: c.text,
    letterSpacing: 0.2,
    height: 1.1,
  );

  return base.copyWith(
    scaffoldBackgroundColor: c.bg,
    canvasColor: c.bg,
    dividerColor: c.outline,
    splashFactory: InkSparkle.splashFactory,
    extensions: [c, e],
    textTheme: text.copyWith(
      displayLarge: display(40, weight: FontWeight.w700),
      displayMedium: display(32, weight: FontWeight.w700),
      displaySmall: display(26, weight: FontWeight.w700),
      headlineMedium: display(22),
      headlineSmall: display(18),
      titleLarge: display(17),
      titleMedium: display(15),
      titleSmall: display(13, weight: FontWeight.w500),
      labelSmall: TextStyle(
        fontFamily: Fonts.mono,
        fontSize: 10.5,
        letterSpacing: 0.8,
        color: c.textMuted,
        fontWeight: FontWeight.w500,
      ),
      labelMedium: TextStyle(fontFamily: Fonts.mono, fontSize: 12, color: c.textMuted),
      bodySmall: TextStyle(fontFamily: Fonts.body, fontSize: 12.5, color: c.textMuted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.bg,
      foregroundColor: c.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: display(17),
      shape: Border(bottom: BorderSide(color: c.outline)),
    ),
    cardTheme: CardThemeData(
      color: c.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.borderMedium,
        side: BorderSide(color: c.outline),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: c.surface,
      selectedColor: c.accent.withValues(alpha: 0.16),
      side: BorderSide(color: c.outline),
      shape: const StadiumBorder(),
      labelStyle: TextStyle(fontFamily: Fonts.body, fontSize: 12.5, color: c.text),
      secondaryLabelStyle: TextStyle(fontFamily: Fonts.body, fontSize: 12.5, color: c.text),
      checkmarkColor: c.accent,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: c.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      hintStyle: TextStyle(fontFamily: Fonts.mono, fontSize: 13, color: c.textMuted),
      border: OutlineInputBorder(
        borderRadius: Radii.borderSmall,
        borderSide: BorderSide(color: c.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: Radii.borderSmall,
        borderSide: BorderSide(color: c.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: Radii.borderSmall,
        borderSide: BorderSide(color: c.accent, width: 1.5),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: c.bg,
      indicatorColor: c.accent.withValues(alpha: 0.16),
      surfaceTintColor: Colors.transparent,
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontFamily: Fonts.mono, fontSize: 10.5, letterSpacing: 0.6, color: c.textMuted),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? c.accent : c.textMuted,
          size: 22,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: c.bg,
      indicatorColor: c.accent.withValues(alpha: 0.16),
      selectedIconTheme: IconThemeData(color: c.accent),
      unselectedIconTheme: IconThemeData(color: c.textMuted),
      selectedLabelTextStyle: TextStyle(fontFamily: Fonts.mono, fontSize: 10.5, color: c.accent),
      unselectedLabelTextStyle: TextStyle(
        fontFamily: Fonts.mono,
        fontSize: 10.5,
        color: c.textMuted,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: c.accent,
        foregroundColor: c.onAccent,
        shape: RoundedRectangleBorder(borderRadius: Radii.borderSmall),
        textStyle: display(13).copyWith(letterSpacing: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: c.text,
        side: BorderSide(color: c.outline),
        shape: RoundedRectangleBorder(borderRadius: Radii.borderSmall),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: c.textMuted,
      textColor: c.text,
      shape: Border(bottom: BorderSide(color: c.outline)),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.onAccent : c.textMuted,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? c.accent : c.surfaceHigh,
      ),
      trackOutlineColor: WidgetStatePropertyAll(c.outline),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
    ),
    dividerTheme: DividerThemeData(color: c.outline, thickness: 1, space: 1),
  );
}
