# Demonica

A friendlier fusion compendium for **Shin Megami Tensei IV**, built with Flutter for web, Android and iOS.

Pick the demon you want, see every recipe that produces it, and expand any ingredient into its own recipes without leaving the screen. Filter the compendium by skill ("who learns Mediarahan?"), race and level.

> Unofficial fan tool. Not affiliated with Atlus or Sega. Demon names and numbers belong to their owners; no game art is included.

## What works today (MVP)

- **Compendium**: 454 demons, search, filters by skill, race, max level, and a toggle for demons you have disabled.
- **Demon page**: stats, resistances, ailments, skills with learn level and MP cost, innate and free skill slots, how to obtain it, evolution links, re-summon price.
- **Recipe tree**: every normal, element and special recipe, sorted by macca or by lowest ingredient level, with any ingredient expandable in place.
- **Skills**: reverse lookup from a skill to the demons that learn it.
- **Settings**: dark/light theme, and switches for story, quest, New Game+, Fiend and DLC demons so recipes only use what you have unlocked.
- Works offline. All data ships inside the app.

Planned next (see `docs/PROJECT.md`): save slots with your level and owned demons, a skill planner with a step checklist, curated recruit locations, and GitHub releases for Android and iOS.

## Run it

```sh
flutter pub get
flutter run -d chrome          # web
flutter run                    # a connected phone or emulator
flutter build web --release --no-web-resources-cdn
```

Tests:

```sh
(cd packages/fusion_core && dart test)   # fusion engine, golden recipes
flutter test                             # widget smoke tests
flutter analyze
```

## Layout

```
packages/fusion_core/   pure Dart: models, GameRules, Smt4Rules, reverse recipes (no Flutter)
tool/import_smt4.dart   decodes upstream data at a pinned commit into assets/data/smt4/
assets/data/smt4/       the decoded game data the app ships
lib/design_system/      tokens, Material 3 theme (dark + light), components
lib/features/           compendium, demon detail, recipe tree, skills, settings
lib/app/                router (go_router), state (Riverpod), adaptive shell
docs/                   project plan, design system notes, runbook
```

## Data and credits

Fusion data comes from [aqiu384/megaten-fusion-tool](https://github.com/aqiu384/megaten-fusion-tool), released into the public domain (Unlicense). Thank you. The import script pins the upstream commit it reads from and decodes the compact upstream format once; the app never touches the raw files.

Fonts: Chakra Petch, Inter and JetBrains Mono, all under the SIL Open Font License.
