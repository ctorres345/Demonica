import 'package:demonica/design_system/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final hi = la > lb ? la : lb, lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // WCAG AA for body text. A palette change that breaks this fails here
  // instead of on someone's screen. See docs/DESIGN_SYSTEM.md.
  for (final palette in Palette.values) {
    for (final brightness in Brightness.values) {
      test('${palette.label} ${brightness.name} keeps text readable', () {
        final c = DemonicaColors.of(palette, brightness);
        for (final bg in [c.bg, c.surface]) {
          expect(contrast(c.text, bg), greaterThanOrEqualTo(4.5));
          expect(contrast(c.textMuted, bg), greaterThanOrEqualTo(4.5));
        }
        expect(contrast(c.text, c.surfaceHigh), greaterThanOrEqualTo(4.5));
        expect(contrast(c.onAccent, c.accent), greaterThanOrEqualTo(4.5));
        expect(contrast(c.accent, c.bg), greaterThanOrEqualTo(3));
      });
    }
  }
}
