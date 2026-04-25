# Anchor 05: Feature-Gated Window (`app.ENABLE_*`)

## What this is + when to use it

A window that should only exist (be importable, instantiable, accessible) when a feature flag is enabled. Use this for any feature that's experimental, fork-specific, or staged-rollout — the flag lives in `app.py` (C++ Python module) and gets toggled per build configuration. NOT for windows that are always present but conditionally hidden (use `Hide()` / `Show()` for runtime visibility). NOT for runtime A/B tests (a config-based check inside the window is more flexible than import-time gating).

The pattern is a CALL-SITE pattern, not a window pattern. The underlying window class itself stays unaware of the flag — the gating happens in `interfacemodule.py` at five canonical points: import, init nullification, instance creation, destroy, and HideAllWindows.

## Source

Pattern extracted from `pack/pack/root/interfacemodule.py` real fork usage, using `app.ENABLE_MOVE_CHANNEL` (gates `uimovechannel.MoveChannelWindow` from anchor 03). Also seen for `ENABLE_ACCE_COSTUME_SYSTEM`, `ENABLE_WON_EXCHANGE_WINDOW`, `ENABLE_DRAGON_SOUL_SYSTEM`, `__BL_OFFICIAL_LOOT_FILTER__`. Same five-point pattern across all of them.

The underlying window (the one being gated) is whatever anchor matches its type — for this anchor's example, anchor 03-list-selector. The window is unchanged.

Normalized to current m2ui rules:

- All five gating points present (most leak-prone bug: forgetting one of them)
- `app.ENABLE_*` checked symmetrically — if instance creation is gated, destroy MUST be gated too
- For `__BL_*` (BL = build-level) flags, same pattern, double-underscore name

## Uiscript dict

Same as the underlying window's anchor (e.g., `03-list-selector.md` → `movechanneldialog.py`). No gating-specific changes.

## Root class

Same as the underlying window's anchor (e.g., `MoveChannelWindow` in `03-list-selector.md`). The window class does NOT check the flag — gating happens at the call site in interfacemodule.

If you want the window class itself to defensively bail when the flag is off (defensive double-gate), add at the top of `Open()`:

```python
def Open(self):
    if not app.ENABLE_MOVE_CHANNEL:
        return
    # ... rest of open logic ...
```

This is OPTIONAL. The interfacemodule gates already prevent the window from existing when the flag is off, so a second check is paranoid but harmless.

## Locale entries

Standard for the window. Optionally a "feature unavailable" string if the absence is user-facing (rare — usually the menu item that opens the gated window is also gated, so users never see the missing feature).

## interfacemodule.py integration snippet

This is the heart of the anchor. ALL FIVE gating points must be present, in order:

```python
import app

# ============================================================
# Point 1 of 5: Import (top of interfacemodule.py)
# Without this, just importing interfacemodule.py raises
# ImportError when the module being imported isn't in the build.
# ============================================================
if app.ENABLE_MOVE_CHANNEL:
    import uimovechannel


class Interface(object):

    def __init__(self):
        # ... unrelated init ...

        # ====================================================
        # Point 2 of 5: Init-time attribute nullification
        # Without this, code paths that read self.wndMoveChannel
        # (e.g., HideAllWindows, __del__) raise AttributeError
        # when the flag is off. Initialize to None defensively.
        # ====================================================
        if app.ENABLE_MOVE_CHANNEL:
            self.wndMoveChannel = None

    # ====================================================
    # Point 3 of 5: Instance creation
    # The actual constructor call. Lives in MakeInterface
    # or similar — wherever the rest of the window dialogs
    # get built.
    # ====================================================
    def MakeInterface(self):
        # ... other window creation ...

        if app.ENABLE_MOVE_CHANNEL:
            self.wndMoveChannel = uimovechannel.MoveChannelWindow()

    # ====================================================
    # Toggle method (the public entry point)
    # Double-gate the toggle: flag check + None check.
    # Either could be wrong (flag off OR window not yet
    # constructed because MakeInterface hasn't run).
    # ====================================================
    def ToggleMoveChannelWindow(self):
        if not app.ENABLE_MOVE_CHANNEL:
            return
        if not self.wndMoveChannel:
            return
        if self.wndMoveChannel.IsShow():
            self.wndMoveChannel.Close()
        else:
            self.wndMoveChannel.Open()

    # ====================================================
    # Point 4 of 5: Destroy
    # Cleanup MUST be gated symmetrically with creation.
    # The `and self.wndMoveChannel` guard handles the case
    # where MakeInterface didn't run (rare but possible
    # during early teardown).
    # ====================================================
    def __DestroyDialogs(self):
        # ... other destroys ...

        if app.ENABLE_MOVE_CHANNEL and self.wndMoveChannel:
            self.wndMoveChannel.Destroy()
            self.wndMoveChannel = None

    # ====================================================
    # Point 5 of 5: HideAllWindows
    # When the user closes the inventory, opens a menu, or
    # the engine triggers a global hide (e.g., entering a
    # cutscene), every window must hide. Gate this too.
    # ====================================================
    def HideAllWindows(self):
        # ... other hides ...

        if app.ENABLE_MOVE_CHANNEL and self.wndMoveChannel:
            self.wndMoveChannel.Close()
```

For `__BL_*` flags (build-level, e.g., `app.__BL_OFFICIAL_LOOT_FILTER__`):

```python
if app.__BL_OFFICIAL_LOOT_FILTER__:
    import uilootingsystem  # at module top

if app.__BL_OFFICIAL_LOOT_FILTER__:
    self.wndLootFilter = None  # in __init__

# ... same pattern for the other 3 points ...
```

## Common variations

1. **Multiple flags (AND/OR composite)** — `if app.ENABLE_X and app.ENABLE_Y:` for AND. For OR, use `or`. The same condition must appear in ALL FIVE gating points; copy-paste exactly.
2. **Flag with default fallback** — `if getattr(app, "ENABLE_NEW_THING", False):`. Use this when the flag may not exist in older builds — `getattr` returns `False` instead of raising `AttributeError`. All five points use `getattr` consistently.
3. **Run-time toggle (not just import-time)** — for flags that the user can change at runtime (rare), check the flag in `Toggle*Window` and `Open` too, not just import. Cache the import behind the flag; rebuild the window if the flag flips ON.
4. **Different windows per flag value** — `if app.SHOP_VERSION == 2: import uishop_v2 as uishop` else `import uishop_v1 as uishop`. Now `uishop.X` works regardless of version. Five gating points still apply but with the unified `uishop.X` name.
5. **Net packet handler also gated** — if the gated window is the only consumer of a net packet, gate the `RecvX` registration in `net.py` (or wherever packets are dispatched) too. Otherwise an inactive window receives packets and either crashes (no `wndX`) or wastes work.

## Don't copy these obsolete bits

- Some forks have `from uimovechannel import *` (no flag check) — REPLACED with `if app.ENABLE_MOVE_CHANNEL: import uimovechannel`. Star imports break the gate completely (always loads).
- Some forks gate import + creation but FORGET destroy or HideAllWindows — ADD the missing point. Symptom: window stays visible on global hide, OR raises `AttributeError` on game exit when destroy paths run unconditionally.
- Some forks check ONLY the flag (not `and self.wndX`) in destroy/HideAllWindows — ADD the `and self.wndX` guard. If the flag flipped off mid-session OR `MakeInterface` was skipped, `self.wndX` may be `None` and `None.Destroy()` raises.
- Some forks initialize `self.wndX = None` UNCONDITIONALLY (no flag) in `__init__`, then guard creation with the flag — ALLOWED, slightly safer than the conditional `__init__` pattern shown above (no `AttributeError` risk if a code path forgets the gate). But pick one style and apply it consistently across all gated windows in the same file.
- Some forks call `self.wndX` without first checking `hasattr(self, "wndX")` AND without `None`-init — when the flag is off, the attribute doesn't exist; calls raise `AttributeError`. Always either gate the call sites OR initialize to `None` unconditionally with a separate `is_enabled` check.
