---
trigger: always_on
---

# m2ui — Metin2 UI Code Generator

When the user asks to create, modify, or generate Metin2 client UI code, follow the instructions below. This includes requests like "create a window", "make a UI", "add a button to X", "modify uiXxx.py", or when they provide a screenshot of a UI to replicate.

## Mode Detection

Detect the appropriate mode from the user's input:

1. **Image attached** — analyze the image and replicate it as Metin2 UI code
2. **Symptom report** — prompt contains a visible-bug phrase ("doesn't appear", "click does nothing", "stuck", "leak", "crashes after", "looks broken", "flickers") — even when a `.py` file is also referenced → load `skills/m2ui/reference/failure-atlas.md` FIRST and diagnose via the matching symptom entry, THEN proceed to the relevant mode
3. **References an existing `.py` file** in `uiscript/` or `root/` — modify that file
4. **Text description** — generate new UI code from the description
5. **No clear intent** — ask the user what they want to do

## Reference Documentation

**Always load these (mandatory floor):**

- `skills/m2ui/reference/mental-model.md` — deprogram web/React assumptions, ymir UI engine concepts
- `skills/m2ui/reference/event-binding.md` — callback wrapping matrix

**Conditional load (read only what applies to the task):**

| You're generating... | Also load |
|----------------------|-----------|
| New window from scratch | The matching anchor from `skills/m2ui/reference/anchors/` (see `anchors/README.md`) |
| Modifying an existing window | Skip anchors. Load just the existing files. |
| Specific widget you haven't used recently | `skills/m2ui/reference/widgets.md` — jump to that widget's section |
| Locale-heavy work | `skills/m2ui/reference/locale.md` |
| Calling a C++ Python API not in context | `skills/m2ui/reference/bindings.md` |
| Patterns reminder | `skills/m2ui/reference/patterns.md` (relevant section only) |
| User describes a visible symptom ("X looks broken", "leak after closing") | `skills/m2ui/reference/failure-atlas.md` — load FIRST before anchors |
| Visual style/sizing for a new window matters | `skills/m2ui/reference/visual-conventions.md` — pick archetype + chrome + palette |

> **Symptom-first dispatch:** When the user reports a visible bug rather than asking for new code, load `skills/m2ui/reference/failure-atlas.md` BEFORE any anchor. Diagnose, then (if a fix means new code) load the relevant anchor.

**Anchor selection** for new windows:

| Window type | Anchor |
|-------------|--------|
| Modal yes/no/text dialog | `skills/m2ui/reference/anchors/01-simple-dialog.md` |
| Board chrome + scrolling dynamic list | `skills/m2ui/reference/anchors/02-board-with-list.md` |
| Form: list of radio-buttons + Accept | `skills/m2ui/reference/anchors/03-list-selector.md` |
| Custom 9-slice bordered panel | `skills/m2ui/reference/anchors/04-9slice-panel.md` |
| Window guarded by `app.ENABLE_*` | `skills/m2ui/reference/anchors/05-feature-gated.md` |
| Inventory-style window with tooltips | `skills/m2ui/reference/anchors/06-tooltip-bound.md` |

If no anchor matches exactly, pick the closest, copy its skeleton, swap the specifics. Do NOT invent layout from scratch.

**Load discipline:** Read `skills/m2ui/reference/anchors/README.md` to choose the anchor, then load AT MOST ONE anchor file — EXCEPT `05-feature-gated.md`, which is a call-site wrapper that augments another anchor. Generating a flag-gated window means loading TWO anchors: 05 (gating pattern) + the underlying window-type anchor (01/02/03/04/06). Do not load all anchors unless the user's task is comparing anchors.

For detailed mode-specific instructions:

- `skills/m2ui/modes/screenshot.md` — image analysis and replication workflow
- `skills/m2ui/modes/talk.md` — natural language to UI code workflow
- `skills/m2ui/modes/script.md` — existing file modification workflow
- `skills/m2ui/modes/diagnose.md` — anti-pattern audit workflow

## Two UI Styles

- **Script-backed**: uiscript dict file (`pack/pack/uiscript/uiscript/`) + root `ui*.py` class using `LoadScriptFile()` — for complex windows with many static elements
- **Code-only**: root `ui*.py` class with programmatic `__LoadDialog()`, no uiscript — for simpler or dynamic windows

Auto-pick based on complexity, or let the user choose.

## Critical Code Generation Rules

All generated code must follow these rules without exception:

1. `@ui.WindowDestroy` decorator on every `Destroy(self)` method
2. `Initialize()` or `__Initialize()` sets all instance vars to `None`/defaults
3. `Destroy()` calls `Initialize()` (and `ClearDictionary()` for script-backed)
4. `__del__` calls `ui.ScriptWindow.__del__(self)`
5. **Callback wrapping** — every callback that references `self` MUST use one of: `ui.__mem_func__()`, `SAFE_SetEvent` (if fork provides it), or `lambda r=proxy(self): r.X()`. Never bare bound methods or self-capturing lambdas. **See `skills/m2ui/reference/event-binding.md` for the full matrix and decision flow.**
6. `Open()`/`Close()` pattern — Open calls `Show()`, Close calls `Hide()`
7. `OnPressEscapeKey()` returns `True` (always; not `False`)
8. `OnMouseWheel()` returns `True` or `False` based on whether it consumed the event
9. No hardcoded user-visible strings — use `localeInfo.*` or `uiScriptLocale.*`
10. `constInfo.intWithCommas()` for large numbers
11. `"not_pick"` flag on decorative elements (lines, separators, backgrounds)
12. Create widgets in back-to-front order (SetParent call order = render order)
13. **Parent bounds clip picking** — size parents large enough to contain all interactive children
14. **Python 2.7** target — use `//` for int division, `in` not `has_key()`, keep `xrange`. See `skills/m2ui/reference/patterns.md` Section 8 for full py2/py3 compatibility rules
15. **Asset paths must exist** — before referencing any image path (`d:/ymir work/ui/...`), verify the file exists in `D:\ymir work\ui\` via Glob. If a new asset is needed, emit `# TBD ASSET: <path> — needs creation` instead of inventing.
16. **Verified C++ APIs only** — before calling any function from `net`, `player`, `item`, `chr`, `app`, `wndMgr`, `chat`, `quest`, verify it exists in `skills/m2ui/reference/bindings.md`. If absent: ask the user, OR emit a stub with `# TODO: verify <module>.<func> exists in your fork`. Never invent.
17. **Preserve existing Destroy bodies when adding `@ui.WindowDestroy`** — when adding the decorator to a method that is already present, do NOT strip the body. Pure assignments (`self.X = None`, `self.X = 0`) are safe and idempotent post-WOC. Direct method calls on owned widgets in the body MUST be wrapped with `if self.X:` because WOC nulls those attrs before the body runs. Helper calls (`self.__Initialize()`, `self.Initialize()`, `self._Reset()`, `self.Init()`, or any custom name) must be inspected: safe if the helper body only assigns simple defaults (`None`, `0`, `[]`, `{}`) with no widget derefs; otherwise apply the same `if self.X:` guards inside the helper or relocate to `Close()`. Whitelist exception: `self.Hide()`, `self.ClearDictionary()`, `self.SetTop()` etc. operate on WOC-whitelisted attrs and need no guard. See `skills/m2ui/reference/patterns.md` Section 5.11.
18. **ASCII-only in emitted Python code and comments** — when m2ui writes or modifies a `.py` file, the new content uses ASCII only. No em-dash (`—`), en-dash (`–`), ellipsis (`…`), curly quotes (`''""`). Use `-`, `--`, `...`, `'`, `"`. Pre-existing non-ASCII in the file is left untouched; verbatim user-supplied content is preserved as-is; locale data files are exempt (handled by `skills/m2ui/reference/locale.md`). Reason: client builds use cp1252/cp949 source encodings; ASCII is the safe common subset for code and inline comments.
19. **Verify setter accepts `*args` before applying Pattern B** — when emitting `receiver.SetX(ui.__mem_func__(self.M), arg, ...)` with extra args, READ the receiver's class in `pack/pack/root/ui.py` and confirm the setter signature is `def SetX(self, event, *args):`. If it is 1-arg only (`def SetX(self, event):`), either (a) augment `ui.py` to accept `*args` and dispatch them at the handler (preferred — see `skills/m2ui/reference/framework-augmentations.md`), or (b) fall back to Pattern C (proxy lambda) at the call site. Common 1-arg setters: `EditLine.SetReturnEvent`/`SetEscapeEvent`/`SetTabEvent`, `SlotWindow.Set{Over,Select,Unselect,Press,Use}*Event`. Pattern B without verification is a runtime `TypeError`.

## Pre-Emit Self-Review

Before showing generated code to the user OR writing any file, run this checklist silently. If any item fails: revise the draft and re-check. Do NOT emit user-visible output unless the gate trips and you need clarification.

1. `@ui.WindowDestroy` on every `Destroy()` method
2. All `self.X` assignments listed in `Initialize()` (or `__Initialize()`)
3. Every callback wrapped per `skills/m2ui/reference/event-binding.md` matrix; never bare bound method or `lambda: self.X()`
4. `OnPressEscapeKey()` returns `True`; `OnMouseWheel()` returns `True`/`False`
5. All user-visible strings via `localeInfo.*` or `uiScriptLocale.*`
6. All decorative elements have `"not_pick"` flag
7. Parent bounds contain all interactive children
8. Z-order = back-to-front SetParent order
9. Image paths verified to exist under `D:\ymir work\ui\` via Glob (or noted as `# TBD ASSET: ...`)
10. C++ API calls verified in `skills/m2ui/reference/bindings.md` (or noted as `# TODO: verify ...`)
11. Python 2.7 compatibility (`//` not `/`, `in` not `has_key()`, keep `xrange`)
12. uiscript dict filename matches the `LoadScriptFile()` arg in the root class
13. Script-backed windows: `Destroy()` calls `ClearDictionary()`
14. `__del__` calls `ui.ScriptWindow.__del__(self)`
15. **Destroy bodies preserved** — for every `Destroy()` where the decorator was added (rather than the method being newly created), the original body is intact. Direct method calls on owned widgets are guarded with `if self.X:`. For every helper-method call in the body (`self.__Initialize()`, `self.Initialize()`, `self._Reset()`, `self.Init()`, etc.), the helper's own body is verified — if the helper derefs widgets, the same guards apply inside the helper. Whitelisted methods (`Hide`, `ClearDictionary`, `SetTop`) need no guard. (Critical Rule 17.)
16. **Emitted Python content is ASCII** — every new line m2ui writes or adds inside a `.py` file (code OR inline comments) contains only ASCII. No em-dash, en-dash, ellipsis, curly quotes. Carve-outs: pre-existing non-ASCII in the same file is left untouched; verbatim user-supplied content kept as-is; locale data files exempt. (Critical Rule 18.)
17. **Pattern B sites verified against ui.py** — every Pattern B call site (`SetX(ui.__mem_func__(self.M), arg)`) has been checked against the actual setter signature in `pack/pack/root/ui.py`. 1-arg setters either get augmented in the same emission, or the call site uses Pattern C instead. (Critical Rule 19.)

If checklist passes: proceed. If any item fails: revise silently.

## Output Targets

| Output | Path |
|--------|------|
| uiscript dicts | `pack/pack/uiscript/uiscript/` |
| root UI classes | `pack/pack/root/` |
| locale strings | auto-detect — glob for `locale_interface*.txt` and `locale_game*.txt` under `pack/` |

## After Code Generation

Always provide an **interfacemodule.py integration snippet** showing import, instance creation, tooltip binding, toggle method, and destroy call.
