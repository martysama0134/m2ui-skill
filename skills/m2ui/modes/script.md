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
- Read `reference/locale.md` for format rules
- Append to appropriate locale file
- Use `localeInfo.KEY` in root files, `uiScriptLocale.KEY` in uiscript dicts

## Step 4: Verify Consistency

After modifications:
- All new callbacks use `ui.__mem_func__()`
- No lambda captures `self` — pass extra args directly to event setters
- All new instance vars added to `Initialize()` (set to None)
- No hardcoded strings — all user-visible text through `localeInfo.*` or `uiScriptLocale.*`
- `@ui.WindowDestroy` still present and `Destroy()` calls `Initialize()`
- New elements have unique `"name"` values for `GetChild()`
- `"not_pick"` flag on any new decorative elements
- Event handlers return `True`/`False` where required (OnPressEscapeKey, OnMouseWheel)

## Step 5: Show Changes

Present the diff to the user before writing:
- For uiscript changes: show the full modified dict section
- For root class changes: show the added/modified methods
- For locale additions: show the new entries
- Apply changes only after user confirms
