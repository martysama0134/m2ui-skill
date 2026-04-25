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

Read these reference files adjacent to this mode file (in `../reference/`):
- `skills/m2ui/reference/event-binding.md` for the callback wrapping matrix (mandatory)
- `reference/widgets.md` for exact property names and valid values
- `reference/patterns.md` for the appropriate style template
- `reference/locale.md` for locale string rules

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

## Step 6: Review with User

Show the generated code and ask:
- "Does this match what you see in the screenshot?"
- "Any elements I missed or got wrong?"
- "Any position/size adjustments needed?"

Iterate until user approves, then write files to:
- uiscript: `pack/pack/uiscript/uiscript/`
- root class: `pack/pack/root/`
- locale: auto-detect paths per `reference/locale.md` — glob for locale files, ask user if ambiguous
