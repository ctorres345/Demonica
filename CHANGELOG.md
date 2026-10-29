# Changelog

User-visible changes, newest first. Dates are when the change reached `main`.

## Unreleased

- Recipe tree: a bar above the tree says how many recipes are open ("Path: 2 steps") and has a SAVE PATH button. It replaces the bookmark icon at the top and the help text under the tree.
- Saved: only the tick box and the step text tick a step, so taps while scrolling no longer tick things by accident. "Add note" and "Open in tree" are buttons on each card; the bin icon removes it (with Undo).
- Compendium: "Sort: Level / Name / Race" next to the demon count. Race order lists each race from weakest to strongest.
- Level filters: -/+ buttons and a number field next to the slider.
- Tutorial: each page shows a picture of the real screen. The last page asks "Are you early in the story?". Yes hides the demons that story bosses unlock until you tick them in Settings > Unlocks.

## 1.0.0 (2026-10-29)

First public release.

- Web app at https://ctorres345.github.io/Demonica/. It works offline after the first visit, and can be added to the home screen on iPhone and Android.
- Android APK (and an unsigned iOS IPA) attached to each GitHub Release, built with `tool/release.sh`.
- Settings: privacy note and an "Open source licences" page listing Flutter, the packages and the fonts.
- MIT licence for the code. README: install table, offline use, how-to steps, roadmap with other games, credits.
- Tutorial: five short pages after the welcome screen. Settings → "Show the tutorial again" reopens it.
- Unlocks: the story, quest, New Game+, Fiend and DLC switches moved from Settings to their own page, as a checklist of what you have done. A locked demon's page shows its unlock condition with the same tick.
- Settings: Help section with the tutorial, "Report a wrong recipe" and a contact address (demonica@cjtech.dev).
- Easier to read, from a UX review: bigger captions and tab labels (12 px minimum), stronger outlines in the light palettes and SMT IV dark, a visible focus ring on desktop.
- Demon page: tapping a skill now keeps the demon in the back stack; "+N more in the tree" is a link; the ¥ price is explained; "Used in" rows no longer split race from level.
- Compendium: "Show locked demons" chip only appears when something is locked; races are listed alphabetically; the empty state has a "Clear search and filters" button; a wrong demon link shows a "Browse demons" button. The duplicate settings icon is gone.
- Skills: "4 demons" instead of a bare number; skills nobody learns are dimmed.
- Plan: "SHOW IN TREE", and "2 to inherit · 6 slots free".
- Welcome screen says what the app is before asking for a palette.
- Fixed: fusions that land above the strongest demon of a race now give that demon, like the game does (Thor, Cerberus and Kali gained up to 96 recipes each). Checked against aqiu384's calculator.
- Macca prices are hidden by default (in-game discounts change the real numbers). Settings → "Show macca prices" turns them on; "Cheapest first" sorting works either way.

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
