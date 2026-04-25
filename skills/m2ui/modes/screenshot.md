# Screenshot Mode

You have received an image to replicate as Metin2 UI code. Follow these steps:

## Step 1: Analyze the Image

Identify all visible UI elements and map them to Metin2 widget types:

| Visual Element | Widget Type |
|----------------|------------|
| Window frame with border | `board` or `board_with_titlebar` |
| Title bar with close button | `board_with_titlebar` or `titlebar` |
| Clickable button | `button` |
| Radio/tab selector | `radio_button` |
| Toggle switch | `toggle_button` |
| Static text/label | `text` |
| Input field | `editline` |
| Static image/icon | `image` |
| Scalable background | `expanded_image` |
| Item/equipment slot | `grid_table` or `slot` |
| Progress bar | `gauge` |
| Scrollable list | `listbox` + `scrollbar` |
| Dropdown | `ComboBox` (programmatic only, no uiscript type) |
| Horizontal divider | `horizontalbar` |
| Tab group | multiple `radio_button` with shared event |
| Thin bordered panel | `thinboard` or `thinboard_circle` |
| Solid color rect | `bar` |
| Line separator | `line` |

## Step 2: Estimate Layout

- Estimate pixel positions and sizes from the image proportions
- Metin2 UI uses absolute positioning (x, y coordinates)
- Common window widths: 200-400px. Common heights: 150-500px
- Standard button height: ~25px. Standard slot: 32x32px
- Board padding: ~10-15px on each side
- Title bar: typically 30px tall, offset x=6 y=7 from board top
- Button images auto-size the button — width/height optional in dict

## Step 3: Ask User

1. **Style**: "Script-backed (uiscript dict + root class) or code-only (programmatic root class)?"
   - Suggest script-backed if 5+ static elements
   - Suggest code-only if dynamic/few elements
2. **File names**: "What should the files be named?" (suggest based on window purpose)
3. **Feature flags**: "Should this be gated behind an `app.*` flag?"

## Step 4: Generate Code

Read these reference files (paths relative to repo root):
- `skills/m2ui/reference/event-binding.md` for the callback wrapping matrix (mandatory)
- `skills/m2ui/reference/widgets.md` for exact property names, valid values, and per-widget caveats (read EVERY widget section for widgets the layout uses — chrome/sizing rules and gotchas live in those sections, e.g., the `text` `all_align` re-anchor warning, the `ComboBox` dropdown-direction caveat)
- `skills/m2ui/reference/visual-conventions.md` for chrome / archetype / palette rules — mandatory for screenshot replication so the output uses native vocabulary, not the source mockup's aesthetic
- `skills/m2ui/reference/patterns.md` for the appropriate style template
- `skills/m2ui/reference/locale.md` for locale string rules

Generate:
1. The uiscript file (if script-backed style) or `__LoadDialog` method (if code-only)
2. The root `ui*.py` class with all required patterns:
   - `@ui.WindowDestroy` on `Destroy()`
   - `Initialize()` setting all vars to None
   - `__del__` calling `ui.ScriptWindow.__del__(self)`
   - `Open()`/`Close()` pattern
   - `OnPressEscapeKey()` returning `True`
   - All callbacks with `self` wrapped per `skills/m2ui/reference/event-binding.md` matrix (`ui.__mem_func__`, `SAFE_SetEvent` if fork provides it, or `lambda r=proxy(self): r.X()`)
3. Locale string entries to append to appropriate `locale_*_ex.txt`
4. An interfacemodule.py integration snippet

## Step 5: Pre-Emit Self-Review

Before showing the user the generated code OR writing any file, run the Pre-Emit Self-Review checklist defined in `skills/m2ui/SKILL.md` (the `## Pre-Emit Self-Review` section). Revise silently and re-check until all items pass. Do NOT mention the gate to the user unless an item legitimately requires user input (e.g., asset doesn't exist and you need to confirm path).

**Screenshot-mode-specific geometry self-check** (in addition to the SKILL.md checklist):

For every widget in the generated uiscript / `__LoadDialog`, mentally resolve its FINAL screen rect after engine alignment is applied, then verify:

- Each widget with `all_align` (or paired `horizontal_align: "center"` + `vertical_align: "center"`): apply the parent-center re-anchor (per `widgets.md` text section warning). The `(x, y)` becomes an OFFSET from parent center, not absolute coords. Does the resolved screen position still match what the screenshot shows?
- Body children of `board_with_titlebar`: do their resolved y-coords sit BELOW the engine titlebar bottom (~32 px) and ABOVE the parent's bottom edge?
- ComboBox widgets: does each have at least `(item_count * 17 + 10)` px of clear space directly below before the next interactive widget? If not, refactor per `widgets.md` ComboBox caveat (mitigation a/b/c/d) BEFORE emitting.
- Section headers / labels positioned by absolute y: cross-check the resolved y against the source screenshot's pixel position of the same label. If the offset is large, the alignment semantics resolved differently than intended (most often `all_align` was used where it shouldn't have been).

If ANY widget resolves to a position that contradicts the source screenshot, revise the dict (drop `all_align`, recompute coords, restructure layout) and re-run the geometry self-check before proceeding.

## Step 6: Review with User

Show the generated code and ask:
- "Does this match what you see in the screenshot?"
- "Any elements I missed or got wrong?"
- "Any position/size adjustments needed?"

Iterate until user approves, then write files to:
- uiscript: `pack/pack/uiscript/uiscript/`
- root class: `pack/pack/root/`
- locale: auto-detect paths per `skills/m2ui/reference/locale.md` — glob for locale files, ask user if ambiguous
