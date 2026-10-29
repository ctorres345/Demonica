import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../design_system/tokens.dart';

/// Five short pages that show what the app does. Shown once after the
/// welcome screen; Settings can open it again.
class TutorialScreen extends ConsumerStatefulWidget {
  const TutorialScreen({super.key});

  @override
  ConsumerState<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends ConsumerState<TutorialScreen> {
  final _controller = PageController();
  var _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() {
    ref.read(settingsProvider.notifier).setTutorialSeen(true);
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/smt4/demons');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    final last = _page == tutorialPages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.x4, Space.x4, Space.x2, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'HOW DEMONICA WORKS',
                          style: context.tt.labelSmall?.copyWith(color: dc.accent),
                        ),
                      ),
                      TextButton(
                        key: const Key('tutorial-skip'),
                        onPressed: _finish,
                        child: const Text('SKIP'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _page = i),
                    children: [for (final p in tutorialPages) _Page(p)],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(Space.x4, 0, Space.x4, Space.x6),
                  child: Row(
                    children: [
                      for (var i = 0; i < tutorialPages.length; i++)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: Space.x2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == _page ? dc.accent : dc.outline,
                          ),
                        ),
                      const Spacer(),
                      FilledButton.icon(
                        key: const Key('tutorial-next'),
                        onPressed: last
                            ? _finish
                            : () => _controller.nextPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                        icon: Icon(last ? Icons.check : Icons.arrow_forward, size: 18),
                        label: Text(last ? 'START' : 'NEXT'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page(this.page);
  final TutorialPage page;

  @override
  Widget build(BuildContext context) {
    final dc = context.dc;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.x4, Space.x8, Space.x4, Space.x4),
      children: [
        Icon(page.icon, size: 56, color: dc.accent),
        const SizedBox(height: Space.x4),
        Text(page.title, style: context.tt.displaySmall),
        const SizedBox(height: Space.x3),
        for (final line in page.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: Space.x2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: Space.x3),
                  child: Icon(Icons.circle, size: 6, color: dc.accent),
                ),
                Expanded(child: Text(line, style: context.tt.bodyLarge)),
              ],
            ),
          ),
      ],
    );
  }
}

class TutorialPage {
  const TutorialPage(this.icon, this.title, this.lines);
  final IconData icon;
  final String title;
  final List<String> lines;
}

const tutorialPages = [
  TutorialPage(Icons.auto_awesome_mosaic_outlined, 'Start from the demon you want', [
    'Demons lists all 454 demons. Type a name, or filter by race, level or a skill.',
    'Open one to see its stats, resistances, skills and every recipe that makes it.',
  ]),
  TutorialPage(Icons.account_tree_outlined, 'Follow the recipe tree', [
    'Open recipe tree shows every pair that fuses into your demon, cheapest first.',
    'Tap an ingredient to open its own recipes right underneath. Keep going until '
        'every ingredient is one you have or can recruit.',
    'A green speech bubble means you can recruit that demon instead of fusing it.',
  ]),
  TutorialPage(Icons.route_outlined, 'Plan for specific skills', [
    'Plan takes a demon and the skills it should end with.',
    'You get numbered steps: what to fuse, which skills to keep at each step, and '
        'what to level up first.',
  ]),
  TutorialPage(Icons.bookmarks_outlined, 'Save and tick off', [
    'The bookmark icon saves a demon, one recipe or a whole path to Saved.',
    'Add a note, tick steps off as you fuse, and export everything as a file.',
  ]),
  TutorialPage(Icons.lock_open_outlined, 'Match your game', [
    'Some demons unlock after a boss, a quest, New Game+ or DLC. Tick what you have '
        'done in Settings > Unlocks, and locked demons stay out of recipes.',
    'Late-game areas are hidden from "Where to find" until you turn spoilers on.',
  ]),
];
