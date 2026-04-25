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
        └─ Use the event setter's extra-args feature (NOT a lambda):
              btn.SetEvent(ui.__mem_func__(self.OnSelect), idx)
              slot.SetOverInItemEvent(ui.__mem_func__(self.OnOverIn), 0, row)
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
