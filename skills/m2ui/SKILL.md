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
4. **Symptom report**: args contain a visible-bug phrase ("doesn't appear", "doesn't open", "doesn't work", "click does nothing", "X is broken", "looks broken", "leak", "crashes after", "stuck", "flickers") — even when a `.py` file is also referenced → load `reference/failure-atlas.md` FIRST and diagnose via the matching symptom entry, THEN proceed to script mode (if a code fix is needed) or talk mode
5. **File reference**: args reference a `.py` file in `uiscript/` or `root/` (e.g., `uimovechannel.py`, `MoveChannelDialog.py`) → script mode
6. **Text description**: any other text → talk mode
7. **No args**: bare `/m2ui` → interactive (ask user what they want to do)

## Dispatch

Based on detected mode, read the corresponding mode file from `modes/` directory adjacent to this SKILL.md:

- Screenshot mode → read `modes/screenshot.md`, then follow its instructions
- Talk mode → read `modes/talk.md`, then follow its instructions
- Script mode → read `modes/script.md`, then follow its instructions
- Diagnose mode → read `modes/diagnose.md`, then follow its instructions
- Interactive → ask: "What would you like to do? (a) Create new UI from screenshot, (b) Describe a new UI to build, (c) Modify an existing UI file, (d) Diagnose an existing UI for bugs" — then dispatch to the chosen mode

## Before Generating Any Code

**Always load these (mandatory floor):**

1. `reference/mental-model.md` — deprogram web/React assumptions, ymir UI engine concepts
2. `reference/event-binding.md` — callback wrapping matrix

**Conditional load (read only what applies to the task):**

| You're generating... | Also load |
|----------------------|-----------|
| New window from scratch | The matching anchor from `reference/anchors/` (see anchor decision matrix in `reference/anchors/README.md`) |
| Modifying an existing window | Skip anchors. Load just the existing files. |
| Specific widget you haven't used recently | `reference/widgets.md` — jump to that widget's section |
| Locale-heavy work (lots of new strings) | `reference/locale.md` |
| Calling a C++ Python API (`net.X`, `player.X`, etc.) NOT already in context | `reference/bindings.md` — grep for the function |
| Patterns reminder needed (Initialize/Destroy, scrollbar wiring, ListBoxEx, integration template) | `reference/patterns.md` — jump to the relevant section |
| Auditing existing code for anti-patterns | Mode-specific: `modes/diagnose.md` already loaded by mode dispatch |
| User describes a visible symptom ("X looks broken", "click does nothing", "leak after closing") | `reference/failure-atlas.md` — jump to the matching symptom heading FIRST, before loading anchors |
| Composing a window from scratch where the visual style/sizing matters | `reference/visual-conventions.md` — pick archetype + chrome + palette before coding |

**Anchor selection** — when generating from scratch, pick the closest anchor:

| Window type | Anchor |
|-------------|--------|
| Modal yes/no/text dialog | `reference/anchors/01-simple-dialog.md` |
| Board chrome + scrolling dynamic list | `reference/anchors/02-board-with-list.md` |
| Form: list of radio-buttons + Accept | `reference/anchors/03-list-selector.md` |
| Custom 9-slice bordered panel | `reference/anchors/04-9slice-panel.md` |
| Window guarded by `app.ENABLE_*` flag | `reference/anchors/05-feature-gated.md` |
| Inventory-style window with `SetItemToolTip` | `reference/anchors/06-tooltip-bound.md` |

If no anchor matches exactly, pick the closest, copy its skeleton, swap the specifics. Do NOT invent layout from scratch — start from a working pattern.

**Load discipline:** Read `reference/anchors/README.md` to choose the anchor, then load AT MOST ONE anchor file — EXCEPT `05-feature-gated.md`, which is a call-site wrapper that augments another anchor. Generating a flag-gated window means loading TWO anchors: 05 (for the gating pattern) + the underlying window-type anchor (01/02/03/04/06). Do not load all anchors unless the user's task is comparing anchors. Same applies to widgets.md/locale.md/bindings.md/patterns.md — load only the section you need, not the whole file.

> **Symptom-first dispatch:** When the user reports a visible bug rather than asking for new code, load `reference/failure-atlas.md` BEFORE any anchor. Diagnose, then (if a fix means new code) load the relevant anchor.

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
