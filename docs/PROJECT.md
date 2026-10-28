# Demonica: project plan (v2, 2026-10-28)

## Goal

Make fusing a specific demon in SMT IV easy: pick the target, filter by the skills you want, read the recipe tree, and later follow a step-by-step plan. The existing tool (aqiu384's megaten-fusion-tool) has the data but a confusing UI, flat recipe lists, no chaining into an ingredient's own recipes, and no recruit locations.

## Decisions

| Topic | Decision |
| --- | --- |
| Game scope | SMT IV only in v1, behind `GameRules` so SMT IV Apocalypse, SMT V and Persona can be added with one adapter and one import script each |
| Platforms | Web first (GitHub Pages, installable PWA, which is also the iOS path), Android APK on GitHub Releases, iOS IPA best effort. No app stores |
| Player state | On the device only, no accounts. Save slots come in v0.2 |
| Visual style | "Terminal": dark-first Material 3, one cyan accent, 1px outlines, Chakra Petch + Inter + JetBrains Mono. Light theme mirrors it |
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
| v0.2 Saves | Save slots, your level, owned/Compendium marks, DLC and unlock toggles per save, ★ and ⚑ badges in the tree | |
| v0.3 Planner | Target + wanted skills, bounded search over recipes, step checklist with macca totals | Cesar confirms the inheritance rule in-game |
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
