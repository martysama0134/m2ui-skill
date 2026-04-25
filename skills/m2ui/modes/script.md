# Script Mode

User wants to modify existing UI files. They've referenced a specific file or window by name.

## Step 1: Locate and Read Files

Find the referenced files:
- If user gives a root file name (e.g., `uimovechannel.py`): read from `pack/pack/root/`
- If user gives a uiscript name (e.g., `MoveChannelDialog.py`): read from `pack/pack/uiscript/uiscript/`
- If user gives a window class name (e.g., `MoveChannelWindow`): grep for it in `pack/pack/root/ui*.py`

For script-backed windows, find BOTH files:
- The root `ui*.py` class — look for `LoadScriptFile` call to find the uiscript path
- The corresponding uiscript dict file

Read both files completely before proceeding.

## Step 2: Understand Current State

Before making changes:
- List all existing child elements (from uiscript dict or `InsertChild` calls)
- Identify the UI style (script-backed vs code-only)
- Check if `@ui.WindowDestroy` is present — if not, add it
- Check if `ui.__mem_func__` is used consistently
- Note any feature flags (`app.BL_*`, `app.ENABLE_*`)
- Note existing `Initialize()` / `__Initialize()` method and what it resets

## Generating a Root Class from an Existing Uiscript

When the user provides a uiscript and asks to create the root `ui*.py`
class for it, follow this checklist:

1. **Parse all named children** — extract every `"name"` value from
   the uiscript dict tree (recursive, including nested children).
   Use these EXACT names in `GetChild()` calls — preserve typos and
   unconventional naming (e.g., `imporve_slot`, `impove_text_window`).

2. **Identify the board type** — check if the root child is `"board"`
   or `"board_with_titlebar"`. For `board_with_titlebar`, the close
   event goes on the board itself (`self.board.SetCloseEvent(...)`),
   NOT on a separate titlebar child.

3. **Classify each widget** as interactive or decorative:
   - **Interactive**: buttons, editlines, slots, grid_tables, scrollbars,
     radio_buttons, toggle_buttons → need `GetChild()` + event wiring
   - **Decorative**: images, expanded_images, text labels, bars, lines
     → typically no `GetChild()` needed unless updated at runtime
   - **Containers**: windows used as viewports for dynamic content →
     need `GetChild()` for runtime population
   - **Drag targets**: an `image` widget can serve as a drag-drop target
     (e.g., improvement/enhancement slot). Classify based on context
     and naming, not just widget type — if it looks like a slot area
     where items are dropped, treat it as interactive

4. **Handle empty viewport + scrollbar patterns** — if the uiscript has
   an empty `"window"` type child with a nearby `"scrollbar"`, this is
   a container for dynamically-populated content (list items, cards).
   Generate stub methods for populating it at runtime.

5. **Generate Initialize()** with a `None` entry for every interactive
   widget and dynamic data structure.

6. **Wire events** for all interactive widgets:
   - Buttons → `SetEvent(ui.__mem_func__(self.OnXxx))`
   - Editlines → hook `OnIMEUpdate` if text changes matter
   - Scrollbars → `SetScrollEvent(ui.__mem_func__(self.__OnScroll))`
   - Slots/grid_tables → `SetSelectEmptySlotEvent`, `SetOverInItemEvent`, etc.

7. **Generate stub methods** for every event handler with `pass` body.

8. **Handle path constants** — if the uiscript uses constants like
   `ROOT_PATH = "d:/ymir work/ui/game/cube/"`, note them but don't
   reproduce in the root class (they're uiscript-only).

9. **LoadScriptFile path** — use full lowercase path. The pack system
   converts all file paths to lowercase and `\\` to `/`. Example:
   `pyScrLoader.LoadScriptFile(self, "uiscript/cuberenewalwindow.py")`
   NOT `"UIScript/CubeRenewalWindow.py"`.

10. **Uiscript properties are auto-applied** — properties like
    `only_number`, `input_limit`, `secret_flag`, `text` on editlines
    are handled by `PythonScriptLoader` during `LoadScriptFile`. Don't
    duplicate them in the root class (e.g., don't call
    `SetNumberMode()` if the uiscript already has `"only_number": 1`).

## Step 3: Apply Modifications

Based on user's request:

**Adding elements to uiscript dict:**
- Find the correct `"children"` tuple to insert into
- Add new element dict with proper indentation
- Match existing formatting style (spacing, comma placement)
- Give new elements unique `"name"` values

**Adding elements to code-only window:**
- Add widget creation in `__LoadDialog()` method
- Follow existing creation order (z-order matters — later = on top)
- Use `SetParent()`, `SetPosition()`, `Show()`, `InsertChild()`
- All callbacks through `ui.__mem_func__()`

**Adding handler methods to root class:**
- Add method definitions in the class
- Wire up events in `__LoadWindow()` or `__LoadDialog()`
- Add any new instance vars to `Initialize()` / `__Initialize()`

**Adding locale strings:**
- Read `reference/locale.md` for format rules and path auto-detection
- Glob for locale files, ask user if multiple locale dirs found
- Append to appropriate locale file
- Use `localeInfo.KEY` in root files, `uiScriptLocale.KEY` in uiscript dicts

## Step 4: Pre-Emit Self-Review

Before showing the user the diff OR writing any file, run the Pre-Emit Self-Review checklist defined in `skills/m2ui/SKILL.md` (the `## Pre-Emit Self-Review` section). All items apply to MODIFIED code, not just freshly generated code. Pay special attention to:

- Modifications must preserve `@ui.WindowDestroy` and `Initialize()` patterns
- New child elements need unique `"name"` values for `GetChild()`
- New callbacks follow `reference/event-binding.md` matrix
- New instance vars added to `Initialize()` (set to None)

Revise silently and re-check until all items pass. Do NOT mention the gate to the user unless an item legitimately requires user input.

## Step 5: Show Changes

Present the diff to the user before writing:
- For uiscript changes: show the full modified dict section
- For root class changes: show the added/modified methods
- For locale additions: show the new entries
- Apply changes only after user confirms
