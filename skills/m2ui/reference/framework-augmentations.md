# Framework augmentations (modifications to ui.py)

m2ui generally writes user code (root classes, uiscripts), not framework code (`ui.py`). This file is the single exception: when an idiomatic Pattern B / Pattern E call requires a setter to accept `*args` but the canonical setter takes only `(self, event)`, m2ui augments the setter rather than degrading the call site to a proxy lambda.

## When to augment

Augment a setter in `ui.py` when ALL of:

1. The user code being generated wants to use Pattern B (`receiver.SetX(ui.__mem_func__(self.M), arg1, ...)`), and
2. The setter's current signature is `def SetX(self, event):` (1-arg only), and
3. The setter is defined in `pack/pack/root/ui.py` (Python source, not a C++ binding shim), and
4. The dispatch site (the handler that invokes the stored event) is also in Python and editable.

If condition 3 or 4 fails, fall back to **Pattern C** (proxy lambda) at the call site. Do not augment.

## Event-setter *args augmentation

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

## `__mem_func__` idempotency augmentation

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

## Cross-references

- Critical Rule 19 in `skills/m2ui/SKILL.md`
- Pre-Emit checklist item 19 in `skills/m2ui/SKILL.md`
- Slim mirror in `rules/m2ui-activate.md` (Critical Rule 19 + Pre-Emit item 17)
- Decision tree in `skills/m2ui/reference/event-binding.md`
- Pattern reference in `skills/m2ui/reference/patterns.md` Section 3 (verification-first extra-args example)
- Diagnose finding in `skills/m2ui/modes/diagnose.md` (Callback Binding Crashes section)
- Smoke test assertion in `tests/test-mode-dispatch.sh` (`EXTREMELY-IMPORTANT` block count)
