---
name: m2ui
description: >
  Generate and modify Metin2 client UI code from screenshots, natural language,
  or existing scripts. Creates uiscript dicts, root ui*.py classes, and locale entries.
  Use when: user says "/m2ui", "create UI", "make a window", "modify UI",
  "add button to", "screenshot to UI", "check UI for bugs", "diagnose".
  Supports four modes: screenshot (from image), talk (from description),
  script (modify existing), diagnose (audit for anti-patterns).
---

# /m2ui — Metin2 UI Generator

## Mode Detection

Detect mode from user input using this priority:

1. **Explicit keyword**: args start with `screenshot`, `talk`, `script`, or `diagnose` → use that mode
2. **Image attached**: user message contains an image/screenshot → screenshot mode
3. **Diagnose request**: args say "check", "audit", "review", "diagnose", "find bugs in" → diagnose mode
4. **File reference**: args reference a `.py` file in `uiscript/` or `root/` (e.g., `uimovechannel.py`, `MoveChannelDialog.py`) → script mode
5. **Text description**: any other text → talk mode
6. **No args**: bare `/m2ui` → interactive (ask user what they want to do)

## Dispatch

Based on detected mode, read the corresponding mode file from `modes/` directory adjacent to this SKILL.md:

- Screenshot mode → read `modes/screenshot.md`, then follow its instructions
- Talk mode → read `modes/talk.md`, then follow its instructions
- Script mode → read `modes/script.md`, then follow its instructions
- Diagnose mode → read `modes/diagnose.md`, then follow its instructions
- Interactive → ask: "What would you like to do? (a) Create new UI from screenshot, (b) Describe a new UI to build, (c) Modify an existing UI file, (d) Diagnose an existing UI for bugs" — then dispatch to the chosen mode

## Before Generating Any Code

Always load these reference files (adjacent to this SKILL.md in `reference/` directory):

1. `reference/event-binding.md` — callback wrapping matrix (mandatory for every window)
2. `reference/patterns.md` — code templates, boilerplate, best practices
3. `reference/widgets.md` — widget type catalog with properties
4. `reference/locale.md` — locale string format and rules

Read `reference/bindings.md` only when you need to verify whether a specific C++ Python function exists (e.g., user wants to call `player.GetSomeFunction()` — check if it's registered).

> **Note:** Phases 2 and 3 of the m2ui quality uplift will expand this into a full conditional-load decision matrix. For now, the four files above plus on-demand bindings.md are the floor.

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
5. **Callback wrapping** — every callback that references `self` MUST use one of: `ui.__mem_func__()`, `SAFE_SetEvent` (if fork provides it), or `lambda r=proxy(self): r.X()`. Never bare bound methods or self-capturing lambdas. **See `reference/event-binding.md` for the full matrix and decision flow.**
6. **`Open()`/`Close()`** pattern — `Open` calls `Show()`, `Close` calls `Hide()`
7. **`OnPressEscapeKey()`** returns `True` (always; not `False`)
8. **`OnMouseWheel()`** returns `True` or `False` based on whether it consumed the event
9. **No hardcoded strings** — all user text via `localeInfo.*` or `uiScriptLocale.*`
10. **`constInfo.intWithCommas()`** for large numbers
11. **`"not_pick"` flag** on decorative elements (lines, separators, background images)
12. **Z-order**: create widgets in back-to-front order (SetParent call order = render order)
13. **Parent bounds clip picking**: size parents large enough to contain all interactive children
14. **Python 2.7** target — use `//` for int division, `in` not `has_key()`, keep `xrange`. See `reference/patterns.md` Section 8 for full py2/py3 compatibility rules
15. **Asset paths must exist** — before referencing any image path (`d:/ymir work/ui/...`), verify the file exists in `D:\ymir work\ui\` via Glob. If a new asset is needed, emit `# TBD ASSET: <path> — needs creation` instead of inventing.
16. **Verified C++ APIs only** — before calling any function from `net`, `player`, `item`, `chr`, `app`, `wndMgr`, `chat`, `quest`, verify it exists in `reference/bindings.md`. If absent: ask the user, OR emit a stub with `# TODO: verify <module>.<func> exists in your fork`. Never invent.

## Pre-Emit Self-Review

Before showing generated code to the user OR writing any file, run this checklist silently. If any item fails: revise the draft and re-check. Do NOT emit user-visible output unless the gate trips and you need clarification.

1. `@ui.WindowDestroy` on every `Destroy()` method
2. All `self.X` assignments listed in `Initialize()` (or `__Initialize()`)
3. Every callback wrapped per `reference/event-binding.md` matrix (`ui.__mem_func__`, `SAFE_SetEvent`, `lambda r=proxy(self): r.X()`, or no-self lambda); never bare bound method or `lambda: self.X()`
4. `OnPressEscapeKey()` returns `True` (not `False`); `OnMouseWheel()` returns `True`/`False`
5. All user-visible strings via `localeInfo.*` or `uiScriptLocale.*` (no hardcoded text)
6. All decorative elements have `"not_pick"` flag (images, lines, bars, backgrounds)
7. Parent bounds contain all interactive children (mouse picking respects parent rect)
8. Z-order = back-to-front SetParent call order (later children render on top)
9. Image paths verified to exist under `D:\ymir work\ui\` via Glob (or noted as `# TBD ASSET: ...`)
10. C++ API calls verified in `reference/bindings.md` (or noted as `# TODO: verify ...`)
11. Python 2.7 compatibility (`//` not `/`, `in` not `has_key()`, keep `xrange`)
12. uiscript dict filename matches the `LoadScriptFile()` arg in the root class
13. Script-backed windows: `Destroy()` calls `ClearDictionary()`
14. `__del__` calls `ui.ScriptWindow.__del__(self)`

If checklist passes: proceed to emit/write. If any item fails: revise silently and re-run.

## After Code Generation

Always provide an **interfacemodule.py integration snippet** showing:
- Import line (guarded by feature flag if applicable)
- Instance creation (in MakeInterface or __init__)
- Tooltip binding (if applicable): `SetItemToolTip(self.tooltipItem)` / `SetSkillToolTip(self.tooltipSkill)`
- `BindInterface(self)` if window needs interface access
- Toggle method for taskbar/keybind hookup
- `Destroy()` call in cleanup section
- `Hide()` call in HideAllWindows
