# Framework augmentations (modifications to ui.py / uiCommon.py)

m2ui generally writes user code (root classes, uiscripts), not framework code. This file documents the exceptions: augmentations to `ui.py` and `uiCommon.py` that m2ui-generated code may depend on. When generated code calls a method that requires an augmentation, m2ui must emit the augmentation alongside the user code or warn that it is missing.

## ui.py augmentations

### When to augment ui.py

Augment a setter in `ui.py` when ALL of:

1. The user code being generated wants to use Pattern B (`receiver.SetX(ui.__mem_func__(self.M), arg1, ...)`), and
2. The setter's current signature is `def SetX(self, event):` (1-arg only), and
3. The setter is defined in `pack/pack/root/ui.py` (Python source, not a C++ binding shim), and
4. The dispatch site (the handler that invokes the stored event) is also in Python and editable.

If condition 3 or 4 fails, fall back to **Pattern C** (proxy lambda) at the call site. Do not augment.

### Event-setter *args augmentation

Three pieces change in `ui.py`:

### Piece 1 — initialize the args attr in `__init__`

Locate the class's `__init__` (or `Initialize` if used) and add a default for the args attribute alongside the existing event attribute:

```python
# Before
def __init__(self):
    ...
    self.eventTab = None

# After
def __init__(self):
    ...
    self.eventTab = None
    self.eventTabArgs = ()
```

### Piece 2 — accept `*args` in the setter and store

```python
# Before
def SetTabEvent(self, event):
    self.eventTab = event

# After
def SetTabEvent(self, event, *args):
    self.eventTab = event
    self.eventTabArgs = args
```

### Piece 3 — dispatch with the stored args at the handler

**Critical: preserve any native args the dispatch site already passes; append the stored `*args` at the END.** Different setters dispatch with different native shapes:

| Setter | Native dispatch shape | Augmented dispatch |
|---|---|---|
| `EditLine.SetTabEvent` | `self.eventTab()` (no native args) | `self.eventTab(*self.eventTabArgs)` |
| `EditLine.SetReturnEvent` | `self.eventReturn()` | `self.eventReturn(*self.eventReturnArgs)` |
| `SlotWindow.SetSelectItemSlotEvent` | `self.eventSelectItemSlot(slotNumber)` | `self.eventSelectItemSlot(slotNumber, *self.eventSelectItemSlotArgs)` |
| `SlotWindow.SetOverInItemEvent` | `self.eventOverInItem(slotNumber)` | `self.eventOverInItem(slotNumber, *self.eventOverInItemArgs)` |
| `SlotWindow.SetPressedSlotButtonEvent` | `self.eventPressedSlotButton(slotNumber)` | `self.eventPressedSlotButton(slotNumber, *self.eventPressedSlotButtonArgs)` |
| `SlotWindow.SetOverOutItemEvent` | `self.eventOverOutItem()` (no native args) | `self.eventOverOutItem(*self.eventOverOutItemArgs)` |

**Always grep the dispatch site first and read its existing call shape.** Stripping native args (e.g., turning `self.eventSelectItemSlot(slotNumber)` into `self.eventSelectItemSlot(*args)`) breaks every existing caller that was relying on receiving `slotNumber`.

If the dispatch site might run before `__init__` set the args attribute (defensive path: subclass that skips parent init, etc.), use `getattr` instead:

```python
# EditLine pattern (no native args)
self.eventTab(*getattr(self, 'eventTabArgs', ()))

# SlotWindow pattern (native args preserved)
self.eventSelectItemSlot(slotNumber, *getattr(self, 'eventSelectItemSlotArgs', ()))
```

## Augmentation-safety checklist

Before committing the augmentation, verify:

1. **Backwards compatible** — existing callers `obj.SetTabEvent(callback)` still work because `*args` collects to an empty tuple.
2. **All init paths set the args attr** — every `__init__` and every `Initialize`/`__Initialize` that resets the event attribute also resets the args attribute. (Use `getattr` in dispatch as a safety net.)
3. **All references to the stored event attr found** — grep the file for `self.eventXxx` (the bare attribute name, no parenthesis) to find every place the event is read. Common dispatch forms include `self.eventXxx(args)`, `apply(self.eventXxx, args)` (Py2-only), aliases (`fn = self.eventXxx; fn()`), and conditional guards (`if self.eventXxx: ...`). Each invocation site must preserve its native call shape and APPEND the stored `*self.eventXxxArgs`. Each guard / alias must remain untouched. A miss leaves the augmentation half-applied and produces inconsistent runtime behavior.
4. **No subclass overrides the setter** — if a subclass overrides `SetTabEvent` to do something fork-specific, that override needs the same `*args` extension.
5. **No SAFE_ variant out of step** — if `SAFE_SetTabEvent` exists alongside `SetTabEvent`, augment both for parity, OR explicitly note that SAFE_ does not accept extra args.

## Setters known to lack `*args` in canonical ui.py

These are common offenders in vanilla / ymir-derived `ui.py`. m2ui must STILL verify by reading the target project's actual file (forks vary).

- `EditLine.SetReturnEvent` / `SetEscapeEvent` / `SetTabEvent`
- `SlotWindow.SetSelectEmptySlotEvent` / `SetSelectItemSlotEvent` / `SetUnselectEmptySlotEvent` / `SetUnselectItemSlotEvent` / `SetUseSlotEvent` / `SetOverInItemEvent` / `SetOverOutItemEvent` / `SetPressedSlotButtonEvent`

## When to fall back to Pattern C instead

- Setter lives in a `wndMgr` / native binding (C++), not Python.
- Dispatch site has a fork-specific transform on the stored event that breaks under `*args` (rare; investigate before deciding).
- The user explicitly asked NOT to modify `ui.py`.

In any of those cases:

```python
# Pattern C fallback
from _weakref import proxy
receiver.SetX(lambda a=arg1, b=arg2, r=proxy(self): r.M(a, b))
```

### `__mem_func__` idempotency augmentation

A second framework augmentation that pairs naturally with this rule: make `ui.__mem_func__` idempotent so double-wrap is safe.

### Why

A common foot-gun in m2-style fork code: a "passthrough" setter forwards an event to an inner setter without transformation:

```python
def SetCloseEvent(self, event):
    self.eventClose = event
    self.btnClose.SetEvent(event)   # forwards as-is
```

The contract is "caller pre-wraps". When a caller does:

```python
helpwnd.SetCloseEvent(ui.__mem_func__(self.OnClose))  # already wrapped
```

things work. But when a well-meaning edit (or m2ui auto-wrap) turns the passthrough into:

```python
def SetCloseEvent(self, event):
    self.eventClose = event
    self.btnClose.SetEvent(ui.__mem_func__(event))   # double-wrap
```

the call site crashes at runtime:

```
AttributeError: __mem_func__ instance has no attribute 'im_func'
```

because `__mem_func__.__init__` reads `mfunc.im_func.func_code.co_argcount` — that attribute lookup is for **bound methods**, and an already-wrapped `__mem_func__` instance does not have it.

### Augmentation

Single early-return at the top of `__mem_func__.__init__`:

```python
class __mem_func__:
    ...
    def __init__(self, mfunc):
        # Idempotent: if mfunc is already a __mem_func__ instance, reuse its
        # stored call dispatcher. Prevents AttributeError ("__mem_func__
        # instance has no attribute 'im_func'") when a passthrough setter
        # wraps an already-wrapped callable.
        if isinstance(mfunc, __mem_func__):
            self.call = mfunc.call
            return
        if mfunc.im_func.func_code.co_argcount > 1:
            self.call = __mem_func__.__arg_call__(mfunc.im_class, mfunc.im_self, mfunc.im_func)
        else:
            self.call = __mem_func__.__noarg_call__(mfunc.im_class, mfunc.im_self, mfunc.im_func)
```

That is the entire patch. Three lines added before the existing branch.

### Effect

After applying:

- `ui.__mem_func__(bound_method)` — works as before (existing arity-aware path).
- `ui.__mem_func__(ui.__mem_func__(bound_method))` — works (early-return reuses inner `.call`).
- `ui.__mem_func__(ui.__mem_func__(ui.__mem_func__(bm)))` — also works (each layer reuses).

The `__call__` dispatcher (`self.call(*arg)`) is unchanged. Any existing weakref proxy semantics preserved exactly.

### When to apply this augmentation

Apply it once, alongside Critical Rule 19's setter augmentations, on any `ui.py` you also touch. It pairs with — and supersedes — manual policing of "passthrough vs auto-wrap" call sites: with idempotent `__mem_func__`, both shapes are safe.

### When NOT to apply

- The fork's `__mem_func__` already has equivalent idempotency (grep for `isinstance(mfunc, __mem_func__)` first).
- The user explicitly wants double-wrap to error (debugging scenario).

### Companion rule for emission

Even with idempotent `__mem_func__`, m2ui's emission preference is still:

1. **Passthrough setter (`def SetX(self, event): self.inner.SetEvent(event)`)** — leave as passthrough; add a caller-contract comment (`# Caller must pre-wrap with ui.__mem_func__`). Do NOT auto-wrap inside the method body — the contract is clearer that way.
2. **Auto-wrap setter (`def SetX(self, event): self.inner.SetEvent(ui.__mem_func__(event))`)** — only when the existing setter is already an auto-wrap by design (e.g., `SAFE_SetEvent`).

Idempotency is a safety net, not a license to be sloppy.

---

## uiCommon.py augmentations

### `QuestionDialog2.SetText()` — convenience split-and-delegate

#### Why

`QuestionDialog2` exposes `SetText1()` / `SetText2()` for its two text lines. When a single locale string contains `\n`, callers must manually split and guard:

```python
fullText = localeInfo.GEM_SYSTEM_ADD_SLOT % (itemName, itemCount)
lines = fullText.split("\n")
questionDialog.SetText1(lines[0] if len(lines) > 0 else "")
questionDialog.SetText2(lines[1] if len(lines) > 1 else "")
```

This boilerplate repeats at every call site using single-key locale strings.

#### Augmentation

Add to class `QuestionDialog2` in `uiCommon.py`:

```python
def SetText(self, text):
    if text is None:
        text = ""
    lines = text.split("\n")
    self.SetText1(lines[0] if len(lines) > 0 else "")
    self.SetText2(lines[1] if len(lines) > 1 else "")
```

Key design decisions:
- Delegates through `SetText1()` / `SetText2()`, NOT `self.textLine1.SetText()` / `self.textLine2.SetText()` directly — preserves fork overrides of the per-line setters.
- `None` guard for safety.
- Max 2 lines consumed; extra lines silently ignored (appropriate for a 2-line dialog).
- `QuestionDialogWithTimeLimit` inherits via subclass — no additional work needed.

#### Detection

**Do not grep for just `def SetText`** — stock `QuestionDialog2` inherits `QuestionDialog.SetText()` which targets `self.textLine` (single text widget, wrong method). That inherited method does NOT split on `\n`. Detection must verify `SetText` is defined directly on `QuestionDialog2` class, not merely inherited.

Check: grep for `def SetText` within the `class QuestionDialog2` block in the target project's `uiCommon.py`. If absent, the augmentation is needed.

#### When to emit

When m2ui generates code that calls `QuestionDialog2.SetText()`, verify the target project has the method on `QuestionDialog2` itself (not inherited from `QuestionDialog`). If missing, either:
1. Emit the augmentation alongside the user code, or
2. Fall back to `SetText1()` / `SetText2()` with manual split at the call site.

#### Backwards compatibility

- `SetText1()` / `SetText2()` remain unchanged and available for separate locale keys or conditional per-line assignment.
- No existing callers break — `SetText()` is purely additive.

---

## AniImageBox frame event augmentation (C++ + ui.py)

### What it adds

Three capabilities to `AniImageBox`:

| Feature | What | Depends on |
|---------|------|------------|
| `SetEndFrameEvent(event)` | Python callback when animation cycle completes | C++ `OnEndFrame` (already exists) |
| `SetKeyFrameEvent(event)` | Python callback every frame tick with `(cur_frame)` arg | **New** C++ `OnKeyFrame` call |
| `ResetFrame()` Python wrapper | Reset animation to frame 0 from Python | C++ `ResetFrame` (already exists, needs wndMgr binding) |

### Guard symbol

`__BL_ON_END_KEY_FRAME__` — C++ `#if defined(...)`, Python `if app.__BL_ON_END_KEY_FRAME__:`.

### Prerequisites — verify before applying

```
# C++ must have these:
grep "OnEndFrame" EterPythonLib/PythonWindow.cpp      # PyCallClassMemberFunc line
grep "ResetFrame" EterPythonLib/PythonWindow.cpp       # m_bycurIndex = 0
grep "m_bycurIndex" EterPythonLib/PythonWindow.h       # BYTE member

# Python must have:
grep "class AniImageBox" pack/pack/root/ui.py          # with OnEndFrame stub
```

If `OnEndFrame` in C++ does NOT call `PyCallClassMemberFunc`, this augmentation
cannot work — the C++→Python callback bridge is missing entirely.

### Detection

```
# Already applied?
grep "__BL_ON_END_KEY_FRAME__" Locale_inc.h              # C++ define
grep "__BL_ON_END_KEY_FRAME__" PythonApplicationModule.cpp # Python constant
grep "SetKeyFrameEvent" pack/pack/root/ui.py              # Python setter
```

---

### Piece 0 — Define guard + Python constant

**File:** `UserInterface/Locale_inc.h`

```cpp
#define __BL_ON_END_KEY_FRAME__
```

**File:** `UserInterface/PythonApplicationModule.cpp` (near other `__BL_` constants)

```cpp
#if defined(__BL_ON_END_KEY_FRAME__)
    PyModule_AddIntConstant(poModule, "__BL_ON_END_KEY_FRAME__",	1);
#else
    PyModule_AddIntConstant(poModule, "__BL_ON_END_KEY_FRAME__",	0);
#endif
```

### Piece 1 — C++ header: add `OnKeyFrame` declaration

**File:** `EterPythonLib/PythonWindow.h`, inside `class CAniImageBox`

```cpp
        virtual void OnEndFrame();
#if defined(__BL_ON_END_KEY_FRAME__)
        void OnKeyFrame();
#endif
```

No new member variables needed — `m_bycurIndex` already exists.

### Piece 2 — C++ implementation: add `OnKeyFrame` and call from `OnUpdate`

**File:** `EterPythonLib/PythonWindow.cpp`

Add the new method right after `OnEndFrame`:

```cpp
#if defined(__BL_ON_END_KEY_FRAME__)
void CAniImageBox::OnKeyFrame()
{
    PyCallClassMemberFunc(m_poHandler, "OnKeyFrame", Py_BuildValue("(i)", m_bycurIndex));
}
#endif
```

In `OnUpdate`, add call after the frame-advance block:

```cpp
    ++m_bycurIndex;
    if (m_bycurIndex >= m_ImageVector.size())
    {
        m_bycurIndex = 0;
        OnEndFrame();
    }

#if defined(__BL_ON_END_KEY_FRAME__)
    OnKeyFrame();
#endif
}
```

**Order matters:** `OnKeyFrame` fires AFTER the index advances and AFTER a
potential `OnEndFrame` reset. Frame 0 fires on both cycle-wrap and first frame.

### Piece 3 — C++ wndMgr binding: expose `ResetFrame` to Python

**File:** `EterPythonLib/PythonWindowManagerModule.cpp`

Add the binding function (near the other AniImageBox bindings):

```cpp
PyObject * wndImageResetFrame(PyObject * poSelf, PyObject * poArgs)
{
    UI::CWindow * pWindow;
    if (!PyTuple_GetWindow(poArgs, 0, &pWindow))
        return Py_BuildException();

    ((UI::CAniImageBox*)pWindow)->ResetFrame();

    return Py_BuildNone();
}
```

Add to the method table (after `AppendImage`):

```cpp
// AniImageBox
{ "SetDelay",                  wndImageSetDelay,                  METH_VARARGS },
{ "AppendImage",               wndImageAppendImage,               METH_VARARGS },
{ "ResetFrame",                wndImageResetFrame,                METH_VARARGS },
```

**Note:** `ResetFrame` binding is NOT guarded — the C++ method exists
unconditionally. Only `OnKeyFrame` needs the guard.

### Piece 4 — Python ui.py: gated event setters

**File:** `pack/pack/root/ui.py`, `class AniImageBox`

```python
class AniImageBox(Window):
    def __init__(self, layer = "UI"):
        Window.__init__(self, layer)
        if app.__BL_ON_END_KEY_FRAME__:
            self.end_frame_event = None
            self.key_frame_event = None

    def __del__(self):
        Window.__del__(self)
        if app.__BL_ON_END_KEY_FRAME__:
            self.end_frame_event = None
            self.key_frame_event = None

    def RegisterWindow(self, layer):
        self.hWnd = wndMgr.RegisterAniImageBox(self, layer)

    def SetDelay(self, delay):
        wndMgr.SetDelay(self.hWnd, delay)

    def AppendImage(self, filename):
        wndMgr.AppendImage(self.hWnd, filename)

    def ResetFrame(self):
        wndMgr.ResetFrame(self.hWnd)

    def SetPercentage(self, curValue, maxValue):
        wndMgr.SetRenderingRect(self.hWnd, 0.0, 0.0, -1.0 + float(curValue) / float(maxValue), 0.0)

    if app.__BL_ON_END_KEY_FRAME__:
        def OnEndFrame(self):
            if self.end_frame_event:
                self.end_frame_event()

        def SetEndFrameEvent(self, event):
            self.end_frame_event = event

        def OnKeyFrame(self, cur_frame):
            if self.key_frame_event:
                self.key_frame_event(cur_frame)

        def SetKeyFrameEvent(self, event):
            self.key_frame_event = event
    else:
        def OnEndFrame(self):
            pass
```

### Verification checklist

1. **C++ compiles** — `OnKeyFrame` declared in header, implemented in .cpp, no
   new includes needed (`Py_BuildValue` already available).
2. **ResetFrame binding registered** — grep method table for `"ResetFrame"`.
3. **OnEndFrame backwards compatible** — if no event set, `self.end_frame_event`
   is `None`, the `if` guard skips the call. Old code with `OnEndFrame` overrides
   in subclasses still works because `end_frame_event` defaults to `None`.
4. **OnKeyFrame absent = no-op** — if Python class has no `OnKeyFrame` method,
   `PyCallClassMemberFunc` silently fails (standard engine behavior for
   missing handler methods). Once the ui.py augmentation is applied, the method
   exists and delegates to the stored event or no-ops if `None`.
5. **Memory safety** — event attrs stored as `None` or `__mem_func__` wrapped.
   Cleaned up in `__del__`. Matches `MoveImageBox.SetEndMoveEvent` pattern.
6. **Frame index type** — `m_bycurIndex` is `BYTE` (0-255). Passed to Python as
   `int` via `Py_BuildValue("(i)", ...)`. Safe for up to 255-frame animations.

### When to apply

Apply when generated code uses `SetEndFrameEvent`, `SetKeyFrameEvent`, or
`ResetFrame()` on an `AniImageBox` — any of the patterns in
`timer-patterns.md` sections 8 and 9.

### When NOT to apply

- Fork already has these features (grep for `SetKeyFrameEvent` in ui.py).
- C++ `OnEndFrame` does not call `PyCallClassMemberFunc` — the callback
  bridge is missing; this augmentation alone cannot fix that.
- Animation has > 255 frames — `m_bycurIndex` is `BYTE`, will wrap. Rare
  in practice (most Metin2 animations are 4-12 frames).

### Performance note

`OnKeyFrame` calls `PyCallClassMemberFunc` every frame advance. For a
6-frame animation at delay 6, that is ~28 Python calls/second. Negligible
for 1-3 animated widgets; avoid setting `SetKeyFrameEvent` on > 10
simultaneously animating widgets. If only `SetEndFrameEvent` is needed,
skip `SetKeyFrameEvent` — `OnKeyFrame` still fires in C++ but the Python
`if self.key_frame_event:` guard exits immediately.

---

## Cross-references

- Critical Rule 19 in `skills/m2ui/SKILL.md`
- Pre-Emit checklist item 19 in `skills/m2ui/SKILL.md`
- Slim mirror in `rules/m2ui-activate.md` (Critical Rule 19 + Pre-Emit item 17)
- Decision tree in `skills/m2ui/reference/event-binding.md`
- Pattern reference in `skills/m2ui/reference/patterns.md` Section 3 (verification-first extra-args example)
- Diagnose finding in `skills/m2ui/modes/diagnose.md` (Callback Binding Crashes section)
- Smoke test assertion in `tests/test-mode-dispatch.sh` (`EXTREMELY-IMPORTANT` block count)
- Timer patterns in `reference/timer-patterns.md` sections 8-9 (deque queue + layered effects use these events)
