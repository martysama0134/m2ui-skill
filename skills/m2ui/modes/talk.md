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
- `reference/event-binding.md` for the callback wrapping matrix (mandatory)
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
   - All callbacks with `self` wrapped per `reference/event-binding.md` matrix (`ui.__mem_func__`, `SAFE_SetEvent` if fork provides it, or `lambda r=proxy(self): r.X()`)
   - No bare bound methods or self-capturing lambdas — pass extra args directly to event setters
   - `"not_pick"` flag on decorative elements
   - `constInfo.intWithCommas()` for large numbers
3. Locale string entries to append
4. An interfacemodule.py integration snippet

## Step 5: Pre-Emit Self-Review

Before showing the user the generated code OR writing any file, run the Pre-Emit Self-Review checklist defined in `skills/m2ui/SKILL.md` (the `## Pre-Emit Self-Review` section). Revise silently and re-check until all items pass. Do NOT mention the gate to the user unless an item legitimately requires user input (e.g., asset doesn't exist and you need to confirm path).

## Step 6: Write Files

After user approves the generated code:
1. Write uiscript to `pack/pack/uiscript/uiscript/`
2. Write root class to `pack/pack/root/`
3. Append locale entries — auto-detect paths per `reference/locale.md` (glob for locale files, ask user if ambiguous)
4. Show interfacemodule.py snippet for manual integration (don't auto-modify interfacemodule.py — it's too large and complex for blind modification)
