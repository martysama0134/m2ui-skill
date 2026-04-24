---
name: m2ui
description: >
  Generate and modify Metin2 client UI code from screenshots, natural language,
  or existing scripts. Creates uiscript dicts, root ui*.py classes, and locale entries.
  Use when: user says "/m2ui", "create UI", "make a window", "modify UI",
  "add button to", "screenshot to UI". Supports three modes: screenshot (from image),
  talk (from description), script (modify existing).
---

# /m2ui — Metin2 UI Generator

## Mode Detection

Detect mode from user input using this priority:

1. **Explicit keyword**: args start with `screenshot`, `talk`, or `script` → use that mode
2. **Image attached**: user message contains an image/screenshot → screenshot mode
3. **File reference**: args reference a `.py` file in `uiscript/` or `root/` (e.g., `uimovechannel.py`, `MoveChannelDialog.py`) → script mode
4. **Text description**: any other text → talk mode
5. **No args**: bare `/m2ui` → interactive (ask user what they want to do)

## Dispatch

Based on detected mode, read the corresponding mode file from `modes/` directory adjacent to this SKILL.md:

- Screenshot mode → read `modes/screenshot.md`, then follow its instructions
- Talk mode → read `modes/talk.md`, then follow its instructions
- Script mode → read `modes/script.md`, then follow its instructions
- Interactive → ask: "What would you like to do? (a) Create new UI from screenshot, (b) Describe a new UI to build, (c) Modify an existing UI file" — then dispatch to the chosen mode

## Before Generating Any Code

Always read these reference files (adjacent to this SKILL.md in `reference/` directory):

1. `reference/patterns.md` — code templates, boilerplate, best practices
2. `reference/widgets.md` — widget type catalog with properties
3. `reference/locale.md` — locale string format and rules

Read `reference/bindings.md` only when you need to verify whether a specific C++ Python function exists (e.g., user wants to call `player.GetSomeFunction()` — check if it's registered).

## Output Targets

| Output | Path |
|--------|------|
| uiscript dicts | `pack/pack/uiscript/uiscript/` |
| root UI classes | `pack/pack/root/` |
| locale strings | **auto-detect** — see `reference/locale.md` for path resolution |

## Critical Rules

These rules apply to ALL generated code, in ALL modes:

1. **`@ui.WindowDestroy`** on every `Destroy(self)` method
2. **`Initialize()` or `__Initialize()`** sets all instance vars to `None`/defaults
3. **`Destroy()` calls `Initialize()`** and optionally `ClearDictionary()` (script-backed only)
4. **`__del__`** calls `ui.ScriptWindow.__del__(self)`
5. **`ui.__mem_func__()`** for every callback referencing `self` — no exceptions
6. **No lambda with `self`** — pass extra args directly to event setters instead
7. **`Open()`/`Close()`** pattern — `Open` calls `Show()`, `Close` calls `Hide()`
8. **`OnPressEscapeKey()`** returns `True`
9. **No hardcoded strings** — all user text via `localeInfo.*` or `uiScriptLocale.*`
10. **`constInfo.intWithCommas()`** for large numbers
11. **`"not_pick"` flag** on decorative elements (lines, separators, background images)
12. **Z-order**: create widgets in back-to-front order (SetParent call order = render order)
13. **Event return values**: `OnPressEscapeKey`, `OnMouseWheel` must return `True`/`False`
14. **Parent bounds clip picking**: size parents large enough to contain all interactive children

## After Code Generation

Always provide an **interfacemodule.py integration snippet** showing:
- Import line (guarded by feature flag if applicable)
- Instance creation (in MakeInterface or __init__)
- Tooltip binding (if applicable): `SetItemToolTip(self.tooltipItem)` / `SetSkillToolTip(self.tooltipSkill)`
- `BindInterface(self)` if window needs interface access
- Toggle method for taskbar/keybind hookup
- `Destroy()` call in cleanup section
- `Hide()` call in HideAllWindows
