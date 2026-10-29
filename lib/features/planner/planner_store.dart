import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fusion_core/fusion_core.dart';

import '../../app/providers.dart';

/// What the Plan tab shows: the target, the wanted skills, and the last result.
class PlannerState {
  const PlannerState({
    this.target,
    this.skills = const [],
    this.allowLevelUps = true,
    this.result,
    this.running = false,
    this.option = 0,
  });

  final String? target;
  final List<String> skills;
  final bool allowLevelUps;

  /// Null until the user presses the button, and again after any input changes.
  final PlanResult? result;
  final bool running;

  /// Which of the result's plans is shown.
  final int option;

  Plan? get plan => result != null && option < result!.plans.length ? result!.plans[option] : null;

  PlannerState copyWith({
    String? target,
    List<String>? skills,
    bool? allowLevelUps,
    PlanResult? Function()? result,
    bool? running,
    int? option,
  }) => PlannerState(
    target: target ?? this.target,
    skills: skills ?? this.skills,
    allowLevelUps: allowLevelUps ?? this.allowLevelUps,
    result: result != null ? result() : this.result,
    running: running ?? this.running,
    option: option ?? this.option,
  );
}

/// Holds the planner inputs and runs the engine's [Planner].
class PlannerNotifier extends Notifier<PlannerState> {
  // Bumped on every input change, so a slow search that finishes after the
  // user changed something does not overwrite the screen.
  int _run = 0;

  @override
  PlannerState build() => const PlannerState();

  PlannerState _cleared(PlannerState s) {
    _run++;
    return s.copyWith(result: () => null, running: false, option: 0);
  }

  void setTarget(String name) => state = _cleared(state.copyWith(target: name));

  void addSkill(String name) {
    if (state.skills.contains(name)) return;
    state = _cleared(state.copyWith(skills: [...state.skills, name]));
  }

  void removeSkill(String name) =>
      state = _cleared(state.copyWith(skills: [...state.skills.where((s) => s != name)]));

  void setAllowLevelUps(bool v) => state = _cleared(state.copyWith(allowLevelUps: v));

  void showOption(int i) => state = state.copyWith(option: i);

  /// Fills the inputs from a link like `/plan?demon=pixie&skills=Agi,Zio`
  /// and runs the search. Unknown names are ignored.
  Future<void> openLink(String? demonId, String? skills) async {
    final data = ref.read(gameDataProvider).value;
    final target = data?.demonsById[demonId];
    if (data == null || target == null) return;
    final wanted = [
      for (final s in (skills ?? '').split(','))
        if (data.skills.containsKey(s.trim())) s.trim(),
    ];
    state = _cleared(state.copyWith(target: target.name, skills: wanted));
    await run();
  }

  Future<void> run() async {
    final rules = ref.read(rulesProvider);
    final target = rules?.data.demons[state.target];
    if (rules == null || target == null) return;
    final run = ++_run;
    state = state.copyWith(running: true, result: () => null, option: 0);
    // Let the spinner draw before the search takes the thread (up to about a
    // second for six skills).
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (run != _run) return;
    final result = Planner(
      rules,
      settings: ref.read(fusionSettingsProvider),
      allowLevelUps: state.allowLevelUps,
    ).plan(target, state.skills);
    if (run != _run) return;
    state = state.copyWith(running: false, result: () => result);
  }
}

final plannerProvider = NotifierProvider<PlannerNotifier, PlannerState>(PlannerNotifier.new);
