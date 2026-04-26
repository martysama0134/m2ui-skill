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

<SUBAGENT-STOP>
If you were dispatched as a subagent with a specific task description, skip this skill's mode-detection flow and execute the assigned task directly. The parent agent has already loaded the relevant m2ui context and selected the mode for you. Re-running the full dispatch wastes tokens and may second-guess the parent's choice.
</SUBAGENT-STOP>

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
5. <EXTREMELY-IMPORTANT>
   **Callback wrapping** — every callback that references `self` MUST use one of: `ui.__mem_func__()`, `SAFE_SetEvent` (if fork provides it), or `lambda r=proxy(self): r.X()`. NEVER bare bound methods (`btn.SetEvent(self.OnClick)`) or self-capturing lambdas (`btn.SetEvent(lambda: self.OnClick())`). Both leak — the button's reference to the bound method holds `self` alive past `Destroy`, and the engine never garbage-collects. This is the single most common bug in community Metin2 code. See `reference/event-binding.md` for the full matrix and decision flow.
   </EXTREMELY-IMPORTANT>
6. **`Open()`/`Close()`** pattern — `Open` calls `Show()`, `Close` calls `Hide()`
7. **`OnPressEscapeKey()`** returns `True` (always; not `False`)
8. **`OnMouseWheel()`** returns `True` or `False` based on whether it consumed the event
9. **No hardcoded strings** — all user text via `localeInfo.*` or `uiScriptLocale.*`
10. **`constInfo.intWithCommas()`** for large numbers
11. **`"not_pick"` flag** on decorative elements (lines, separators, background images)
12. **Z-order**: create widgets in back-to-front order (SetParent call order = render order)
13. **Parent bounds clip picking**: size parents large enough to contain all interactive children
14. **Python 2.7** target — use `//` for int division, `in` not `has_key()`, keep `xrange`. See `reference/patterns.md` Section 8 for full py2/py3 compatibility rules
<EXTREMELY-IMPORTANT>
15. **Asset paths must exist** — before referencing any image path (`d:/ymir work/ui/...`), verify the file exists in `D:\ymir work\ui\` via Glob. If a new asset is needed, emit `# TBD ASSET: <path> — needs creation` instead of inventing. Inventing a path produces a red-X / pink-box at runtime (failure-atlas entry 6).
16. **Verified C++ APIs only** — before calling any function from `net`, `player`, `item`, `chr`, `app`, `wndMgr`, `chat`, `quest`, verify it exists in `reference/bindings.md`. If absent: ask the user, OR emit a stub with `# TODO: verify <module>.<func> exists in your fork`. NEVER invent. Inventing a binding produces an `AttributeError` traceback at runtime, often crashing the calling window.
</EXTREMELY-IMPORTANT>
17. <EXTREMELY-IMPORTANT>
    **Preserve existing Destroy bodies when adding `@ui.WindowDestroy`** — when an existing `Destroy(self)` method is missing the decorator, ADD the decorator but DO NOT strip the body. Pure assignments (`self.X = None`, `self.X = 0`) are safe — they run after WOC's pre-clean and remain idempotent. **Any helper method call** from the Destroy body — `self.__Initialize()`, `self.Initialize()`, `self._Reset()`, `self.Init()`, `self.ClearState()`, or any custom name — MUST be inspected: if its body only assigns simple defaults (`None`, `0`, empty list `[]`, empty dict `{}`) and contains no widget derefs or method calls on owned widgets, it is safe; if it derefs owned widgets (calls methods on `self.X` widget refs), those calls inside the helper need the same `if self.X:` guards (or the helper's risky calls relocate to `Close()`). Direct method calls on owned widgets in the Destroy body itself (`self.confirmDialog.Hide()`, `self.acceptButton.SetEvent(0)`, `self.X.ClearDictionary()`) MUST be guarded with `if self.X:` because WOC nulls those attrs before the body runs. Whitelist exception: `self.Hide()`, `self.ClearDictionary()`, `self.SetTop()` and other methods that operate on `hWnd` / `ElementDictionary` / `Children` / `parentWindow` / `windowName` / `WocIsDestroyed` / `WocIsCleaned` are safe — those attrs survive WOC. Stripping the body deletes user intent (defensive cleanup, state reset for reuse, owned-dialog cleanup); guarding is a 3-character change that preserves it. See `reference/patterns.md` Section 5.11.
    </EXTREMELY-IMPORTANT>
18. **ASCII-only in emitted Python code and code comments** — when m2ui WRITES or MODIFIES a `.py` file, the new content uses ASCII only. No em-dash (`—`), en-dash (`–`), ellipsis (`…`), curly quotes (`''""`). Use `-`, `--`, `...`, `'`, `"` instead. Two carve-outs: (a) pre-existing non-ASCII in the file is left untouched — the rule constrains what m2ui adds, not what is already there; (b) verbatim user-supplied content (a comment the user wrote and asked to preserve, or user-provided text being passed through) keeps its original characters. Locale data files (translated user-visible strings) are NOT covered by this rule — those follow `reference/locale.md` encoding rules. Reason: client builds use cp1252/cp949 source encodings; ASCII is the safe common subset for source code and inline comments.
19. <EXTREMELY-IMPORTANT>
    **Verify setter accepts `*args` before applying Pattern B** — when about to emit `receiver.SetX(ui.__mem_func__(self.M), arg1, ...)` (Pattern B / Pattern E with extra args), READ the receiver's class in `pack/pack/root/ui.py` and confirm `def SetX(self, event, *args):` (or equivalent). If the setter is 1-arg only (`def SetX(self, event):`), the call site will raise `TypeError: SetX() takes exactly 2 arguments (N given)` at runtime. Two responses are correct: (a) AUGMENT the setter in `ui.py` to accept `*args` and dispatch them at the handler site (preferred — see `reference/framework-augmentations.md` for the three-piece template: init the args attr, store `*args`, dispatch with `*self.eventXxxArgs`); (b) fall back to Pattern C with `proxy(self)` at the call site (only when augmentation is impossible — C++ binding, fork-specific transform, or user opt-out). Setters commonly affected: `EditLine.SetReturnEvent`/`SetEscapeEvent`/`SetTabEvent`, `SlotWindow.SetOverInItemEvent`/`SetSelectItemSlotEvent`/`SetPressedSlotButtonEvent` etc. Do NOT trust by name — verify the actual file.
    </EXTREMELY-IMPORTANT>

## Pre-Emit Self-Review

<EXTREMELY-IMPORTANT>
This gate is mandatory and runs BEFORE any output to the user. Skipping it is the single biggest cause of regression reports against this skill — every previous user-reported bug (memory leaks, missing decorators, alignment surprises, off-screen widgets) traces back to a failed silent self-review. Run the full checklist on every emission, even on edits to existing files.
</EXTREMELY-IMPORTANT>

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
15. **Alignment semantics resolved** — for every widget with `all_align`, `horizontal_align: "center"`, or `vertical_align: "center"`, mentally resolve the FINAL screen position. `all_align` re-anchors to PARENT CENTER (the widget's `(x, y)` becomes an offset from center, not absolute coords). Confirm the resolved position is intended. NEVER use `all_align` on a child whose y is meaningful as an absolute coord. (See `reference/widgets.md` text section + `reference/mental-model.md` Section 1.)
16. **Computed rect within parent bounds** — for every widget, `child.x + child.width <= parent.width` AND `child.y + child.height <= parent.height` AFTER alignment is applied. Children of `board_with_titlebar` must also clear the engine titlebar (`y >= 32`).
17. **Destroy bodies preserved** — for every `Destroy()` where the decorator was added (rather than the method being newly created), the original body is intact. Direct method calls on owned widgets are guarded with `if self.X:`. For every helper-method call in the body (`self.__Initialize()`, `self.Initialize()`, `self._Reset()`, `self.Init()`, etc.), the helper's own body is verified — if the helper derefs widgets, the same guards apply inside the helper. Whitelisted methods (`Hide`, `ClearDictionary`, `SetTop` etc. that touch only WOC-whitelisted attrs) need no guard. (Critical Rule 17.)
18. **Emitted Python content is ASCII** — every new line m2ui writes or adds inside a `.py` file (code OR inline comments) contains only ASCII. No em-dash, en-dash, ellipsis, curly quotes. Carve-outs: pre-existing non-ASCII in the same file is left untouched; verbatim user-supplied content kept as-is; locale data files exempt (handled by locale rules). (Critical Rule 18.)
19. **Pattern B sites verified** — every `receiver.SetX(ui.__mem_func__(self.M), arg, ...)` in the emission has been checked against the actual setter signature in `pack/pack/root/ui.py`. If the setter takes only `(self, event)`, either (a) `ui.py` is being augmented in the same emission to add `*args` support (init + setter + dispatch — see `reference/framework-augmentations.md`), or (b) the call site is downgraded to Pattern C (proxy lambda). Pattern B without `*args`-capable setter is a runtime `TypeError` waiting to fire. (Critical Rule 19.)

If checklist passes: proceed to emit/write. If any item fails: revise silently and re-run.

**Optional second-pass review.** For high-stakes generations (screenshot mode, multi-file edits, gated windows), dispatch the `m2ui-pre-emit-reviewer` subagent BEFORE emission as an independent audit. The reviewer cites file:line for every finding and proposes no fixes — it surfaces issues for you to address. Use it when the silent self-review feels like cargo-cult or when the user has reported regressions in similar windows before. Distinct from `diagnose` mode, which audits user-supplied existing files.

## After Code Generation

Always provide an **interfacemodule.py integration snippet** showing:
- Import line (guarded by feature flag if applicable)
- Instance creation (in MakeInterface or __init__)
- Tooltip binding (if applicable): `SetItemToolTip(self.tooltipItem)` / `SetSkillToolTip(self.tooltipSkill)`
- `BindInterface(self)` if window needs interface access
- Toggle method for taskbar/keybind hookup
- `Destroy()` call in cleanup section
- `Hide()` call in HideAllWindows
