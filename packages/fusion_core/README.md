# fusion_core

The pure-Dart fusion engine behind Demonica. No Flutter, no I/O: it takes the decoded game JSON as strings and answers fusion questions.

```dart
final data = GameData.fromJsonStrings(meta: ..., demons: ..., skills: ...,
    fusionChart: ..., elementChart: ..., unlocks: ...);
final rules = Smt4Rules(data);
final settings = data.defaultSettings;            // DLC off, story demons on

rules.fuse(data.demon('Pixie'), data.demon('Angel'), settings);   // -> Demon?
rules.reverseRecipes(data.demon('Lilith'), settings);             // every way to make Lilith
rules.forwardRecipes(data.demon('Pixie'), settings);              // everything Pixie fuses into
rules.freeSkillSlots(data.demon('Lilith'));                       // inherit slots
```

`reverseRecipes` and `forwardRecipes` are cached per settings and return read-only lists.

| Folder | Contents |
| --- | --- |
| `lib/src/model` | `Demon`, `Skill`, `Recipe`, `FusionSettings`, `GameData` |
| `lib/src/engine` | `GameRules`, the interface each game implements |
| `lib/src/games/smt4` | `Smt4Rules`, with the rules in plain words at the top |
| `test` | rule tests and `smt4_golden.json` (recipes from an independent port of the upstream code) |
| `benchmark` | `dart run benchmark/recipes_benchmark.dart` |

Run `dart test` here after any change. See ../../docs/ARCHITECTURE.md for how the app uses it.
