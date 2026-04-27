# Anchor 21: Wheel / Roulette / Gacha

## What this is + when to use it

A primary archetype for **time-based wheel-spinning windows**. Window shows a circular wheel widget (image + rotation transform) + Spin button + result preview slot + cost text. One-shot lifecycle: window opens, user pays the cost (Yang / cheque / free-spin token), Spin button sends a packet, server picks the result and pushes back the final segment index, the client animates the wheel to the matching segment via ease-out rotation, the result is revealed in the result slot, and the user dismisses with the Close button (Close is blocked during the spin to protect the server-committed result).

Use this archetype for: gacha box, soul-roulette, lucky-spin, wheel-of-destiny, daily-spin, prize-wheel. Subsumes the mini-game overlay archetype (one-shot Show -> spin -> close lifecycle).

Distinct from `13-craft-refine-window` (synchronous yes/no commit) by virtue of the **time-based animation inside `OnUpdate`** plus the **one-shot lifecycle** (window is dismissed after a single result, not reused). Distinct from `19-daily-reward-grid` (the player picks from a fixed grid; the wheel picks for the player from a server-driven random index).

Layer `15-network-coupled-flow` for the SendSpin -> RecvResult contract. Cross-link `timer-patterns.md` sections 2 (animation-step), 6 (ease-out math), 7 (wheel-segment rotation math).

## Source

Patterns synthesized from 3 peer implementations of wheel / roulette systems in real Metin2 forks. All three observed sources tie the final segment to a server-pushed index (good); the variations across sources are in animation style (continuous rotation via `SetRotation` vs discrete step via `EdgeEffect` shifting an indicator one slot per tick) and in the easing curve. The anchor uses the continuous-rotation shape with `EaseOut` per `timer-patterns.md`, since this is the more visually canonical wheel feel and the math generalizes to any segment count. One source uses framerate-dependent decrement (`Langsamer -= 0.1` per frame) which couples animation duration to client framerate -- the anchor uses elapsed-time math (`app.GetTime()` deltas) instead so animation duration is consistent across hardware.

## Uiscript dict

`pack/pack/uiscript/uiscript/wheelroulette.py`:

```python
window = {
    "name" : "WheelRouletteWindow",
    "x" : 0,
    "y" : 0,
    "style" : ("movable", "float",),

    "width" : 480,
    "height" : 540,

    "children" :
    (
        {
            "name" : "board",
            "type" : "board_with_titlebar",
            "x" : 0,
            "y" : 0,
            "width" : 480,
            "height" : 540,
            "title" : uiScriptLocale.WHEEL_TITLE,

            "children" :
            (
                # ----- Wheel widget -----
                {
                    "name" : "wheel_image",
                    "type" : "expanded_image",
                    "x" : 80,
                    "y" : 60,
                    # TBD ASSET: d:/ymir work/ui/game/wheel/wheel_disk.tga -- needs creation
                    "image" : "d:/ymir work/ui/game/wheel/wheel_disk.tga",
                    "not_pick" : 1,
                },
                {
                    "name" : "wheel_indicator",
                    "type" : "expanded_image",
                    "x" : 220,
                    "y" : 50,
                    # TBD ASSET: d:/ymir work/ui/game/wheel/wheel_indicator.tga -- needs creation
                    "image" : "d:/ymir work/ui/game/wheel/wheel_indicator.tga",
                    "not_pick" : 1,
                },

                # ----- Result preview -----
                {
                    "name" : "result_thinboard",
                    "type" : "thinboard",
                    "x" : 174,
                    "y" : 400,
                    "width" : 132,
                    "height" : 56,
                },
                {
                    "name" : "result_slot",
                    "type" : "slot",
                    "x" : 224,
                    "y" : 412,
                    "width" : 32,
                    "height" : 32,
                    "slot" : ((0, 0, 0, 1, 1),),
                },

                # ----- Cost text -----
                {
                    "name" : "cost_label",
                    "type" : "text",
                    "x" : 18,
                    "y" : 470,
                    "text" : uiScriptLocale.WHEEL_COST_LABEL,
                    "not_pick" : 1,
                },
                {
                    "name" : "cost_text",
                    "type" : "text",
                    "x" : 110,
                    "y" : 470,
                    "text" : "",
                    "not_pick" : 1,
                },

                # ----- Spin / Close buttons -----
                {
                    "name" : "spin_button",
                    "type" : "button",
                    "x" : 280,
                    "y" : 466,
                    "text" : uiScriptLocale.WHEEL_SPIN_BUTTON,
                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },
                {
                    "name" : "close_button",
                    "type" : "button",
                    "x" : 380,
                    "y" : 466,
                    "text" : uiScriptLocale.WHEEL_CLOSE_BUTTON,
                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },
            ),
        },
    ),
}
```

## Root class

`pack/pack/root/uiwheelroulette.py`:

```python
import ui
import net
import app
import item
import chat
import localeInfo
import uiScriptLocale
import constInfo

# Wheel geometry
TOTAL_SEGMENTS = 8
SPIN_DURATION_SECONDS = 5.0
DEFAULT_SPIN_COUNT = 5     # full rotations before settling


def EaseOut(t):
    return 1.0 - (1.0 - t) ** 3


def ComputeFinalRotation(finalIdx, totalSegments, spinCount):
    # Center of the final segment plus N full rotations for visible spin.
    SEGMENT_DEGREES = 360.0 / totalSegments
    targetDegrees = finalIdx * SEGMENT_DEGREES + SEGMENT_DEGREES / 2.0
    return spinCount * 360.0 + targetDegrees


class WheelRouletteWindow(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.__Initialize()
        self.__LoadWindow()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def __Initialize(self):
        # Chrome
        self.wheelImage = None
        self.wheelIndicator = None
        self.resultBoard = None
        self.resultSlot = None
        self.costText = None
        self.spinButton = None
        self.closeButton = None

        # Animation state
        self.spinning = False
        self.elapsed = 0.0
        self.totalDuration = SPIN_DURATION_SECONDS
        self.lastUpdate = 0.0
        self.startRotation = 0.0
        self.finalRotation = 0.0
        self.rotation = 0.0

        # Result state (server-pushed)
        self.finalSegmentIdx = -1
        self.rewardVnum = 0
        self.rewardCount = 0

        # Session state
        self.cost = 0
        self.isFreeSpin = False
        self.isPending = False
        self.tooltipItem = None

    def __LoadWindow(self):
        try:
            self.LoadScriptFile("uiscript/wheelroulette.py")
        except:
            import exception
            exception.Abort("WheelRouletteWindow.__LoadWindow.LoadScriptFile")

        try:
            self.wheelImage = self.GetChild("wheel_image")
            self.wheelIndicator = self.GetChild("wheel_indicator")
            self.resultBoard = self.GetChild("result_thinboard")
            self.resultSlot = self.GetChild("result_slot")
            self.costText = self.GetChild("cost_text")
            self.spinButton = self.GetChild("spin_button")
            self.closeButton = self.GetChild("close_button")
        except:
            import exception
            exception.Abort("WheelRouletteWindow.__LoadWindow.BindObject")

        self.spinButton.SetEvent(ui.__mem_func__(self.OnSpin))
        self.closeButton.SetEvent(ui.__mem_func__(self.OnClickClose))
        self.resultSlot.SetSelectItemSlotEvent(ui.__mem_func__(self.OnResultSlotClick))

    # ---- Lifecycle ----

    def Open(self, cost, isFreeSpin):
        self.cost = int(cost)
        self.isFreeSpin = bool(isFreeSpin)
        self.__RefreshCost()
        self.__ResetWheel()
        self.SetCenterPosition()
        self.SetTop()
        self.Show()

    def Close(self):
        self.Hide()

    def OnPressEscapeKey(self):
        # Block escape while spinning to prevent the user dismissing the
        # window mid-animation; server has already committed the result.
        if self.spinning:
            return True
        self.Close()
        return True

    @ui.WindowDestroy
    def Destroy(self):
        if self.spinButton:
            self.spinButton.SetEvent(0)
        if self.closeButton:
            self.closeButton.SetEvent(0)
        if self.resultSlot:
            self.resultSlot.SetSelectItemSlotEvent(0)
        self.ClearDictionary()
        self.__Initialize()

    # ---- Spin flow ----

    def OnSpin(self):
        if self.spinning or self.isPending:
            return
        self.isPending = True
        self.spinButton.Disable()
        # TODO: verify net.SendWheelSpin exists in your fork (bindings.md).
        # Some forks send via player.SendXxxAction(...) helpers instead of
        # direct net.SendXxx -- match the fork's convention.
        net.SendWheelSpin()

    def OnRecvSpinResult(self, finalSegmentIdx, rewardVnum, rewardCount):
        # Server-authoritative result. Client renders the animation
        # converging on the segment server picked. NEVER pick locally
        # (failure-atlas entry 24).
        # Guard against duplicate Recv packets and against results arriving
        # for a window the user already closed: only honor the first result
        # for an in-flight spin while the window is visible.
        if self.spinning:
            return
        if not self.isPending:
            return
        if not self.IsShow():
            self.isPending = False
            return
        self.finalSegmentIdx = int(finalSegmentIdx)
        self.rewardVnum = int(rewardVnum)
        self.rewardCount = int(rewardCount)
        self.isPending = False
        self.__StartAnimation()

    def OnRecvSpinReject(self, reasonText):
        self.isPending = False
        self.spinButton.Enable()
        self.spinButton.SetUp()
        if reasonText:
            chat.AppendChat(chat.CHAT_TYPE_INFO, reasonText)

    def __StartAnimation(self):
        self.startRotation = self.rotation
        self.finalRotation = self.startRotation + ComputeFinalRotation(
            self.finalSegmentIdx, TOTAL_SEGMENTS, DEFAULT_SPIN_COUNT
        )
        self.elapsed = 0.0
        self.lastUpdate = app.GetTime()
        self.spinning = True

    def OnUpdate(self):
        if not self.spinning:
            return
        now = app.GetTime()
        dt = now - self.lastUpdate
        self.lastUpdate = now
        self.elapsed += dt

        if self.elapsed >= self.totalDuration:
            # Snap to exact final rotation; ignore accumulated dt drift.
            self.rotation = self.finalRotation
            if self.wheelImage:
                self.wheelImage.SetRotation(self.rotation)
            self.spinning = False
            self.__OnSpinComplete()
            return

        progress = self.elapsed / self.totalDuration
        eased = EaseOut(progress)
        self.rotation = self.startRotation + (self.finalRotation - self.startRotation) * eased
        if self.wheelImage:
            self.wheelImage.SetRotation(self.rotation)

    def __OnSpinComplete(self):
        # Reveal the reward in the result slot, then re-enable Close so the
        # user can dismiss the window. Spin button stays disabled until the
        # window is reopened with a fresh Open(cost) call -- the lifecycle
        # is one-shot per session.
        if self.rewardVnum > 0:
            self.resultSlot.SetItemSlot(0, self.rewardVnum, self.rewardCount)
        # Spin button intentionally stays disabled at the end of a one-shot
        # session. Forks that allow re-spin without re-opening the window
        # should call self.spinButton.Enable() + Open() with a fresh cost.
        # Optional: send a confirm packet so the server moves the reward
        # into inventory at this point (some forks split the result-pick
        # and reward-grant into two packets so the user sees the spin
        # before the inventory slot fills).
        # TODO: verify net.SendWheelClaim if your fork uses two-step grant.

    # ---- Helpers ----

    def __ResetWheel(self):
        self.spinning = False
        self.elapsed = 0.0
        self.startRotation = 0.0
        self.finalRotation = 0.0
        self.rotation = 0.0
        self.finalSegmentIdx = -1
        self.rewardVnum = 0
        self.rewardCount = 0
        if self.wheelImage:
            self.wheelImage.SetRotation(0.0)
        if self.resultSlot:
            self.resultSlot.ClearSlot(0)

    def __RefreshCost(self):
        if self.isFreeSpin:
            self.costText.SetText(localeInfo.WHEEL_COST_FREE)
        else:
            self.costText.SetText(constInfo.intWithCommas(self.cost))

    def OnClickClose(self):
        if self.spinning:
            # Block close while spinning -- protects the server's committed
            # result from being dismissed mid-animation.
            return
        self.Close()

    def OnResultSlotClick(self, slotIndex):
        # Click on result slot does nothing but tooltip rendering is wired
        # through OverIn/OverOut hooks (omitted here for brevity).
        pass

    def SetItemToolTip(self, tooltip):
        self.tooltipItem = tooltip
```

## Locale entries

```
WHEEL_TITLE              Wheel of Fortune
WHEEL_COST_LABEL         Cost:
WHEEL_COST_FREE          Free spin
WHEEL_SPIN_BUTTON        Spin
WHEEL_CLOSE_BUTTON       Close
WHEEL_NEED_FUNDS         Insufficient funds.
WHEEL_RESULT_LABEL       You won:
```

## interfacemodule.py integration snippet

```python
import uiwheelroulette

self.wndWheel = None  # lazy-built; the wheel is one-shot per session

def OnRecvWheelOpen(cost, isFreeSpin):
    if interface.wndWheel is None:
        interface.wndWheel = uiwheelroulette.WheelRouletteWindow()
        if interface.tooltipItem is not None:
            interface.wndWheel.SetItemToolTip(interface.tooltipItem)
    interface.wndWheel.Open(cost, isFreeSpin)

def OnRecvSpinResult(finalSegmentIdx, rewardVnum, rewardCount):
    if interface.wndWheel is not None:
        interface.wndWheel.OnRecvSpinResult(finalSegmentIdx, rewardVnum, rewardCount)

def OnRecvSpinReject(reasonText):
    if interface.wndWheel is not None:
        interface.wndWheel.OnRecvSpinReject(reasonText)
```

The wheel is opened in response to a server-pushed `OnRecvWheelOpen` (e.g., player consumed a wheel-token; server sends the open packet with the cost). Close is handled internally by the window's Close button.

## Common variations

### Variation 1: 8-segment wheel

Default (`TOTAL_SEGMENTS = 8`). Eight reward slots. Use this for general-purpose wheels.

### Variation 2: 12-segment wheel

`TOTAL_SEGMENTS = 12`. Tighter wedges (30 degrees each). Use this when there are 12 distinct reward tiers (e.g., monthly horoscope wheel).

### Variation 3: Instant-spin (no animation)

Skip `__StartAnimation` and call `__OnSpinComplete` directly from `OnRecvSpinResult`. Useful when wheel is purely cosmetic (the server has already moved the reward; the spin animation is just user-feedback) and the user has opted into "skip animation" via settings.

### Variation 4: Free-spin-count-driven

Maintain `self.freeSpinCount` (server-pushed). Open the window with `Open(cost, isFreeSpin=True)` if `freeSpinCount > 0`. After spin, decrement `freeSpinCount` on Recv-side and refresh the cost label. When `freeSpinCount == 0`, switch to paid mode (Yang / cheque consumed per spin).

### Variation 5: Cinematic-spin overlay

Wrap the window in a TOP_MOST curtain layer that dims the rest of the UI during the spin. Implement by adding a fullscreen `ui.ImageBox` with `SetParent(wndMgr.GetTopMostWindow())` and a tinted half-alpha asset; show on `__StartAnimation`, hide on `__OnSpinComplete`.

## Don't copy these obsolete bits

- **Client-side random selection (failure-atlas entry 24)** -- some sources call `random.randint(0, totalSegments)` in `OnUpdate` to drive the animation while the actual reward is decided server-side. The visual segment doesn't match the awarded reward. Anchor uses `finalSegmentIdx` from `OnRecvSpinResult` exclusively.
- **Framerate-dependent decrement** -- one observed pattern is `self.Langsamer -= 0.1` per `OnUpdate` call, where `Langsamer` is the angular velocity. At 60fps the spin lasts ~5 seconds; at 30fps it lasts ~10. Use `app.GetTime()` deltas (elapsed-time math) instead.
- **Missing settle snap** -- accumulating `dt` math over a 5-second animation drifts a few degrees from the intended `finalRotation`. At settle, snap rotation to `self.finalRotation` exactly (the anchor's `if self.elapsed >= self.totalDuration` branch).
- **Missing OnUpdate guard on `not spinning`** -- if `OnUpdate` always advances rotation regardless of `self.spinning`, the wheel keeps drifting after settle. Always check `if not self.spinning: return` first.
- **OnPressEscapeKey closing during spin** -- letting Escape dismiss the window mid-animation lets the user "skip" the spin. The anchor blocks Escape (and Close button) while `self.spinning is True`.
- **Bare bound methods on Spin button** -- `self.spinButton.SetEvent(self.OnSpin)` leaks `self`. Use `ui.__mem_func__(self.OnSpin)` per the Critical Rule 5 callback-wrapping matrix.
