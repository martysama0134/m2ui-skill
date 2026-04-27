# Anchor 23: Auto-Hide Chrome (Augmentor)

## What this is + when to use it

An **augmentor** that adds inactivity-driven auto-hide behavior to any chrome-bearing archetype: taskbar, minimap, energy bar, chat, custom HUD overlays. Once the user has been idle past a threshold, the window fades alpha from 1.0 to 0.0 over a fade window. Mouse-move OR hotkey-open re-shows the window and resets the inactivity timer.

AUGMENTOR (single-source). Body content lives in section 7.

The hotkey-open path MUST reset the inactivity timer (failure-atlas entry 27 mitigation), otherwise the window opens then immediately starts fading because the existing `lastActivity` timestamp is already past the threshold.

Use this when the consumer wants a clean screen during gameplay but still wants the chrome accessible. Combine with archetypes 04-9slice-panel, 09-options-settings, or any window that should defer to gameplay focus when unused.

## Source

Single-source synthesis -- only one peer implementation found in the survey set. The observed source uses a position-shift mechanism (slides the chrome 5px per frame toward off-screen / back) gated on mouse-in-bottom-region detection. This anchor canonicalizes around alpha-fade instead, since alpha-fade generalizes to any chrome regardless of screen position and is the form documented by `timer-patterns.md` section 3 (fade-timer). The position-shift mechanism is captured as a variation. Conventions verified against engine semantics (`event-binding.md`, `widgets.md` SetAlpha, `bindings.md` `app.GetTime`, `wndMgr.GetMousePosition`) rather than peer agreement. Fork variations may differ; treat the anchor's specific shape as ONE canonical form, not THE form.

## Uiscript dict

Same as augmented archetype. Auto-hide is a behavior layered on top of the existing chrome -- no uiscript additions.

## Root class

Same as augmented archetype, with three additions:

- `self.lastActivity = 0.0` and `self.alpha = 1.0` in `__Initialize`
- An `OnUpdate(self)` body implementing the fade-timer pattern
- A `__ResetActivityTimer()` helper called from `Open`, `Toggle`, `OnMouseLeftButtonDown`, and any hotkey-open path

The body and section-7 variations are documented below.

## Locale entries

Augmentor adds two keys (used by the settings dialog that exposes the auto-hide toggle):

```
AUTO_HIDE_OPTION_TITLE        Auto-hide HUD when idle
AUTO_HIDE_OPTION_DESCRIPTION  Fades the taskbar / minimap / chat after a period of inactivity. Mouse movement or any hotkey re-shows.
```

## interfacemodule.py integration snippet

The integration is minimal -- no per-window wiring beyond the standard archetype's BindInterface. The auto-hide augmentor is self-contained inside each consuming window's `OnUpdate`. Settings dialog provides the on/off toggle:

```python
import constInfo

# In MakeInterface() or OptionsDialog setup:
constInfo.AUTO_HIDE_OPTION = True   # or read from saved settings

# In the settings dialog's checkbox callback:
def OnToggleAutoHide(self, isOn):
    constInfo.AUTO_HIDE_OPTION = bool(isOn)
    # When the user disables auto-hide, snap any currently-faded windows
    # back to alpha=1.0 so they don't stay invisible until next mouse move.
    if not isOn:
        for wnd in self.GetAutoHideWindows():
            if hasattr(wnd, "ResetAutoHide"):
                wnd.ResetAutoHide()
```

The `app.ENABLE_WINDOW_AUTO_HIDE` build-flag gate (see anchor 05-feature-gated) wraps the entire augmentor so forks without the runtime hook compile cleanly.

## Common variations

The full body for this augmentor lives here -- five canonical variations covering the most common timing profiles and integration shapes.

### Variation 1: Default (5s idle + 1s fade)

The canonical form for HUD chrome. Five seconds of pointer-idle before fade begins; one-second fade-out. Re-shows instantly on mouse move or hotkey.

```python
import app
import wndMgr
import constInfo

IDLE_THRESHOLD = 5.0
FADE_DURATION = 1.0
MIN_ALPHA = 0.0


class AutoHideMixin(object):
    """Mix into any chrome window. Provides OnUpdate fade-timer body and
    re-show hooks. Consumer initializes via __InitAutoHide() in
    __Initialize and calls __ResetActivityTimer() from any user-input
    handler."""

    def __InitAutoHide(self):
        self.lastActivity = 0.0
        self.alpha = 1.0
        self.lastMouseX = 0
        self.lastMouseY = 0

    def OnUpdate(self):
        if not app.ENABLE_WINDOW_AUTO_HIDE:
            return
        if not constInfo.AUTO_HIDE_OPTION:
            self.__SetWindowAlpha(1.0)
            return

        now = app.GetTime()

        # Detect mouse-move so any cursor activity counts as input.
        x, y = wndMgr.GetMousePosition()
        if x != self.lastMouseX or y != self.lastMouseY:
            self.lastMouseX = x
            self.lastMouseY = y
            self.__ResetActivityTimer()

        idle = now - self.lastActivity
        if idle < IDLE_THRESHOLD:
            self.__SetWindowAlpha(1.0)
            return

        fadeProgress = (idle - IDLE_THRESHOLD) / FADE_DURATION
        if fadeProgress > 1.0:
            fadeProgress = 1.0
        elif fadeProgress < 0.0:
            fadeProgress = 0.0
        self.__SetWindowAlpha(max(MIN_ALPHA, 1.0 - fadeProgress))

    def __ResetActivityTimer(self):
        self.lastActivity = app.GetTime()

    def __SetWindowAlpha(self, alpha):
        if alpha != self.alpha:
            self.alpha = alpha
            self.SetAlpha(self.alpha)

    # Public entry points -- consumer calls these from input handlers.
    def OnMouseLeftButtonDown(self):
        self.__ResetActivityTimer()
        self.__SetWindowAlpha(1.0)

    def Open(self):
        self.__ResetActivityTimer()
        self.__SetWindowAlpha(1.0)
        self.Show()

    def Toggle(self):
        self.__ResetActivityTimer()
        if self.IsShow():
            self.Close()
        else:
            self.Open()

    def ResetAutoHide(self):
        # Public hook for the settings dialog when user disables auto-hide.
        self.__ResetActivityTimer()
        self.__SetWindowAlpha(1.0)
```

### Variation 2: Fast UI (2s idle + 0.3s fade)

For UIs that want aggressive auto-hide -- e.g., a streamer-mode HUD that should disappear quickly between actions. Override the constants:

```python
IDLE_THRESHOLD = 2.0
FADE_DURATION = 0.3
```

The shorter fade can feel jarring; pair with a slight ease-in (re-use `EaseIn` from `timer-patterns.md` section 6) by replacing the linear fade with `1.0 - EaseIn(fadeProgress)`.

### Variation 3: Per-window-configurable thresholds

For windows that want their own idle / fade timing (e.g., chat fades slower than minimap), read from the settings dialog at init:

```python
class AutoHideConfig:
    def __init__(self, idleSeconds, fadeSeconds, minAlpha=0.0):
        self.idleSeconds = float(idleSeconds)
        self.fadeSeconds = float(fadeSeconds)
        self.minAlpha = float(minAlpha)

# In window __Initialize:
self.autoHideConfig = AutoHideConfig(
    idleSeconds=constInfo.AUTO_HIDE_TASKBAR_IDLE,
    fadeSeconds=constInfo.AUTO_HIDE_TASKBAR_FADE,
    minAlpha=0.2,   # never fully invisible
)
```

`MIN_ALPHA = 0.2` keeps the window dispatchable to mouse events; engines that disable mouse-routing on alpha=0 require this (see "Don't copy" note below).

### Variation 4: Hide-on-cutscene + auto-show-on-end

Treat cutscene state as "infinite idle" -- force alpha=0 while a cutscene is active, restore on cutscene end. Hook into your fork's cutscene state via a flag:

```python
def OnUpdate(self):
    if app.ENABLE_WINDOW_AUTO_HIDE:
        if constInfo.IS_CUTSCENE_ACTIVE:
            self.__SetWindowAlpha(0.0)
            return
        # ... fall through to default fade-timer body ...
```

When cutscene ends, the next frame's OnUpdate falls through, alpha snaps based on `lastActivity`. If the cutscene happens to end right at idle threshold, the window appears already faded -- mitigate by `__ResetActivityTimer()` on cutscene-end signal.

### Variation 5: Tooltip-show-during-fade

Don't fade if a tooltip is currently being shown over this window -- the tooltip is conveying intent. Gate by checking the interfacemodule's tooltip state:

```python
def OnUpdate(self):
    if app.ENABLE_WINDOW_AUTO_HIDE:
        if self.interface and self.interface.tooltipItem and self.interface.tooltipItem.IsShow():
            self.__ResetActivityTimer()
            self.__SetWindowAlpha(1.0)
            return
        # ... default body ...
```

Cross-link: `06-tooltip-bound` (the interface-owned tooltipItem accessed here).

### Position-shift variation (alternative mechanism)

The original observed source uses position-shift instead of alpha-fade: window slides 5px per frame toward off-screen until partially hidden, then slides back when the cursor enters a gutter region near the screen edge. Use this when fade looks wrong against busy backgrounds (alpha-blending makes text illegible). Trade-off: position-shift requires per-window screen-edge math (the source spelled out three windows: taskbar, energy bar, chat); alpha-fade generalizes without that.

## Don't copy these obsolete bits

- **Missing hotkey-open timer reset (failure-atlas entry 27)** -- if `Toggle()` toggles visibility but doesn't reset `lastActivity`, the OnUpdate fade-timer keeps running on the old timestamp. Window opens then immediately fades. The anchor's `Toggle` and `Open` both call `__ResetActivityTimer()`.
- **Fully transparent (alpha=0) without engine-mouse-route guarantee** -- some engines stop routing mouse events to alpha=0 windows. The mouse-move detection in `OnUpdate` then never fires and the window stays invisible forever. Either keep `MIN_ALPHA >= 0.05`, OR hook `wndMgr` global mouse-move so detection happens regardless of window alpha.
- **Per-window `lastActivity` without coordination** -- if windows A and B both auto-hide independently, mouse-over A leaves B fading. Two reasonable forks: (a) shared `interfacemodule.lastActivity` so all auto-hide windows reset together, or (b) per-window with overlap detection so hovering A near B's bounds counts as B activity.
- **`OnMouseLeftButtonDown` not resetting the timer** -- click-only counts as activity but mouse-move-only doesn't, or vice versa. The full pattern resets on BOTH.
- **`OnUpdate` running every frame even when feature flag is off** -- always check `app.ENABLE_WINDOW_AUTO_HIDE` AND `constInfo.AUTO_HIDE_OPTION` at the top of `OnUpdate`. The feature flag is build-time; the option is user-runtime.
- **Missing alpha snap on settings-toggle-off** -- when the user disables auto-hide via the settings dialog, faded windows stay faded until the next mouse move. The settings dialog's toggle handler should call `ResetAutoHide()` on every consuming window.
- **Per-frame `SetAlpha` calls** -- calling `SetAlpha(self.alpha)` every frame even when `self.alpha` hasn't changed thrashes the renderer. Guard with `if alpha != self.alpha:` (the anchor's `__SetWindowAlpha` helper).
