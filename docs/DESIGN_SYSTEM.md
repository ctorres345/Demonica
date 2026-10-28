# Design system: "Terminal"

Dark-first Material 3 with a light twin. Tokens live in `lib/design_system/tokens.dart`, the `ThemeData` in `theme.dart`, components in `components.dart`. Screens read colors through `context.dc` (DemonicaColors) and `context.ec` (ElementColors), never as literals, so a direction swap is one file.

## Color

| Token | Dark | Light | Use |
| --- | --- | --- | --- |
| bg | #0B0D10 | #F4F6F8 | page |
| surface | #12161B | #FFFFFF | cards, inputs, rows |
| surfaceHigh | #1A2028 | #ECEFF3 | selected rows |
| outline | #2A323D | #D6DCE3 | 1px borders (no shadows) |
| text | #E6EDF3 | #14181D | |
| textMuted | #8B98A5 | #5B6672 | captions, mono labels |
| accent | #3DDCFF | #0A7EA4 | the one accent: selection, primary button, tree root |
| danger | #FF4D6D | #C62F3F | weaknesses, accidents |
| ok | #3DDC97 | #2F7D4F | owned / recruitable (v0.2+) |
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

The three explored directions (Terminal, Gauntlet, Codex) are in the "Demonica Prototypes" artifact shared in the project thread. Terminal is implemented; the other two are token swaps.
