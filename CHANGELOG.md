# Changelog

User-visible changes, newest first. Dates are when the change reached `main`.

## 0.4.0 (2026-10-29)

- Demon page: "Where to find" lists the areas where the demon appears, in story order, with the story phase, a route tag for Lucifer's Palace and Purgatorium, and whether it can be recruited there. Fusion-only demons say so.
- Recruit flag: a green speech bubble next to recruitable demons in the compendium, recipe rows and the recipe tree, so you know when talking beats fusing.
- Settings: "Show late-game areas" switch (off by default) hides Blasted Tokyo, Infernal Tokyo and the final dungeons, and a counter shows how many demons have locations.
- Data: 190 recruitable demons in 21 areas, from the GamerGuides walkthrough bestiaries.

## 0.3.0 (2026-10-29)

- Plan tab: pick a target demon and the skills it should end with. Demonica finds up to three fusion chains (up to 3 fusions deep), cheapest first, and says which skills to keep at each step and which ingredients to level up first. Ticking a step saves the plan to the Saved tab.
- Demon page: "Plan with skills" button opens the Plan tab with that demon.
- Saved plans show the skills to keep and the level-ups for each step.
- Faster screens: recipe lists are cached, and changing the palette or theme no longer recomputes recipes. Opening one branch of the recipe tree no longer rebuilds the whole tree.
- SMT IV light palette: darker orange accent so button text is readable (contrast 3.2:1 to 5.0:1).
- Settings shows the app version from one place (`lib/app/version.dart`).
- Docs: architecture, coding guidelines, contributing guide, design system rules.

## 0.2.0 (2026-10-29)

- Saved tab: bookmark a demon, a recipe, or the open path of the recipe tree as a step-by-step plan. Notes, done ticks, export and import as a file.
- Demon page: "Used in" tab with every fusion the demon is part of, sortable by result level.
- Game-style status line on the demon page, 12x12 pixel helmet in the app bar and rail.
- "Report a wrong recipe" link in Settings.

## 0.1.0 (2026-10-28)

- Compendium of all 454 SMT IV demons with search and race, level and skill filters.
- Demon page: stats, resistances, skills, free inherit slots, how to get it.
- Expandable recipe tree: tap any ingredient to see its own recipes.
- Skills lookup: who learns a skill.
- Three palettes (Strange Journey, SMT IV, Codex) in dark and light, picked on a welcome screen or in Settings.
- Settings to turn DLC, quest, NG+ and Fiend demons on or off.
- App icon for web, Android and iOS.
