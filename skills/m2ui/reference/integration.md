# interfacemodule.py Integration Reference

Every m2ui-generated window needs an integration snippet to hook into the
client's main interface module. This file is the canonical reference for
that integration — the structural pattern every snippet follows, plus the
common variations (lazy init, feature-gated toggle, tooltip binding).

This is NOT an anchor. Anchors are window archetypes; integration is a
post-emission step that runs for every window regardless of archetype.

## When to load this file

- After completing any window generation (talk / screenshot / script mode)
- When modifying interfacemodule.py to wire a new window
- When the user reports "the window doesn't open from any keybind / button" — the wiring is missing
- When a window destroy path is suspect (window persists after game exit, or raises on teardown)

## Structural pattern (always)

Every integration snippet visits the same canonical points in
`interfacemodule.py`. Most bugs come from forgetting one. The points below
are written without a feature-gate (always-on window); the gated variant
is documented in Variation 1.

### Point 1: Import (top of interfacemodule.py)

```python
import uiMyFeature
```

If the module path involves a sub-package, import the sub-package: e.g.,
`import ui.shop` or `from ui import shop as uiShop`. Match the canonical
filename of the window root file you generated.

### Point 2: Init-time attribute nullification (in `__init__`)

```python
class Interface(object):

    def __init__(self):
        # ... unrelated init ...
        self.wndMyFeature = None
```

Initializing to `None` defensively means later read paths
(`HideAllWindows`, `__del__`, `__DestroyDialogs`) can safely test
`if self.wndMyFeature:` instead of `hasattr`.

### Point 3: Instance creation (in `MakeInterface`)

```python
def MakeInterface(self):
    # ... other window creation ...

    self.wndMyFeature = uiMyFeature.MyFeatureWindow()
```

`MakeInterface` is the canonical site for window construction. It runs
once per game session, after C++ subsystems are ready and before the
main game loop starts.

### Point 4: Tooltip binding (in `MakeInterface`, after instance creation)

If the window displays items or skills, bind the shared tooltip widgets:

```python
self.wndMyFeature.SetItemToolTip(self.tooltipItem)
# self.wndMyFeature.SetSkillToolTip(self.tooltipSkill)  # if needed
```

Skip this point for windows without item/skill content. The tooltips
themselves are owned by `interfacemodule`; binding gives the window a
ref to call `tooltipItem.SetItemSlot(...)` etc. See anchor
06-tooltip-bound for the consuming window pattern.

### Point 5: BindInterface (if window calls back into interfacemodule)

If the window needs to call interfacemodule methods (e.g., to refresh
a sibling window, dispatch a global hide), bind a back-reference:

```python
self.wndMyFeature.BindInterface(self)
```

In the window class:

```python
def BindInterface(self, interface):
    from _weakref import proxy
    self.interface = proxy(interface)
```

`proxy` (weak-ref) prevents a circular strong reference between the
interface and the window. Without it, the window keeps the interface
alive past teardown.

### Point 6: Toggle method (the public entry point)

```python
def ToggleMyFeatureWindow(self):
    if not self.wndMyFeature:
        return
    if self.wndMyFeature.IsShow():
        self.wndMyFeature.Close()
    else:
        self.wndMyFeature.Open()
```

The keybind, slash-command, or button click that opens the window
calls this method. The `if not self.wndMyFeature: return` guard handles
the rare case where `MakeInterface` was skipped.

### Point 7: Destroy in `__DestroyDialogs` (cleanup)

```python
def __DestroyDialogs(self):
    # ... other destroys ...

    if self.wndMyFeature:
        self.wndMyFeature.Destroy()
        self.wndMyFeature = None
```

Symmetric with Point 3. Without this, the window's C++ resources leak
on game exit and the next session may crash on uiscript reload.

### Point 8: Hide in `HideAllWindows`

```python
def HideAllWindows(self):
    # ... other hides ...

    if self.wndMyFeature:
        self.wndMyFeature.Close()
```

Triggered globally (entering a cutscene, opening the menu, the user
pressing the standard "hide UI" key). Without this, the window stays
visible during cutscenes and menu transitions.

### Point 9: hideWindows list (in `__HideWindows`)

```python
def __HideWindows(self):
    hideWindows = ()
    # ... other appends ...

    if self.wndMyFeature:
        hideWindows += self.wndMyFeature,

    return hideWindows
```

Some forks use a tuple-collection pattern instead of (or in addition
to) `HideAllWindows`. If the fork's `interfacemodule.py` uses
`__HideWindows`, append to the tuple here. If only `HideAllWindows`
exists, skip this point.

## Variation 1: import-guarded by `app.ENABLE_X`

When the window is feature-gated, wrap ALL FIVE leak-prone points (1, 2,
3, 7, 8) with the same `if app.ENABLE_X:` check. This is the canonical
feature-gating pattern — full treatment in anchor `05-feature-gated.md`.

```python
# Point 1
if app.ENABLE_MY_FEATURE:
    import uiMyFeature

# Point 2
if app.ENABLE_MY_FEATURE:
    self.wndMyFeature = None

# Point 3
if app.ENABLE_MY_FEATURE:
    self.wndMyFeature = uiMyFeature.MyFeatureWindow()

# Point 7
if app.ENABLE_MY_FEATURE and self.wndMyFeature:
    self.wndMyFeature.Destroy()
    self.wndMyFeature = None

# Point 8
if app.ENABLE_MY_FEATURE and self.wndMyFeature:
    self.wndMyFeature.Close()
```

The asymmetry between Points 2/3 (just the flag) and Points 7/8 (flag
AND `self.wndMyFeature`) is intentional: by the time Destroy/Hide
runs, the attribute may not exist (if creation was skipped) — `and`
short-circuits before `None.Destroy()` can raise.

For build-level flags (`__BL_*`), same pattern, double-underscore name.

## Variation 2: lazy instance creation (constructor-deferred)

Memory-conscious forks defer construction until first toggle. Point 3
moves out of `MakeInterface` and into the toggle method:

```python
def __init__(self):
    self.wndMyFeature = None  # Point 2 -- set None upfront

def MakeInterface(self):
    pass  # Point 3 -- no construction here

def ToggleMyFeatureWindow(self):
    if not self.wndMyFeature:
        # Lazy construct on first toggle
        self.wndMyFeature = uiMyFeature.MyFeatureWindow()
        if self.wndMyFeature:
            # Tooltip + BindInterface bindings happen here too,
            # since MakeInterface didn't do them
            self.wndMyFeature.SetItemToolTip(self.tooltipItem)
            self.wndMyFeature.BindInterface(self)
    if self.wndMyFeature.IsShow():
        self.wndMyFeature.Close()
    else:
        self.wndMyFeature.Open()
```

Trade-off: faster startup, slower first-open. Use only when the window
is rarely opened (e.g., admin-only debug windows). Most windows should
construct eagerly.

## Variation 3: gated-toggle (feature flag check at the toggle site)

Alternative to Variation 1. The window is constructed unconditionally;
the flag check lives only at the toggle site:

```python
# Points 1, 2, 3, 7, 8 -- no flag check
import uiMyFeature

self.wndMyFeature = None  # in __init__
self.wndMyFeature = uiMyFeature.MyFeatureWindow()  # in MakeInterface

# Toggle gates the flag instead
def ToggleMyFeatureWindow(self):
    if not app.ENABLE_MY_FEATURE:
        return
    if not self.wndMyFeature:
        return
    # ... toggle logic ...
```

Use this when the window's existence is cheap (lightweight construction)
but its activation is gated. Memory cost is the same as the always-on
case; only the user-facing entry point is gated. Less defensive than
Variation 1 — if the flag is off, the window still exists in memory.

## Variation 4: tooltip binding

Windows that consume the shared `tooltipItem` / `tooltipSkill` widgets
(typically inventory, shop, equipment, storage archetypes) must call
the binding method in `MakeInterface`:

```python
def MakeInterface(self):
    # ... tooltip widgets created earlier in MakeInterface ...
    self.tooltipItem = uitooltip.ItemToolTip()
    self.tooltipSkill = uitooltip.SkillToolTip()

    # ... window creation ...
    self.wndMyFeature = uiMyFeature.MyFeatureWindow()

    # Tooltip bindings (Point 4)
    self.wndMyFeature.SetItemToolTip(self.tooltipItem)
    # self.wndMyFeature.SetSkillToolTip(self.tooltipSkill)  # if needed
```

In the window class:

```python
def SetItemToolTip(self, tooltipItem):
    self.tooltipItem = tooltipItem
    # Pass through to slot widgets that need it
    for slot in self.itemSlots:
        slot.SetItemToolTip(tooltipItem)
```

Cross-link to anchor `06-tooltip-bound.md` for the consuming-window
pattern (how the slot wires `OnOverInItem` → `tooltipItem.SetItemSlot`).

## Variation 5: Widget reassignment (external bar replaces window sub-widgets)

When an external panel (e.g., an expanded taskbar) replaces widgets normally owned by another window (e.g., inventory's money display), the `RefreshStatus` delegation chain needs explicit wiring.

**Problem:** The original window's `RefreshStatus` may not run when the window is hidden. The replacement panel's widgets show stale values.

**Pattern:**

```python
# 1. Replacement panel has its own RefreshStatus pulling from player API:
class ExpandedBar(ui.ScriptWindow):
    def RefreshStatus(self):
        self.moneyText.SetText(localeInfo.NumberToMoneyString(player.GetElk()))
        self.chequeText.SetText(str(player.GetCheque()))

# 2. interfacemodule delegates to replacement panel's RefreshStatus:
def RefreshStatus(self):
    # ... existing refresh calls ...
    if self.wndExpandedBar:
        self.wndExpandedBar.RefreshStatus()

# 3. Widget reference reassignment — on Interface class (interfacemodule.py):
def SetExpandedBar(self, bar):
    # Runs AFTER BindInterfaceClass, so self.wndInventory exists
    self.wndInventory.wndMoney = bar.moneyWidget
    bar.btnExchange.SetEvent(
        ui.__mem_func__(self.ToggleExchangeWindow)
    )
```

**Rules:**
- Replacement panel needs its own `RefreshStatus` pulling directly from `player.GetElk()` / `player.GetCheque()` / etc.
- `interfacemodule.RefreshStatus()` must delegate to replacement panel — don't rely on the original window forwarding.
- Event wiring order matters: wire in the setter method (runs after `BindInterfaceClass`), not in `__init__` — the `interface` reference isn't available yet at init time.
- Original window's `wndMoney`/`wndCheque` references get redirected — the original widgets are no longer updated.

## Cross-references

- Window archetype anchors: `skills/m2ui/reference/anchors/README.md`
- Feature-gating augmentor: `skills/m2ui/reference/anchors/05-feature-gated.md`
- Tooltip-consuming archetype: `skills/m2ui/reference/anchors/06-tooltip-bound.md`
- Patterns reference: `skills/m2ui/reference/patterns.md` (broader pattern catalog; this file is the integration-specific subset)
- Failure atlas entry 11: feature flag check fails silently
- Failure atlas entry 15: window position not persisted across login (cleanup-timing related)
