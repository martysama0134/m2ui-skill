---
name: m2ui
description: >
  Use when creating, modifying, auditing, or debugging Metin2 client UI code
  (uiscript dicts, root ui*.py classes, locale entries) — user says "/m2ui",
  "create UI", "make a window", "add button to", provides a UI screenshot to
  replicate, asks to "check UI for bugs" / "diagnose", or reports a visibly
  broken window ("doesn't open", "click does nothing", "leaks").
---

# /m2ui — Metin2 UI Generator

<SUBAGENT-STOP>
Dispatched as a subagent with a specific task? Skip mode detection and execute the task directly — the parent agent already loaded m2ui context and picked the mode.
</SUBAGENT-STOP>

## Mode Detection

Priority order:

1. **Explicit keyword**: args start with `screenshot`, `talk`, `script`, or `diagnose` → that mode
2. **Image attached** → screenshot mode
3. **Diagnose request**: args say "check", "audit", "review", "diagnose", "find bugs in" → diagnose mode
4. **Symptom report**: args contain a visible-bug phrase ("doesn't appear", "doesn't open", "doesn't work", "click does nothing", "X is broken", "looks broken", "leak", "crashes after", "stuck", "flickers") — even when a `.py` file is also referenced → load `reference/failure-atlas.md` FIRST, diagnose via the matching symptom entry, THEN script mode (if a code fix is needed) or talk mode
5. **File reference**: args name a `.py` file in `uiscript/` or `root/` → script mode
6. **Text description**: any other text → talk mode
7. **No args**: ask — "(a) Create from screenshot, (b) Describe a new UI, (c) Modify an existing file, (d) Diagnose for bugs" — then dispatch

Read the matching mode file from `modes/` adjacent to this SKILL.md (`screenshot.md`, `talk.md`, `script.md`, `diagnose.md`) and follow it.

## Before Generating Any Code

**Mandatory floor (always load):**

1. `reference/mental-model.md` — ymir engine concepts; deprograms web/React assumptions
2. `reference/event-binding.md` — callback wrapping matrix

**Conditional load (only what the task needs):**

| Task | Load |
|------|------|
| New window from scratch | `reference/anchors/README.md` → walk its 2-step tree (see Anchor selection) |
| Modifying an existing window | Skip anchors; load the existing files |
| Widget you haven't used recently | `reference/widgets.md` — that widget's section |
| Locale-heavy work (many new strings) | `reference/locale.md` |
| C++ Python API (`net.X`, `player.X`, ...) not already in context | `reference/bindings.md` — grep for the function |
| Patterns reminder (Initialize/Destroy, scrollbar wiring, ListBoxEx, integration template, lazy-load sub-windows, inner helper classes, 2D grids) | `reference/patterns.md` — relevant section |
| User reports a visible symptom | `reference/failure-atlas.md` — matching symptom entry FIRST, before any anchor |
| Visual style/sizing matters for a new window | `reference/visual-conventions.md` — pick archetype + chrome + palette before coding |
| Wiring a window into the main interface | `reference/integration.md` (always — after every emission) |
| Window has an OnUpdate body (animation / polling / fade / daily-event timing / movement queues / effect chains) | `reference/timer-patterns.md` |

**Anchor selection (new windows):** walk the 2-step decision tree in `reference/anchors/README.md` — pick exactly ONE primary archetype (the window's chrome; no exact match → closest; never skip this step), plus zero or more augmentors (`05-feature-gated`, `14-drag-and-drop`, `15-network-coupled-flow`, `16-tabbed-content`, `22-compare-tooltip`, `23-auto-hide-chrome`). Read the primary FIRST; augmentors layer on top and never override the primary's lifecycle/structure. Tie-breaker: match the window's CHROME, not its data — "tabbed inventory" = primary `08-inventory-equipment` + augmentor `16-tabbed-content`, NOT `16` alone. For `widgets.md`/`locale.md`/`bindings.md`/`patterns.md`, load only the section you need, not the whole file.

## Output Targets

| Output | Path |
|--------|------|
| uiscript dicts | `pack/pack/uiscript/uiscript/` |
| root UI classes | `pack/pack/root/` |
| locale strings | auto-detect — see `reference/locale.md` |

## Critical Rules

All modes, all generated code. Reference files cite these by number — numbering 1-19 is frozen; new rules append.

1. **`@ui.WindowDestroy`** on every `Destroy(self)` method
2. **`Initialize()` or `__Initialize()`** sets all instance vars to `None`/defaults
3. **`Destroy()` calls `Initialize()`**; script-backed windows also `ClearDictionary()`
4. **`__del__`** calls `ui.ScriptWindow.__del__(self)`
5. <EXTREMELY-IMPORTANT>
   **Callback wrapping** — every callback that references `self` MUST use `ui.__mem_func__()`, `SAFE_SetEvent` (if fork provides it), or `lambda r=proxy(self): r.X()`. NEVER a bare bound method (`btn.SetEvent(self.OnClick)`) or self-capturing lambda (`lambda: self.OnClick()`) — both hold `self` alive past `Destroy` and leak. The single most common bug in community Metin2 code. Full matrix: `reference/event-binding.md`.
   </EXTREMELY-IMPORTANT>
6. **`Open()`/`Close()`** — `Open` calls `Show()`, `Close` calls `Hide()`
7. **`OnPressEscapeKey()`** returns `True` (always; not `False`)
8. **`OnMouseWheel()`** returns `True`/`False` based on whether it consumed the event
9. **No hardcoded strings** — all user text via `localeInfo.*` or `uiScriptLocale.*`
10. **`constInfo.intWithCommas()`** for large numbers
11. **`"not_pick"` flag** on decorative elements (lines, separators, background images)
12. **Z-order**: create widgets back-to-front (SetParent call order = render order)
13. **Parent bounds clip picking** — size parents to contain all interactive children
14. **Python 2.7** target — `//` for int division, `in` not `has_key()`, keep `xrange`. Full py2/py3 rules: `reference/patterns.md` Section 8
<EXTREMELY-IMPORTANT>
15. **Asset paths must exist** — verify every `d:/ymir work/ui/...` path under `D:\ymir work\ui\` via Glob before referencing it. New asset needed → emit `# TBD ASSET: <path> — needs creation`; never invent (invented path = red-X/pink-box at runtime, failure-atlas entry 6).
16. **Verified C++ APIs only** — every call into `net`, `player`, `item`, `chr`, `app`, `wndMgr`, `chat`, `quest` must exist in `reference/bindings.md`. Absent → ask the user OR stub with `# TODO: verify <module>.<func> exists in your fork`; never invent (invented binding = `AttributeError` crash).
</EXTREMELY-IMPORTANT>
17. <EXTREMELY-IMPORTANT>
    **Preserve existing Destroy bodies when adding `@ui.WindowDestroy`** — add the decorator, NEVER strip the body. Pure assignments (`self.X = None`) are safe. Direct method calls on owned widgets (`self.confirmDialog.Hide()`) MUST be guarded with `if self.X:` — WOC nulls those attrs before the body runs. Inspect every helper the body calls (`self.__Initialize()`, `self._Reset()`, any name): defaults-only assignments are safe; widget derefs inside the helper need the same guards (or relocate to `Close()`). No guard needed for `self.Hide()`, `self.ClearDictionary()`, `self.SetTop()` — they touch only WOC-whitelisted attrs. Full whitelist + rationale: `reference/patterns.md` Section 5.11.
    </EXTREMELY-IMPORTANT>
18. **ASCII-only in emitted Python** — new `.py` content m2ui writes (code AND comments) is ASCII: no em/en-dash, ellipsis, curly quotes — use `-`, `--`, `...`, `'`, `"`. Pre-existing non-ASCII and verbatim user-supplied content stay untouched; locale data files exempt (see `reference/locale.md`). Reason: cp1252/cp949 build encodings.
19. <EXTREMELY-IMPORTANT>
    **Verify setter accepts `*args` before Pattern B / Pattern E** — before emitting `receiver.SetX(ui.__mem_func__(self.M), arg, ...)` or `SAFE_SetEvent(self.M, arg, ...)` with extra args, READ the setter in `pack/pack/root/ui.py`. If it is 1-arg (`def SetX(self, event):`), the call raises `TypeError` at runtime. Fix: (a) augment the setter for `*args` per `reference/framework-augmentations.md` (preferred), or (b) fall back to Pattern C proxy lambda. Common 1-arg setters: `EditLine.Set{Return,Escape,Tab}Event`, `SlotWindow.Set*Event`. Never trust by name — verify the actual file.
    </EXTREMELY-IMPORTANT>
20. <EXTREMELY-IMPORTANT>
    **GetChild name contract** — every `GetChild("X")` must match a REGISTERED name: a `"name" : "X"` in the target uiscript's `children` tree, or an explicit `InsertChild("X", widget)` on the code path. The root window dict's own `name` is NOT registered — the window IS `self`; asking for it raises `KeyError` and kills the open flow. `GetChild` RAISES on a missing key, it never returns `None` — `GetChild(x) or fallback` is dead code. Cross-check every `GetChild` before emitting.
    </EXTREMELY-IMPORTANT>

## Pre-Emit Self-Review

<EXTREMELY-IMPORTANT>
Mandatory gate BEFORE any output to the user or any file write, on every emission including edits. Every user-reported regression against this skill (leaks, missing decorators, off-screen widgets) traces back to a skipped self-review.
</EXTREMELY-IMPORTANT>

Silently verify each item against the draft; any failure → revise and re-check. Item numbers are cited by reference files — order is frozen.

1. Rule 1: `@ui.WindowDestroy` on every `Destroy()`
2. Rule 2: every `self.X` assignment listed in `Initialize()`/`__Initialize()`
3. Rule 5: every callback wrapped per `reference/event-binding.md` matrix — no bare bound method, no `lambda: self.X()`
4. Rules 7-8: `OnPressEscapeKey()` returns `True`; `OnMouseWheel()` returns `True`/`False`
5. Rule 9: all user-visible strings via `localeInfo.*`/`uiScriptLocale.*`
6. Rule 11: `"not_pick"` on all decorative elements
7. Rule 13: parent bounds contain all interactive children
8. Rule 12: z-order = back-to-front SetParent order
9. Rule 15: image paths verified via Glob (or `# TBD ASSET: ...`)
10. Rule 16: C++ API calls verified in `reference/bindings.md` (or `# TODO: verify ...`)
11. Rule 14: Python 2.7 compatible (`//`, `in`, `xrange`)
12. uiscript dict filename matches the `LoadScriptFile()` arg in the root class
13. Rule 3: `Destroy()` calls `Initialize()`; script-backed also `ClearDictionary()`
14. Rule 4: `__del__` calls `ui.ScriptWindow.__del__(self)`
15. **Alignment resolved** — for every widget with `all_align` or centered `horizontal_align`/`vertical_align`, mentally resolve the FINAL screen position: `all_align` re-anchors `(x, y)` as an offset from PARENT CENTER, not absolute coords. Never `all_align` on a child whose y is meaningful as absolute. (See `reference/widgets.md` text section.)
16. **Rect within parent** — after alignment, `child.x + width <= parent.width` and `child.y + height <= parent.height`; children of `board_with_titlebar` clear the engine titlebar (`y >= 32`)
17. Rule 17: pre-existing Destroy bodies intact; owned-widget calls guarded with `if self.X:` (including inside helper methods the body calls)
18. Rule 18: all new `.py` content ASCII-only (carve-outs per rule: pre-existing non-ASCII, verbatim user content, locale files)
19. Rule 19: every Pattern B / Pattern E site with extra args checked against the actual setter signature in `ui.py` (augmented or downgraded to Pattern C)
20. Rule 20: every `GetChild` name is registered (uiscript child `"name"` or `InsertChild` call; root window's own name never is; no `GetChild(x) or fallback`)

**Optional second pass:** for high-stakes generations (screenshot mode, multi-file edits, gated windows) or when the silent review feels like cargo-cult, dispatch the `m2ui-pre-emit-reviewer` subagent before emission — independent audit, cites file:line, proposes no fixes. Distinct from diagnose mode (which audits user-supplied files).

## After Code Generation

Always emit an **interfacemodule.py integration snippet**: import (feature-flag-guarded if applicable), instance creation, tooltip binding if applicable, `BindInterface(self)` if needed, toggle method, `Destroy()` in cleanup, `Hide()` in HideAllWindows. Shape + lazy-init/gated-toggle/tooltip variations: `reference/integration.md`.
