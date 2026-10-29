import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../design_system/pixel_icon.dart';
import '../design_system/theme.dart';
import '../design_system/tokens.dart';
import '../features/compendium/compendium_screen.dart';
import '../features/compendium/demon_detail_screen.dart';
import '../features/onboarding/welcome_screen.dart';
import '../features/recipes/recipe_tree_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/skills/skills_screen.dart';
import 'providers.dart';

/// The router watches settings so the first start lands on the welcome screen.
final routerProvider = Provider<GoRouter>((ref) {
  final settings = ValueNotifier(ref.read(settingsProvider));
  ref.listen(settingsProvider, (_, next) => settings.value = next);
  ref.onDispose(settings.dispose);
  return GoRouter(
    initialLocation: '/smt4/demons',
    refreshListenable: settings,
    redirect: (context, state) {
      final s = settings.value;
      if (!s.loaded || s.onboarded) return null;
      return state.uri.path == '/welcome' ? null : '/welcome';
    },
    routes: _routes,
  );
});

final _routes = <RouteBase>[
  GoRoute(path: '/welcome', builder: (context, state) => const WelcomeScreen()),
  ShellRoute(
    builder: (context, state, child) => AppShell(location: state.uri.path, child: child),
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/smt4/demons'),
      GoRoute(path: '/smt4/demons', builder: (context, state) => const _CompendiumRoute()),
      GoRoute(
        path: '/smt4/demon/:id',
        builder: (context, state) => _CompendiumRoute(demonId: state.pathParameters['id']),
        routes: [
          GoRoute(
            path: 'tree',
            builder: (context, state) =>
                _CompendiumRoute(demonId: state.pathParameters['id'], tree: true),
          ),
        ],
      ),
      GoRoute(path: '/smt4/skills', builder: (context, state) => const SkillsScreen()),
      GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    ],
  ),
];

class DemonicaApp extends ConsumerWidget {
  const DemonicaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(settingsProvider.select((s) => s.themeMode));
    final palette = ref.watch(settingsProvider.select((s) => s.palette));
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Demonica',
      debugShowCheckedModeBanner: false,
      theme: demonicaTheme(Brightness.light, palette: palette),
      darkTheme: demonicaTheme(Brightness.dark, palette: palette),
      themeMode: mode,
      routerConfig: router,
    );
  }
}

/// Bottom navigation on phones, a rail on wide screens.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.location, required this.child});
  final String location;
  final Widget child;

  static const _tabs = [
    (path: '/smt4/demons', icon: Icons.auto_awesome_mosaic_outlined, label: 'DEMONS'),
    (path: '/smt4/skills', icon: Icons.bolt_outlined, label: 'SKILLS'),
    (path: '/settings', icon: Icons.tune, label: 'SETTINGS'),
  ];

  int get _index {
    if (location.startsWith('/smt4/skills')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final dc = context.dc;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: _index,
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.only(bottom: Space.x4, top: Space.x2),
                child: const PixelHelmet(size: 36),
              ),
              onDestinationSelected: (i) => context.go(_tabs[i].path),
              destinations: [
                for (final t in _tabs)
                  NavigationRailDestination(icon: Icon(t.icon), label: Text(t.label)),
              ],
            ),
            VerticalDivider(width: 1, color: dc.outline),
            Expanded(child: child),
          ],
        ),
      );
    }
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        height: 64,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: [
          for (final t in _tabs) NavigationDestination(icon: Icon(t.icon), label: t.label),
        ],
      ),
    );
  }
}

/// Phone: one screen at a time. Wide: list on the left, detail or tree on the right.
class _CompendiumRoute extends StatelessWidget {
  const _CompendiumRoute({this.demonId, this.tree = false});
  final String? demonId;
  final bool tree;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final dc = context.dc;
    if (!wide) {
      if (demonId == null) return const CompendiumScreen();
      return tree ? RecipeTreeScreen(demonId: demonId!) : DemonDetailScreen(demonId: demonId!);
    }
    return Row(
      children: [
        SizedBox(width: 360, child: CompendiumScreen(selectedId: demonId, embedded: true)),
        VerticalDivider(width: 1, color: dc.outline),
        Expanded(
          child: demonId == null
              ? Center(
                  child: Text(
                    'Pick a demon to see its stats and recipes.',
                    style: context.tt.bodySmall,
                  ),
                )
              : tree
              ? RecipeTreeScreen(demonId: demonId!, embedded: true)
              : DemonDetailScreen(demonId: demonId!, embedded: true),
        ),
      ],
    );
  }
}
