import 'package:demonica/app/providers.dart';
import 'package:demonica/design_system/theme.dart';
import 'package:demonica/design_system/tokens.dart';
import 'package:demonica/features/onboarding/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('welcome screen shows the three palettes and tapping one applies it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(gameDataProvider.future));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: demonicaTheme(Brightness.dark), home: const WelcomeScreen()),
      ),
    );
    await tester.pump();

    for (final p in Palette.values) {
      expect(find.text(p.label), findsOneWidget);
    }
    expect(container.read(settingsProvider).onboarded, isFalse);

    await tester.tap(find.text('Codex'));
    await tester.pump();
    final s = container.read(settingsProvider);
    expect(s.palette, Palette.codex);
    expect(s.themeMode, ThemeMode.light, reason: 'Codex defaults to light');

    final prefs = await tester.runAsync(() => SharedPreferences.getInstance());
    expect(prefs!.getString('demonica.settings.v1'), contains('"palette":"codex"'));
  });

  testWidgets('settings saved before the welcome screen existed count as onboarded', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({
      'demonica.settings.v1': '{"themeMode":"dark","disabledDemons":[]}',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.runAsync(() => container.read(gameDataProvider.future));
    await tester.runAsync(() async {
      for (var i = 0; i < 40 && !container.read(settingsProvider).loaded; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 25));
      }
    });
    expect(container.read(settingsProvider).loaded, isTrue);
    expect(container.read(settingsProvider).onboarded, isTrue);
  });
}
