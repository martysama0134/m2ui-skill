# OnUpdate Timer Patterns Reference

Every Metin2 UI window has an optional `OnUpdate(self)` method called by the engine
once per frame. This file catalogs the canonical patterns for using OnUpdate. The
anchors and augmentors that reference these patterns are listed under each section.

This is NOT an anchor. Anchors are window archetypes; timer patterns are reusable
mechanics that anchors compose.

## When to load this file

- After picking an archetype that has an OnUpdate body (07, 11, 12, 21, 23)
- When generating a new window with time-based behavior (animation, polling, fade)
- When diagnosing failure-atlas entries 24, 27 (timing/animation desync)

## 1. Distance-poll

Used by: anchor 07-shop-exchange, 11-quest-npc-dialog, 12-storage-warehouse.

Pattern: poll player position every frame, close window if player moved beyond a
threshold. Threshold canonical = 1000 engine units.

```python
DISTANCE_LIMIT = 1000

def Open(self):
    (self.startX, self.startY, _) = player.GetMainCharacterPosition()
    self.SetCenterPosition()
    self.SetTop()
    self.Show()

def OnUpdate(self):
    (x, y, _) = player.GetMainCharacterPosition()
    if abs(x - self.startX) > DISTANCE_LIMIT or abs(y - self.startY) > DISTANCE_LIMIT:
        self.Close()
```

`self.startX`, `self.startY` are snapshot in `Open()` via
`player.GetMainCharacterPosition()`. Snapshot once; never re-snapshot during the
window's lifetime (otherwise the threshold drifts with the player).

When the close also requires a network packet, call `self.Hide()` BEFORE the
packet so OnUpdate stops firing on hidden windows. See `patterns.md` section
7.15 for the full network-bound variant.

Cross-link: failure-atlas entry 16 (drag stops mid-op when source slot hides) for
the related cancellation-on-distance interaction.

## 2. Animation-step

Used by: anchor 21-wheel-roulette.

Pattern: advance an animation timer by `app.GetTime()` delta per frame; transform
state based on elapsed time; transition to settle-state when animation completes.

```python
def OnUpdate(self):
    if not self.spinning:
        return
    now = app.GetTime()
    dt = now - self.lastUpdate
    self.lastUpdate = now
    self.elapsed += dt
    if self.elapsed >= self.totalDuration:
        # Settle on final segment (snap to exact target, ignore accumulated drift).
        self.rotation = self.finalRotation
        self.spinning = False
        self.OnSpinComplete()
        return
    progress = self.elapsed / self.totalDuration
    self.rotation = self.startRotation + (self.finalRotation - self.startRotation) * EaseOut(progress)
    self.wheelImage.SetRotation(self.rotation)
```

`app.GetTime()` returns seconds since client start (float). `EaseOut(t)` is the
canonical rotation easing -- see section 6 below.

The terminal `if self.elapsed >= self.totalDuration` branch snaps rotation to the
exact `self.finalRotation` and disables the timer. Don't trust accumulated `dt`
math at the settle frame; snap explicitly (failure-atlas entry 24 root cause #3).

Cross-link: failure-atlas entry 24 (wheel animation ends on wrong segment) for
server-desync mitigation.

## 3. Fade-timer (inactivity-driven)

Used by: anchor 23-auto-hide-chrome.

Pattern: track time-since-last-input; fade window alpha from 1.0 to 0.0 over a
fade window once idle threshold is exceeded; reset on any mouse-move or hotkey.

```python
IDLE_THRESHOLD = 5.0   # seconds before fade starts
FADE_DURATION = 1.0    # seconds for full alpha->0 transition

def OnUpdate(self):
    now = app.GetTime()
    idle = now - self.lastActivity
    if idle < IDLE_THRESHOLD:
        if self.alpha < 1.0:
            self.alpha = 1.0
            self.SetAlpha(self.alpha)
        return
    fadeProgress = (idle - IDLE_THRESHOLD) / FADE_DURATION
    if fadeProgress > 1.0:
        fadeProgress = 1.0
    elif fadeProgress < 0.0:
        fadeProgress = 0.0
    self.alpha = 1.0 - fadeProgress
    self.SetAlpha(self.alpha)
```

`self.lastActivity` resets on:
- `OnMouseLeftButtonDown` / `OnMouseMove` (engine-driven mouse events)
- `Open()` / `Toggle()` (hotkey path)
- Any explicit user interaction handler

Hotkey-open MUST reset `lastActivity` too, otherwise the window opens then
immediately starts fading (failure-atlas entry 27).

Cross-link: failure-atlas entry 27 (auto-hide chrome doesn't re-show on hotkey).

## 4. Check-interval

Used by: anchor 21-wheel-roulette (server-confirm polling), and any window that
polls server state at a fixed cadence.

Pattern: at a fixed interval (e.g., 1 second), call a check function; reset the
timer. Used when the server state may change without push notification.

```python
CHECK_INTERVAL = 1.0

def OnUpdate(self):
    now = app.GetTime()
    if now - self.lastCheck >= CHECK_INTERVAL:
        self.lastCheck = now
        self.CheckServerState()
```

Prefer push (Recv handler) over poll. Use poll only when the server doesn't push
or when polling cadence is naturally fixed (e.g., countdown timers).

## 5. Daily-event-timing

Used by: anchor 19-daily-reward-grid.

Pattern: window changes state at a specific in-game time-of-day. Read server time
via the engine binding; compare against a target hour. Verify the binding name
in your fork's `app` module before using.

```python
DAY_CHECK_INTERVAL_S = 60   # check once per minute, not per frame

def OnUpdate(self):
    now = app.GetTime()
    if now - self.lastDayCheck < DAY_CHECK_INTERVAL_S:
        return
    self.lastDayCheck = now
    # app.GetGlobalTime() returns server epoch (verify against fork's app module).
    server_epoch = app.GetGlobalTime()
    server_hour = (server_epoch // 3600) % 24
    if server_hour != self.lastSeenHour:
        self.lastSeenHour = server_hour
        self.OnHourTransition(server_hour)
```

NEVER compute "today" from client-local `app.GetTime()` -- player tz / DST /
client-clock skew all desync the reward grid (failure-atlas entry 23 root cause).
Use server-pushed values via Recv handlers.

Cross-link: failure-atlas entry 23 (daily-reward grid claims wrong day after midnight).

## 6. Ease-in / ease-out math

Used by: anchor 21-wheel-roulette.

Linear (no easing -- constant velocity):

```python
def Linear(t):
    return t
```

Cubic ease-out (starts fast, settles slow -- canonical wheel-spin):

```python
def EaseOut(t):
    return 1.0 - (1.0 - t) ** 3
```

Cubic ease-in (starts slow, ends fast -- rare; mostly fade-out):

```python
def EaseIn(t):
    return t ** 3
```

Cubic ease-in-out (S-curve -- symmetric):

```python
def EaseInOut(t):
    if t < 0.5:
        return 4.0 * t * t * t
    p = 2.0 * t - 2.0
    return 1.0 + p * p * p / 2.0
```

`t` is the normalized progress in `[0.0, 1.0]`. Output is also `[0.0, 1.0]`. The
caller maps the output to the actual transform (rotation, position, alpha).

## 7. Wheel-segment rotation math

Used by: anchor 21-wheel-roulette.

Given N segments, server-pushed final segment index `finalIdx`, and a desired
total spin count `spinCount` (e.g., 5 full rotations before settling):

```python
def ComputeFinalRotation(finalIdx, totalSegments, spinCount=5):
    SEGMENT_DEGREES = 360.0 / totalSegments
    # Center of the final segment.
    targetDegrees = finalIdx * SEGMENT_DEGREES + SEGMENT_DEGREES / 2.0
    # Add full rotations so the spin animation has visible cycles.
    return spinCount * 360.0 + targetDegrees
```

The `finalIdx` MUST come from the server's `RecvSpinResult` payload. Client-side
random selection desyncs visual segment vs awarded reward (failure-atlas entry
24). Both client and server must agree on `spinCount` -- payload it explicitly
or hardcode the same constant on both sides.

## Cross-references

- `patterns.md` section 7.15 (close-on-distance) -- the original pattern; this
  file generalizes the OnUpdate idiom to other timer-driven mechanics.
- `failure-atlas.md` entries 24, 27 -- timer-related symptoms.
- `bindings.md` `app` module -- verify `app.GetTime`, `app.GetGlobalTime` exist
  in your fork before using.
