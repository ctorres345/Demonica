import '../model/game_data.dart';
import '../model/models.dart';

/// The per-game fusion rules. SMT IV is the first implementation; a new game
/// adds one class here and one import script.
abstract class GameRules {
  GameData get data;

  /// The demon produced by fusing [a] and [b], or null when the pair cannot be
  /// fused (no chart entry, result above the race's top demon, a disabled
  /// demon, or an unfusable ingredient).
  Demon? fuse(Demon a, Demon b, FusionSettings settings);

  /// Every recipe that produces [target] under [settings].
  List<Recipe> reverseRecipes(Demon target, FusionSettings settings);

  /// Every recipe that uses [ingredient] as one of its parents.
  List<Recipe> forwardRecipes(Demon ingredient, FusionSettings settings);

  /// Whether [skill] can be passed from a parent to a child.
  bool canInherit(Skill skill);

  /// How many inherited skills [child] can take on the fusion screen.
  int freeSkillSlots(Demon child);
}
