# Design system: "Demonica"

Dark-first Material 3 with a light twin. The dark palette is modelled on the Strange Journey and SMT I menus: deep navy panels, light-blue outlines, white text, red for danger, orange/green for HP/MP style accents. Tokens live in `lib/design_system/tokens.dart`, the `ThemeData` in `theme.dart`, components in `components.dart`. Screens read colors through `context.dc` (DemonicaColors) and `context.ec` (ElementColors), never as literals, so a direction swap is one file.

## Color

Two palettes, picked in Settings and saved on the device (`Palette` in tokens.dart): **Strange Journey** (default, table below) and **SMT IV** (bg #0D0D0D, surface #1E1E1E, outline #4A4A4A, accent orange #F7941D, danger red #D8232F, ok green #6FD621). Both have a dark and a light variant.

| Token | Dark | Light | Use |
| --- | --- | --- | --- |
| bg | #050B16 | #EEF3FA | page |
| surface | #0C1C36 | #FFFFFF | cards, inputs, rows |
| surfaceHigh | #173159 | #DCE7F5 | selected rows |
| outline | #3F74B4 | #9DB7D8 | 1px borders (no shadows) |
| text | #F4F7FF | #0A1A33 | |
| textMuted | #92B4E0 | #4A6A94 | captions, mono labels |
| accent | #5CC8FF | #1F6FD0 | the one accent: selection, primary button, tree root |
| danger | #E63946 | #C8252C | weaknesses, accidents |
| ok | #4FE06A | #1F8A3A | owned / recruitable (v0.2+) |
| law / neutral / chaos | blue / grey / red | | alignment tags |

Element colors (phys, gun, fire, ice, elec, force, light, dark, almighty, ailment, recovery, support, passive) are defined for both themes and always appear next to a text label.

## Type

- Display and headers: Chakra Petch 500 to 700.
- Body: Inter 400 to 600.
- Numbers and captions: JetBrains Mono 400 to 500, uppercase with letter-spacing for captions.

Fonts are bundled in `assets/fonts` so the app works offline.

## Shape and space

4pt grid (`Space.x1` to `Space.x8`), radius 4 for controls and rows, 8 for cards, 1px outlines, no elevation. 48dp minimum tap targets.

## Components

| Component | Purpose |
| --- | --- |
| `DemonTile` | list row: level badge, name, race, obtain tag or alignment |
| `LevelBadge` | mono level with "LV" caption |
| `Tag`, `AlignmentTag`, `FusionTag` | small outlined mono labels |
| `ResistRow` | 8 cells: – / WK / RS / NU / RP / DR |
| `SkillRow` | element dot, name, element + MP, learn level, unique tag |
| `RecipeRow` | A × B with race and level, kind tag, macca, optional caret |
| `SectionHeader` | uppercase mono caption with optional trailing note |

## Layout

Below 840dp: bottom navigation (Demons, Skills, Settings) and push navigation. At 840dp and above: navigation rail, compendium list (360dp) on the left, detail or tree on the right. Web uses real paths: `/smt4/demons`, `/smt4/demon/lilith`, `/smt4/demon/lilith/tree`, `/smt4/skills`, `/settings`.

## Prototypes

The three explored directions (Terminal, Gauntlet, Codex) are in the "Demonica Prototypes" artifact shared in the project thread. The implemented palette started from Terminal and was retuned to the Strange Journey / SMT I colors; the other two are token swaps.

## Icon

`assets/brand/icon.svg` is the source: a simplified Demonica helmet (gold dome, red visor eyes, side antennas, top sensor) on a navy rounded square. The PNGs under `web/`, `android/.../mipmap-*` and `ios/Runner/Assets.xcassets/AppIcon.appiconset` are rendered from it at 1024px; re-render with headless Chromium (or any SVG rasterizer) when the SVG changes. iOS and the maskable web icons use the square version (no rounded corners) because the platform applies its own mask.
