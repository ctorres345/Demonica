# Design system: "Demonica"

Dark-first Material 3 with a light twin. The dark palette is modelled on the Strange Journey and SMT I menus: deep navy panels, light-blue outlines, white text, red for danger, orange/green for HP/MP style accents. Tokens live in `lib/design_system/tokens.dart`, the `ThemeData` in `theme.dart`, components in `components.dart`. Screens read colors through `context.dc` (DemonicaColors), `context.ec` (ElementColors) and text styles through `context.tt`, never as literals, so a palette swap is one file.

## Color

Three palettes, picked on the welcome screen at first start and in Settings, saved on the device (`Palette` in tokens.dart): **Strange Journey** (default, table below), **SMT IV** (bg #0D0D0D, surface #1E1E1E, outline #5E5E5E, accent orange #F7941D, danger red #D8232F, ok green #6FD621) and **Codex** (light by default: parchment #F3EFE6, surface #FBF8F1, outline #CFC6B2, ink #1D1A14, accent deep red #8F1D2C; its dark twin is ink on dark leather). Every palette has a dark and a light variant; `PaletteCard` in palette_card.dart draws the preview used by both screens.

Strange Journey tokens (`DemonicaColors.strangeJourneyDark` / `strangeJourneyLight`):

| Token | Dark | Light | Use |
| --- | --- | --- | --- |
| bg | #050B16 | #EEF3FA | page |
| surface | #0C1C36 | #FFFFFF | cards, inputs, rows |
| surfaceHigh | #173159 | #DCE7F5 | selected rows |
| outline | #3F74B4 | #7A96B8 | 1px borders (no shadows); about 3:1 against the background so the tree lines stay visible |
| text | #F4F7FF | #0A1A33 | |
| textMuted | #92B4E0 | #4A6A94 | captions, mono labels |
| accent | #5CC8FF | #1F6FD0 | the one accent: selection, primary button, tree root |
| danger | #E63946 | #C8252C | weaknesses, accidents |
| ok | #4FE06A | #1F8A3A | success, recruitable (v0.4 locations) |
| onAccent | #03101F | #FFFFFF | text and icons on an accent fill |
| law / neutral / chaos | blue / grey / red | | alignment tags |

Element colors (phys, gun, fire, ice, elec, force, light, dark, almighty, ailment, recovery, support, passive) are defined for both themes and always appear next to a text label.

### Contrast notes (2026-10-29)

- SMT IV light: the accent was darkened from #D97706 to #B45309. White text on the old orange button was 3.2:1; it is now 5.0:1.
- Still below 4.5:1, left as is because they are rarely used as small text: `danger` on `surfaceHigh` in the dark palettes, and `ok` on light backgrounds. Revisit when v0.4 starts using `ok` for recruit flags.

## Type

- Display and headers: Chakra Petch 500 to 700.
- Body: Inter 400 to 600.
- Numbers and captions: JetBrains Mono 400 to 500, uppercase with letter-spacing for captions.

Fonts are bundled in `assets/fonts` so the app works offline.

## Shape and space

4pt grid (`Space.x1` to `Space.x8`), radius 4 for controls and rows, 8 for cards, 1px outlines, no elevation. 48dp minimum tap targets.

## Components

All in `lib/design_system/`. Reuse these before writing a new widget.

| Component | File | Purpose |
| --- | --- | --- |
| `DemonTile` | components.dart | list row: level badge, name (+ recruit mark), race, obtain tag or alignment |
| `RecruitMark` | components.dart | green speech-bubble icon with tooltip: the demon can be recruited, fusing is optional |
| `LevelBadge` | components.dart | mono level with "LV" caption |
| `Tag`, `AlignmentTag`, `FusionTag` | components.dart | small outlined mono labels |
| `ElementDot` | components.dart | colored square before a skill name, always next to a label |
| `ResistRow` | components.dart | 8 cells: – / WK / RS / NU / RP / DR |
| `SkillRow` | components.dart | element dot, name, element + MP, learn level, unique tag |
| `SectionHeader` | components.dart | uppercase mono caption with optional trailing note |
| `SheetHeader` | components.dart | bottom sheet title with Clear and Done |
| `showLevelSheet` | components.dart | bottom sheet with a 1 to 99 level slider (compendium filter, tree filter) |
| `macca()` | components.dart | `36710` -> `36 710 ¥` |
| `PaletteCard`, `PalettePicker`, `ThemeModePicker` | palette_card.dart | palette previews and the dark/light switch (welcome screen and Settings) |
| `PixelHelmet` | pixel_icon.dart | the 12x12 pixel helmet, drawn crisp at any size |
| `RecipeRow` | features/recipes/recipe_row.dart | A × B with race and level, kind tag, macca, optional caret and trailing button |

## Rules for changing the design system

1. **New color?** Add it to `DemonicaColors` for all six variants (3 palettes × dark/light), to `lerp`, and to the table above. A color that only exists in one palette is a bug.
2. **New size or gap?** Use `Space.x1`..`x8` (4pt grid) and `Radii`. A one-off number like `10` is fine inside a component, not in a screen.
3. **New text style?** Prefer an existing `context.tt` style with `copyWith`. Add to `theme.dart` only when three or more places need it.
4. **New component?** Put it here when two or more screens use it. Keep screen-only widgets private (`_Name`) in the screen's file.
5. **Contrast.** `text` and `textMuted` on `bg`/`surface`, and `onAccent` on `accent`, must reach 4.5:1; `accent` on `bg` at least 3:1. `test/design_tokens_test.dart` checks all six variants, so a palette edit that breaks this fails the tests.
6. **Never color alone.** Elements, resistances and alignments always carry a text label too.

## Layout

Below 840dp (`wideBreakpoint`): bottom navigation (Demons, Skills, Plan, Saved, Settings) and push navigation. At 840dp and above: navigation rail with the pixel helmet, compendium list (360dp) on the left, detail or tree on the right. The Saved tab shows a badge with the number of entries not ticked off. Web uses real paths: `/smt4/demons`, `/smt4/demon/lilith`, `/smt4/demon/lilith/tree`, `/smt4/skills`, `/plan`, `/saved`, `/settings`, `/welcome`.

## Prototypes

The three explored directions (Terminal, Gauntlet, Codex) are in the "Demonica Prototypes" artifact shared in the project thread. The implemented palette started from Terminal and was retuned to the Strange Journey / SMT I colors; the other two are token swaps.

## Icon

`assets/brand/icon.svg` is the source of the app icon: the Demonica helmet as 24x24 pixel art on a navy rounded square. `assets/brand/icon-small.svg` is the 12x12 version, also drawn in code by `PixelHelmet` for the rail and app bar. The PNGs under `web/`, `android/.../mipmap-*` and `ios/Runner/Assets.xcassets/AppIcon.appiconset` are rendered from it at 1024px; re-render with headless Chromium (or any SVG rasterizer) when the SVG changes. iOS and the maskable web icons use the square version (no rounded corners) because the platform applies its own mask.
