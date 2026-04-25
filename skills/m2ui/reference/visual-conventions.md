# Visual Conventions — Native Metin2 Vocabulary

A new window that "looks Metin2" needs to use Metin2's visual vocabulary: board chrome, gold-accent palette, fixed slot grids, sub-font rendering. This file catalogs that vocabulary so generated UIs blend with existing windows instead of looking like generic flat web mockups.

## Why this matters

Modern UI training data biases LLMs toward flat aesthetic, drop shadows, large rounded corners, custom font weights, and 8px-grid spacing. None of that exists in Metin2's engine. The native look is sharper edges, gold-on-dark titles, sub-pixel `.sub` font rendering, and 32-pixel slot grids. Emitting flat-modern code in this engine produces UIs that visually clash with every other window in the game.

## 1. Window archetypes

Pick the closest archetype before sizing. **The size ranges below are conventions** observed across existing Metin2 windows — they're starting points, not engine constants. Going outside these ranges is fine if your content needs it; check against existing windows in your project before committing.

| Archetype | Typical width | Typical height | When |
|-----------|---------------|----------------|------|
| Slim dialog (yes/no, OK message) | 280-340 | 100-130 | confirmation, alert |
| Standard board (settings, info) | 320-440 | 280-360 | menu, info display |
| Inventory grid window | 175-285 | 470-560 | item containers |
| List-with-detail (shop, mall) | 400-560 | 400-600 | catalog browse |
| Slot picker (skill, channel) | 190-260 | 200-320 | choose-one form |
| Notification toast (top of screen) | 300-500 | 40-60 | transient message |

Source: typical sizes observed across multiple Metin2 packs. See `skills/m2ui/reference/anchors/` for the structural skeleton of each archetype with concrete examples.

## 2. Standard chrome elements

**Board background.** Most windows use either:
- `board` widget type (engine-rendered chrome, automatic title-area carve-out)
- `board_with_titlebar` (board + integrated titlebar; root class accesses titlebar via `self.GetChild("TitleBar")` directly, NOT nested under `GetChild("board")`)
- `expanded_image` with a custom background art (e.g., `cube_bg.tga`) for skinned windows
- 9-corner composite (`boardback_mainboxlefttop.sub` + 7 friends) for fully custom chrome — see anchor `04-9slice-panel.md`

**Close button.** Owned by `titlebar`. Asset is typically the `d:/ymir work/ui/public/close_button_*.sub` family — verify the exact size in your pack (commonly 11×11 or 13×13). Position at top-right of titlebar. Wire via `self.GetChild("TitleBar").SetCloseEvent(ui.__mem_func__(self.Close))` — without this explicit wiring, clicking X does nothing (see failure-atlas entry #2 cause #4).

**Titlebar font.** Engine default — do NOT specify a custom font. The `titlebar` widget renders its title in the engine's standard sub-font.

**Padding conventions (observed, not engine-enforced).**
- Outer (window edge → board edge): typically 0 (board fills the window)
- Title area (titlebar → first content child): typically 26-32 px from window top
- Content padding (board edge → content widgets): typically 8-10 px
- Inter-row padding (between content rows): typically 4-6 px

These ranges produce a visually-consistent feel with existing windows. Deviating is fine for special-purpose windows; verify your output looks balanced.

## 3. Slot conventions

The `grid_table` widget renders slots in a fixed-size cell grid. The single-cell size is 32×32 (engine default tied to the icon-render pipeline). Multi-cell items (e.g., a 2-handed weapon spanning 1×3 cells) occupy multiple rows in the grid; the underlying cell size stays 32×32.

| Slot type | Cell size (px) | Notes |
|-----------|---------------|-------|
| Item slot | 32 × 32 | `grid_table` cell. Multi-cell items span rows via item metadata. |
| Equipment slot | 32 × 32 | Same cell size; layout cells in equipment grids may be 32×64 or 32×96 visually but each occupies one or more 32×32 cells. |
| Skill slot | 32 × 32 | Engine-default skill icon size. |
| Quickslot | 32 × 32 | Same cell size as item slot. |

Standard slot background asset: `d:/ymir work/ui/public/slot_base.sub` (lowercase forward-slash — matches the path discipline rule). Verify the exact path exists in your fork before referencing.

Slot SIZE is a HARD CONSTRAINT imposed by the engine's grid_table widget — do not invent custom cell sizes (e.g., 40×40). Custom sizes desync icon rendering and create alignment chaos. To make a "bigger slot", span multiple cells via item metadata, not by resizing the slot.

## 4. Color palette

The hex codes below are **community conventions** (the values appear consistently across many community-built UIs). They are not engine-enforced — the engine accepts any color. Use these for consistency with existing windows; if your project's existing palette differs, prefer the project's own values.

| Use | Hex | Notes |
|-----|-----|-------|
| Title gold | `0xFFFFCE9C` | Common titlebar/title-text color |
| Standard text | `0xFFFFFFFF` | White, default for body text |
| Disabled / muted | `0xFF888888` | Greyed-out / unavailable |
| Error red | `0xFFFF4444` | Errors, warnings, "cannot do" |
| Highlight yellow | `0xFFFFFF00` | New item glow, urgent attention |
| Success green | `0xFF44FF44` | Confirmations, "available" |

Color format is `0xAARRGGBB`. Construct via `grp.GenerateColor(r, g, b, a)` for runtime coloring (each component 0.0-1.0).

## 5. Asset vocabulary

- **`board`** — Engine widget. Renders standard window chrome (no asset path needed).
- **`board_with_titlebar`** — Engine widget. Board + integrated titlebar. Title via `"title"` key.
- **`thinboard`** / **`thinboard_circle`** — Slimmer variants; chrome is just an inset bordered rectangle.
- **`ExpandedImage`** (`expanded_image`) — Image widget that tiles via `"rect"` (x_units, y_units). Used for tiling backgrounds and 9-slice borders.
- **`ImageBox`** (`image`) — Single non-tiled image. Used for icons, decorations, button surfaces.
- **`AniImage`** — Animated sprite sequence (frame array). Used for active-skill glow, particle UI.
- **`text`** — Text widget. Renders via `.sub` font.

Asset path convention: lowercase, forward-slash (`d:/ymir work/ui/...`), formats `.tga` / `.dds` / `.sub`.

## 6. Anti-patterns (visual)

These produce a non-native look. Avoid:

- **Modern flat aesthetic.** Solid-color rectangles with no chrome. Metin2 windows are bordered and skinned.
- **Custom font weights / families.** Engine renders `.sub` font; bold/italic/custom families are not supported.
- **Drop shadows / blurs.** Not supported by the engine. There is no equivalent — bake any needed depth/glow effect into the texture itself (`.tga` with the shadow pre-rendered).
- **Gradients.** Not supported in widgets. If you need a gradient, render it as a `.tga`.
- **Large rounded corners.** Metin2 chrome uses sharp 1-2px corner radius via `thinboard` etc. Anything larger looks like a foreign element.
- **CSS-style spacing rules.** Spacing is per-pixel manual; there is no margin/padding cascade.
- **Web-color palettes (Tailwind, Material).** Use the palette in section 4 instead. Metin2 has a warm, gold-accented palette, not pastel/neon.

## Cross-references

- Mental model (no flex/grid layout) → `skills/m2ui/reference/mental-model.md`
- Widget catalog (every type with properties) → `skills/m2ui/reference/widgets.md`
- 9-slice border anchor → `skills/m2ui/reference/anchors/04-9slice-panel.md`
- Failure entry #6 (red-X / pink-box) → `skills/m2ui/reference/failure-atlas.md#6-image-shows-as-red-x--pink-box`
