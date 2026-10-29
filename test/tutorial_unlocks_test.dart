import 'package:demonica/app/providers.dart';
import 'package:demonica/design_system/theme.dart';
import 'package:demonica/features/onboarding/tutorial_screen.dart';
import 'package:demonica/features/settings/unlocks_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.runAsync(() => container.read(gameDataProvider.future));
  await tester.runAsync(() async {
    for (var i = 0; i < 40 && !container.read(settingsProvider).loaded; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 25));
    }
  });
  return container;
}

// The screens navigate with go_router, so each test gets a one-route router.
Widget _app(ProviderContainer container, Widget home) => UncontrolledProviderScope(
  container: container,
  child: MaterialApp.router(
    theme: demonicaTheme(Brightness.dark),
    routerConfig: GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, _) => home),
        GoRoute(path: '/smt4/demons', builder: (_, _) => const SizedBox()),
      ],
    ),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('tutorial walks through every page and marks itself seen', (tester) async {
    final container = await _container(tester);
    await tester.pumpWidget(_app(container, const TutorialScreen()));
    await tester.pump();

    expect(find.text(tutorialPages.first.title), findsOneWidget);
    for (var i = 1; i < tutorialPages.length; i++) {
      await tester.tap(find.byKey(const Key('tutorial-next')));
      await tester.pumpAndSettle();
      expect(find.text(tutorialPages[i].title), findsOneWidget);
    }
    expect(find.text('START'), findsOneWidget);
    expect(container.read(settingsProvider).tutorialSeen, isFalse);
    await tester.tap(find.byKey(const Key('tutorial-next')));
    await tester.pump();
    expect(container.read(settingsProvider).tutorialSeen, isTrue);
  });

  testWidgets('unticking an unlock hides its demon from fusion', (tester) async {
    final container = await _container(tester);
    await tester.pumpWidget(_app(container, const UnlocksScreen()));
    await tester.pump();

    expect(container.read(fusionSettingsProvider).isEnabled('Minotaur'), isTrue);
    expect(find.text('Unlocks Minotaur'), findsOneWidget);
    await tester.tap(find.byKey(const Key('unlock-Minotaur')));
    await tester.pump();
    expect(container.read(fusionSettingsProvider).isEnabled('Minotaur'), isFalse);
    expect(find.text('17 of 18 done'), findsOneWidget);
  });
}
