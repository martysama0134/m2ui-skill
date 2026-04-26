# Diagnose Mode

User wants to audit existing UI code for common anti-patterns and bugs.
Read the file(s) and report all issues found.

## Step 1: Locate and Read Files

Same as script mode:
- If user gives a root file name: read from `pack/pack/root/`
- If user gives a uiscript name: read from `pack/pack/uiscript/uiscript/`
- For script-backed windows, find and read BOTH files

## Step 2: Run Checklist

Check every item below. Report each finding with the line number and
a brief explanation. Group by severity: Critical, Important, Minor.

### Memory Leaks (Critical)

> **Reference:** `skills/m2ui/reference/event-binding.md` — single source of truth for callback wrapping. Acceptable wrappers: `ui.__mem_func__()`, `SAFE_SetEvent` (if fork provides it), `lambda r=proxy(self): r.X()`, or any lambda that does NOT reference `self`.

- [ ] **Missing `@ui.WindowDestroy`** — `Destroy()` method exists but
  has no decorator. All child windows and dict entries won't be cleaned.
- [ ] **Direct bound method callback** — `button.SetEvent(self.OnClick)`
  without any wrapper. Circular reference leak. (NOTE: `SAFE_SetEvent(self.OnClick)` IS valid — that wrapper auto-applies `ui.__mem_func__` internally. Verify the fork defines `SAFE_SetEvent` before flagging or accepting.)
- [ ] **Lambda capturing `self`** — `lambda ...: self.Method(...)` in
  any event setter. Same leak as direct bound method. EXCEPTION: `lambda r=proxy(self): r.Method(...)` is safe.
- [ ] **`ui.__mem_func__` inside lambda** — `lambda: ui.__mem_func__(self.X)()`
  is useless — lambda still captures `self`.
- [ ] **Dialog stored in local variable** — `dlg = uiCommon.QuestionDialog()`
  without storing on `self`. Weak refs in callbacks will die.
- [ ] **Missing `proxy(self)` in RadioButtonGroup lambda** — select
  callback uses `lambda k=key: self.Method(k)` instead of
  `lambda k=key, r=proxy(self): r.Method(k)`.

### Callback Binding Crashes (Critical)

> **Reference:** `skills/m2ui/reference/framework-augmentations.md` — when a setter does not accept `*args`, augment `ui.py` rather than degrade to a proxy lambda.

- [ ] **Pattern B applied to non-`*args` setter** — `receiver.SetX(ui.__mem_func__(self.M), arg, ...)` where the setter in `pack/pack/root/ui.py` is `def SetX(self, event):` (1-arg only). Runtime crash with `TypeError: SetX() takes exactly 2 arguments (N given)` the first time the binding executes. Fix: augment the setter in `ui.py` to accept `*args` and dispatch them at the handler (preserving native dispatch args; see `reference/framework-augmentations.md`) OR rewrite the call site as Pattern C with `proxy(self)`. Common offenders in canonical ui.py: `EditLine.SetReturnEvent`/`SetEscapeEvent`/`SetTabEvent`, `SlotWindow.SetOverInItemEvent`/`SetSelectItemSlotEvent`/`SetUnselectItemSlotEvent`/`SetPressedSlotButtonEvent`/`SetUseSlotEvent`/`SetSelectEmptySlotEvent`/`SetUnselectEmptySlotEvent`/`SetOverOutItemEvent`. Verify per-fork.

### Missing Cleanup (Critical)

- [ ] **No `Initialize()` method** — instance vars not reset on destroy.
- [ ] **Instance var not in `Initialize()`** — `self.X = ...` assigned
  in `__LoadWindow` but not listed in `Initialize()`.
- [ ] **`Destroy()` doesn't call `Initialize()`** — vars not reset.
- [ ] **Missing `ClearDictionary()`** — script-backed window (uses
  `LoadScriptFile`) but `Destroy()` doesn't call `ClearDictionary()`.
- [ ] **Missing `__del__`** — no `ui.ScriptWindow.__del__(self)` call.

### Event Handlers (Important)

- [ ] **`OnPressEscapeKey` missing return or returns `False`** — must return `True`
  (always). Missing return can cause crashes during child iteration; returning
  `False` may also cause unexpected behavior.
- [ ] **`OnMouseWheel` missing return** — must return `True` or `False`
  based on whether the handler consumed the wheel event.
- [ ] **OnUpdate without Hide before net packet** — sends network
  close packet every frame while visible if distance check triggers.

### Close() Cleanup (Important)

- [ ] **Tooltip not hidden in Close()** — `self.tooltipItem.HideToolTip()`
  missing. Tooltip stays visible after window closes.
- [ ] **EditLine focus not killed** — `self.editLine.KillFocus()` missing.
  IME input goes to hidden editline.
- [ ] **Owned dialog not destroyed** — `self.confirmDialog` not closed
  and set to `None` in `Close()`.
- [ ] **WheelTopWindow not cleared** — `wndMgr.ClearWheelTopWindow()`
  not called if `SetWheelTopWindow` was used.

### Python 2/3 Compatibility (Important)

- [ ] **`has_key()` usage** — should use `in` operator.
- [ ] **`/` for integer division** — should use `//`.
- [ ] **`map()` for side effects** — `map(func, list)` without consuming
  the result. Returns iterator in Python 3, never executes.
- [ ] **`filter()` without list conversion** — same issue.
- [ ] **`apply(func, args)`** — removed in Python 3.
- [ ] **`cmp=` in sort** — removed in Python 3, use `key=`.
- [ ] **bare `except:`** — should be `except Exception:` at minimum.

### Asset & API Hallucination (Important)

- [ ] **Image path not on disk** — any `d:/ymir work/ui/<path>` reference
  that does not exist under `D:\ymir work\ui\`. Use Glob to verify.
  Suggest replacing with `# TBD ASSET: <path> — needs creation`.
- [ ] **Unverified C++ API call** — call to `net.X`, `player.X`, `item.X`,
  `chr.X`, `app.X`, `wndMgr.X`, `chat.X`, or `quest.X` that is NOT
  documented in `skills/m2ui/reference/bindings.md`. Likely fabricated.
  Suggest stubbing with `# TODO: verify <module>.<func> exists in your fork`.

### Code Quality (Minor)

- [ ] **Hardcoded user-visible strings** — should use `localeInfo.*`
  or `uiScriptLocale.*`.
- [ ] **Shadow builtins** — variable named `list`, `type`, `dict`, etc.
- [ ] **Non-English variable names** — Spanish, Turkish, etc.
- [ ] **Missing `"not_pick"` on decorative elements** — images, bars,
  lines that shouldn't intercept clicks.
- [ ] **`SetTop()` without `"float"` flag** — `SetTop()` only works
  on windows with the `"float"` flag set.
- [ ] **Child outside parent bounds** — interactive widget positioned
  outside parent's rectangle. Won't receive mouse events.

### Uiscript Issues (Minor)

- [ ] **`/` instead of `//` in constants** — e.g., `WIDTH / 16` should
  be `WIDTH // 16` for tile count calculations.
- [ ] **Missing `"not_pick"` on border images** — 9-slice border
  elements should be `"not_pick"`.
- [ ] **Inconsistent naming** — some children use camelCase, others
  use snake_case.

## Step 3: Report

Present findings as a structured report:

```
## Diagnosis: uiMyWindow.py

### Critical (must fix)
- Line 45: `button.SetEvent(self.OnClick)` — bare bound method, no `ui.__mem_func__`/`SAFE_SetEvent`/proxy wrapper (see `skills/m2ui/reference/event-binding.md`). Memory leak.
- Line 12: No @ui.WindowDestroy decorator on Destroy(). Children won't be cleaned up.

### Important (should fix)
- Line 89: OnPressEscapeKey doesn't return True/False.
- Line 23: self.scrollBar not listed in Initialize().

### Minor (nice to fix)
- Line 67: Hardcoded string "Accept" — use localeInfo.OK.
- Line 34: Variable named `list` shadows builtin.

### Summary
- 2 critical, 2 important, 2 minor issues found.
- Most critical: memory leak from unwrapped callback at line 45.
```

## Step 4: Offer Fixes

After reporting, ask: "Want me to fix these issues?" If yes, apply
fixes following script mode's modification rules.

> **EXTREMELY-IMPORTANT — when fixing a "Missing `@ui.WindowDestroy`" finding specifically:** ADD the decorator and adapt the existing body — do NOT strip or rewrite it. If the body contains direct method calls on owned widgets (`self.X.Hide()`, `self.X.SetEvent(0)`, `self.X.ClearDictionary()`), wrap each with `if self.X:` so they no-op after WOC pre-clean. Pure assignments (`self.X = None`, `self.X = 0`) are safe. **Any helper-method call** from the body — `self.__Initialize()`, `self.Initialize()`, `self._Reset()`, `self.Init()`, or any custom name — must be inspected: safe if the helper's body only assigns simple defaults (`None`, `0`, `[]`, `{}`) with no widget derefs or method calls on owned widgets; if it derefs widgets, the same `if self.X:` guards apply inside the helper (or the risky calls relocate to `Close()`). Whitelist exception: `self.Hide()`, `self.ClearDictionary()`, `self.SetTop()` etc. need no guard (they operate on WOC-whitelisted attrs). Other findings in the same audit (missing `Initialize()`, missing `ClearDictionary()`, leaks) are independent — fix each per its own rule; this warning constrains only the decorator-add. See `reference/patterns.md` Section 5.11. Stripping the body deletes user intent and is a regression.

## Cross-reference: failure-atlas

If the user reports a SYMPTOM rather than asking for an audit ("the window flickers", "click does nothing"), do NOT run a full diagnose audit. Load `skills/m2ui/reference/failure-atlas.md` and jump to the matching symptom entry — the atlas's ranked root-cause checklist is faster than a brute-force file scan for symptom-driven cases.

Use diagnose mode when the user wants a code-quality scan (no specific symptom, "audit this file"); use failure-atlas when the user has a specific visible bug to chase.
