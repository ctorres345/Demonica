# Demonica: project plan (v2, 2026-10-28)

Related docs: [ARCHITECTURE.md](ARCHITECTURE.md) (how the code is built), [DESIGN_SYSTEM.md](DESIGN_SYSTEM.md) (look and components), [CODING_GUIDELINES.md](CODING_GUIDELINES.md) (rules for code), [../CONTRIBUTING.md](../CONTRIBUTING.md) (how changes land and releases).

## Goal

Make fusing a specific demon in SMT IV easy: pick the target, filter by the skills you want, read the recipe tree, and later follow a step-by-step plan. The existing tool (aqiu384's megaten-fusion-tool) has the data but a confusing UI, flat recipe lists, no chaining into an ingredient's own recipes, and no recruit locations.

## Decisions

| Topic | Decision |
| --- | --- |
| Game scope | SMT IV only in v1, behind `GameRules` so SMT IV Apocalypse, SMT V and Persona can be added with one adapter and one import script each |
| Platforms | Web first (GitHub Pages, installable PWA, which is also the iOS path), Android APK on GitHub Releases, iOS IPA best effort. No app stores |
| Player state | None tied to the game's saves: the app is a companion. Only bookmarked recipes and paths, on the device, exportable (v0.2) |
| Visual style | Three game-inspired palettes (Strange Journey, SMT IV, Codex) chosen at first start or in Settings; dark-first Material 3, 1px outlines, Chakra Petch + Inter + JetBrains Mono. Light theme mirrors it |
| Data | Upstream JSON at a pinned commit, decoded by `tool/import_smt4.dart`. Our own curated `locations.json` later |
| Tracker | Jira project DEM |

## Facts from the data (corrects plan v1)

- 454 demons (426 fusable or recruitable + 28 enemy-only) in 48 races, 261 skills, 67 special recipes, 12 fusion accidents.
- SMT IV has no inheritance affinities. Any skill can be inherited except 18 unique skills (rank 900+ in the data). Free slots = 8 minus the demon's innate skills.
- The macca price is computed from stats, innate skills and resistances; the import ports the formula and matches the existing tool.
- Unlock categories: Story Progression, Challenge Quests, New Game+, Fiend Encounters (all on by default) and Downloadable Content (off by default).

## Fusion rules (as implemented in `Smt4Rules`)

1. Two different races: result race from the chart, result level = ceil((a + b) / 2) + 1, lowest demon of that race at or above it. If the fusion lands above the race's top fusable demon it fails.
2. Same race: the Element demon on the chart diagonal.
3. Element + demon: one rank up or down in the demon's race, per the element chart.
4. Special demons: fixed ingredient list only.
5. Accidents and enemy-only demons cannot be produced.

Reverse recipes run the same rules backwards and are checked against an independent port for 20 demons (`packages/fusion_core/test/smt4_golden.json`).

## Roadmap

| Phase | Contents | Gate |
| --- | --- | --- |
| MVP (done) | Scaffold, design system, data import, compendium + filters, demon detail, reverse recipes, expandable tree, skills lookup, settings | Recipes match the existing tool |
| v0.2 Saved recipes (done) | Bookmark a recipe or a whole fusion path, add a note, tick it off when done, export/import as a file. No level or owned-demon tracking (SMT IV shows fusions above your level and sells apps to fuse past the cap) | |
| v0.3 Planner (done) | Target + wanted skills, bounded search over recipes, step checklist with macca totals | Inheritance rule (8 minus innate) still to be confirmed in-game (DEM-7); it is one function, `freeSkillSlots` |
| v0.4 Locations | Curated `locations.json` (IGN demon locations as the main source), recruit flag in tree, route and spoiler tags | |
| v1.0 Releases | GitHub Actions: Pages deploy, APK and unsigned IPA on releases, runbook | |

## Risks

| Risk | Handling |
| --- | --- |
| Recipe differs from the existing tool | Golden tests; the existing tool's site could not be reached from the build environment, so the cross-check is against an independent port of its code. Spot-check in the browser |
| Inheritance rule detail is wrong | Planner waits for the in-game check |
| Curating locations is slow | Separate phase, shipped incrementally |
| iOS without a paid Apple account | PWA is the iOS path |
| Atlus IP | Names and numbers only, disclaimer, GitHub-only distribution |

## Open questions

See the thread in the Demonica project. Defaults in use: skill slots = 8 minus innate, DLC off, recipes sorted by cheapest macca with a switch, one Jira epic per phase.

## Saved recipes (v0.2, as built)

- Bookmark a demon (no recipe yet), a single recipe, or the open path of the tree as a plan. Ids are built from the content, so saving or importing the same thing twice merges.
- The tree keeps one open recipe per demon, so the open part is always one path. A plan's steps are leaves first; each step's macca counts only ingredients that are bought, not ones fused earlier in the plan.
- Stored in `shared_preferences` under `demonica.saved.v1` in the same JSON as the export file (`format: demonica.saved`, `version: 1`). Import rejects other files and newer versions, skips unknown demons, and replaces entries with the same id.

## Planner (v0.3, as built)

- Input is only a target demon and the wanted skills, plus a switch for leveling ingredients. Nothing about the player's level, party or Compendium.
- Output is up to three plans, cheapest first. Each step: ingredients, result, skills to keep on the fusion screen, ingredients to level first, macca for the ingredients bought at that step.
- A plan saves into the same `path` entry as v0.2 plans. Steps gain two optional fields, `skills` and `levelUps`, written only when set, so v0.2 files still read the same.
- When there is no plan the screen says why: not fusable, unique skill, not enough free slots, or nothing within 3 fusions.
