# Talk Mode

User described a UI window in natural language. Generate Metin2 UI code from the description.

## Step 1: Parse the Description

Extract:
- **Window purpose** — what does it do?
- **Elements mentioned** — buttons, slots, text, inputs, tabs, lists
- **Behavior** — what happens on click, on open, on close?
- **Data sources** — does it need player data, item data, network calls?

## Step 2: Clarify Ambiguities

Ask ONE question at a time if the description is incomplete. Common clarifications:

- "How many slots/tabs/buttons?"
- "What size should the window be? (small: ~200x150, medium: ~300x250, large: ~400x400)"
- "Should it have a title bar with close button?"
- "Any feature flag gate? (`app.ENABLE_*`)"
- "What file names? (suggest: `uiXxxYyy.py` for root, `XxxYyyDialog.py` for uiscript)"

Don't ask if the description already answers it. Don't ask more than 3 questions total.

## Step 3: Choose Style

Auto-decide based on complexity:
- **Script-backed** if: 5+ static elements, standard layout, mostly declarative
- **Code-only** if: fewer elements, dynamic content, conditional elements, calculated positions

Tell the user which style you chose and why. Let them override.

## Step 4: Generate Code

Read these reference files adjacent to this mode file (in `../reference/`):
- `reference/widgets.md` for exact property names and valid values
- `reference/patterns.md` for the appropriate style template
- `reference/locale.md` for locale string rules

Generate:
1. The uiscript file (if script-backed) or `__LoadDialog` method (if code-only)
2. The root `ui*.py` class with full boilerplate:
   - `@ui.WindowDestroy` on `Destroy()`
   - `Initialize()` setting all vars to None
   - `__del__` calling `ui.ScriptWindow.__del__(self)`
   - `Open()`/`Close()` pattern
   - `OnPressEscapeKey()` returning `True`
   - `ui.__mem_func__()` for all callbacks with `self`
   - No lambda capturing `self` — pass extra args directly to event setters
   - `"not_pick"` flag on decorative elements
   - `constInfo.intWithCommas()` for large numbers
3. Locale string entries to append
4. An interfacemodule.py integration snippet

## Step 5: Write Files

After user approves the generated code:
1. Write uiscript to `pack/pack/uiscript/uiscript/`
2. Write root class to `pack/pack/root/`
3. Append locale entries — auto-detect paths per `reference/locale.md` (glob for locale files, ask user if ambiguous)
4. Show interfacemodule.py snippet for manual integration (don't auto-modify interfacemodule.py — it's too large and complex for blind modification)
