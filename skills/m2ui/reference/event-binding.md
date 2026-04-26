# Event Binding — The Single Source of Truth

Every callback that references `self` MUST go through one of the safe patterns below. Bare bound methods and self-capturing lambdas leak.

## The matrix

| Pattern | Safe? | When to use |
|---------|-------|-------------|
| `btn.SetEvent(ui.__mem_func__(self.OnClick))` | yes | Default for self-referencing callbacks |
| `btn.SAFE_SetEvent(self.OnClick)` | yes (only if fork defines it) | Shorter; auto-wraps via `ui.__mem_func__` internally |
| `btn.SetEvent(self.OnClick)` | **NO** | Bare bound method — strong cycle, leak |
| `btn.SetEvent(lambda: self.OnClick())` | **NO** | Lambda captures `self` — same leak |
| `btn.SetEvent(lambda: ui.__mem_func__(self.OnClick)())` | **NO** | Useless — lambda still captures `self` |
| `btn.SetEvent(lambda r=proxy(self): r.OnClick())` | yes (rare) | Only when `ui.__mem_func__` cannot be used; needs `from _weakref import proxy` |
| `btn.SetEvent(SomeFreeFunction)` | yes | No `self` ref → no leak risk |
| `btn.SetEvent(lambda arg=i: standaloneFunc(arg))` | yes | Lambda without `self` is fine |

## Decision flow

```
Need a callback for an event setter?
  │
  ├─ Does the callback reference self?
  │     │
  │     ├─ NO → Pass it directly. Done.
  │     │
  │     └─ YES → Need to wrap. Choose one:
  │             │
  │             ├─ Does the fork define SAFE_SetEvent? (grep `def SAFE_SetEvent` in pack root)
  │             │     │
  │             │     ├─ YES → Prefer btn.SAFE_SetEvent(self.OnClick)
  │             │     └─ NO  → Use btn.SetEvent(ui.__mem_func__(self.OnClick))
  │             │
  │             └─ Does the API forbid both? (e.g., callback signature reshaping)
  │                   └─ Use lambda r=proxy(self): r.OnClick()  (last resort)
  │
  └─ Need to pass extra args to the callback?
        │
        ├─ STEP 1: Read pack/pack/root/ui.py and find the receiver's setter.
        │           Does it accept *args? (e.g., `def SetX(self, event, *args):`)
        │             │
        │             ├─ YES → Use the setter's extra-args feature:
        │             │         btn.SetEvent(ui.__mem_func__(self.OnSelect), idx)
        │             │
        │             └─ NO  → The setter is 1-arg only. Pick:
        │                       │
        │                       ├─ AUGMENT ui.py (preferred)
        │                       │   See reference/framework-augmentations.md
        │                       │   Then use Pattern B normally:
        │                       │     editline.SetTabEvent(ui.__mem_func__(self.X), arg)
        │                       │
        │                       └─ Pattern C fallback (when augmentation impossible)
        │                           editline.SetTabEvent(lambda a=arg, r=proxy(self): r.X(a))
        │
        └─ Common 1-arg offenders (verify per-fork):
              EditLine.SetReturnEvent / SetEscapeEvent / SetTabEvent
              SlotWindow.SetOverInItemEvent / SetSelectItemSlotEvent /
                         SetPressedSlotButtonEvent / etc.
```

## Why bare bound methods leak

`button.SetEvent(self.OnClick)` stores a bound method on the button. The bound method holds a strong reference to `self`. The window holds a strong reference to the button. When the window closes, the cycle prevents garbage collection.

`ui.__mem_func__()` wraps both `im_self` and `im_func` with `weakref.proxy()`, breaking the cycle.

## Why self-capturing lambdas leak

`button.SetEvent(lambda: self.OnClick())` creates a lambda whose closure captures `self`. The button holds the lambda; the lambda holds `self`. Same cycle, same leak.

This is true even if you write `lambda: ui.__mem_func__(self.OnClick)()` — the `__mem_func__` wrap is constructed each call, but the lambda itself still holds `self` strongly.

## Fork compatibility check

Before recommending `SAFE_SetEvent`, verify the fork provides it:

```bash
grep -r "def SAFE_SetEvent" path/to/pack/root/ui.py path/to/pack/root/uiscript*.py
```

Vanilla Metin2 does NOT define `SAFE_SetEvent`. If absent, fall back to `ui.__mem_func__()` always.

## Cross-references

- Anti-pattern detector: `modes/diagnose.md`
- Full codebase examples: `skills/m2ui/reference/patterns.md` Section 3 (now points back to this file)
- Pre-emit checklist item #3: `SKILL.md` Pre-Emit section
