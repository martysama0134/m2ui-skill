# Anchor 19: Daily Reward Grid / Check-In Calendar

## What this is + when to use it

A primary archetype for **server-driven daily-reward grids**. Window shows a fixed 7-by-N grid of day-cells representing a reward calendar (e.g., 28-day month, 7-day rotating week, or 30-day login streak). Today is highlighted; claimed days are greyed; clicking the eligible day claims the reward. Server is authoritative for "today" and "claimed" -- the client never computes those locally.

Use this archetype for: daily-login reward systems, weekly-event check-in, monthly-pass progress, streak-based bonus systems. Distinct from `02-board-with-list` (passive list) and `08-inventory-equipment` (player-state grid) by virtue of FIXED CELL POSITIONS plus PER-CELL CLAIM LIFECYCLE.

Layer `15-network-coupled-flow` for the request-response (claim) plus broadcast-update (state push) contracts. Layer `timer-patterns.md` section 5 (daily-event-timing) if the window needs to react to in-game day transitions while open.

## Source

Canonical daily-reward / check-in UI as commonly built across real Metin2 forks. The structural conventions for the slot grid are inherited from `08-inventory-equipment` (fixed slot positions, programmatic build, single per-slot click handler dispatch) and the server-state contract from `15-network-coupled-flow` (Recv-pushed authoritative state, no client-side day computation). The anti-tz-boundary discipline -- never compute `today` from `app.GetTime()` -- is baked in to mitigate failure-atlas entry 23, which is the dominant failure mode observed when client-local time is used.

## Uiscript dict

`pack/pack/uiscript/uiscript/dailyrewardwindow.py`:

```python
window = {
    "name" : "DailyRewardWindow",
    "x" : 0,
    "y" : 0,
    "style" : ("movable", "float",),

    "width" : 380,
    "height" : 360,

    "children" :
    (
        {
            "name" : "board",
            "type" : "board_with_titlebar",
            "x" : 0,
            "y" : 0,
            "width" : 380,
            "height" : 360,
            "title" : uiScriptLocale.DAILY_REWARD_TITLE,

            "children" :
            (
                {
                    "name" : "info_text",
                    "type" : "text",
                    "x" : 18,
                    "y" : 38,
                    "text" : uiScriptLocale.DAILY_REWARD_INFO,
                    "not_pick" : 1,
                },

                # Day-cell grid container (slots inserted programmatically).
                {
                    "name" : "grid_thinboard",
                    "type" : "thinboard",
                    "x" : 14,
                    "y" : 64,
                    "width" : 352,
                    "height" : 232,
                },

                # Status text (eligible / already-claimed / next-claim-in).
                {
                    "name" : "status_text",
                    "type" : "text",
                    "x" : 18,
                    "y" : 304,
                    "text" : "",
                    "not_pick" : 1,
                },

                # Claim button (enabled only when today is eligible).
                {
                    "name" : "claim_button",
                    "type" : "button",
                    "x" : 240,
                    "y" : 320,
                    "text" : uiScriptLocale.DAILY_REWARD_CLAIM_BUTTON,
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

`pack/pack/root/uidailyrewardwindow.py`:

```python
import ui
import net
import app
import chat
import item
import localeInfo
import uiScriptLocale
import constInfo
from _weakref import proxy

# Grid geometry. Default 28-day calendar (7x4); swap for week or 30-day.
GRID_COLUMNS = 7
GRID_ROWS = 4
DAY_COUNT = GRID_COLUMNS * GRID_ROWS

CELL_SIZE = 44
CELL_GAP = 4
GRID_OFFSET_X = 16
GRID_OFFSET_Y = 16

# Cell visual states
CELL_STATE_LOCKED = 0     # not yet eligible (future days)
CELL_STATE_TODAY = 1      # today's claimable cell
CELL_STATE_CLAIMED = 2    # already claimed (past + today-after-claim)
CELL_STATE_MISSED = 3     # past day that was not claimed (still locked)


class DayCell(ui.Window):
    """One cell in the reward grid. Owns its slot widget and overlay icon.

    The cell binds its slot click handler directly to a proxy of the parent
    window. Storing a bound parent method on the cell (e.g.,
    `self.clickCallback = parentWindow.OnClickCell`) would defeat the proxy
    lambda's weakref discipline -- the cell would still hold the parent
    strong via the bound method, recreating the cycle the proxy was meant
    to break.
    """

    def __init__(self, parent, parentWindow, dayIndex):
        ui.Window.__init__(self)
        self.SetParent(parent)
        self.dayIndex = dayIndex
        self.state = CELL_STATE_LOCKED

        self.slot = ui.SlotWindow()
        self.slot.SetParent(self)
        self.slot.SetSlotStyle(ui.SLOT_STYLE_NONE)
        self.slot.SetPosition(0, 0)
        self.slot.SetSize(CELL_SIZE, CELL_SIZE)
        self.slot.AppendSlot(0, 0, 0, CELL_SIZE, CELL_SIZE)
        self.slot.SetSelectEmptySlotEvent(
            lambda r=proxy(parentWindow), idx=dayIndex: r.OnClickCell(idx)
        )
        self.slot.Show()

        self.dayLabel = ui.TextLine()
        self.dayLabel.SetParent(self)
        self.dayLabel.SetPosition(2, 2)
        self.dayLabel.SetText(str(dayIndex + 1))
        self.dayLabel.Show()

        self.overlayClaimed = ui.ImageBox()
        self.overlayClaimed.SetParent(self.slot)
        # TBD ASSET: d:/ymir work/ui/public/check_overlay.sub  -- needs creation
        # If your fork ships a "claimed" overlay asset, swap the path. Until
        # then, the overlay stays hidden and the slot tints via SetItemSlot.
        self.overlayClaimed.Hide()

    def __del__(self):
        ui.Window.__del__(self)

    def SetReward(self, vnum, count):
        if vnum > 0:
            self.slot.SetItemSlot(0, vnum, count)
        else:
            self.slot.ClearSlot(0)

    def SetState(self, state):
        self.state = state
        if state == CELL_STATE_CLAIMED:
            self.overlayClaimed.Show()
        else:
            self.overlayClaimed.Hide()


class DailyRewardWindow(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.__Initialize()
        self.__LoadWindow()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def __Initialize(self):
        self.gridBoard = None
        self.statusText = None
        self.claimButton = None
        self.cells = []                # list of DayCell, length == DAY_COUNT
        self.rewardConfig = []         # list of (vnum, count) per dayIndex; static
        self.claimedSet = set()        # set of int day indices, server-pushed
        self.todayDay = -1             # int 0..DAY_COUNT-1, server-pushed
        self.serverEpoch = 0           # snapshot from RecvDailyState
        self.isClaimPending = False
        self.tooltipItem = None

    def __LoadWindow(self):
        try:
            self.LoadScriptFile("uiscript/dailyrewardwindow.py")
        except:
            import exception
            exception.Abort("DailyRewardWindow.__LoadWindow.LoadScriptFile")

        try:
            self.gridBoard = self.GetChild("grid_thinboard")
            self.statusText = self.GetChild("status_text")
            self.claimButton = self.GetChild("claim_button")
        except:
            import exception
            exception.Abort("DailyRewardWindow.__LoadWindow.BindObject")

        self.claimButton.SetEvent(ui.__mem_func__(self.OnClickClaim))
        self.__BuildGrid()
        self.__LoadRewardConfig()

    def __BuildGrid(self):
        for dayIndex in xrange(DAY_COUNT):
            col = dayIndex % GRID_COLUMNS
            row = dayIndex // GRID_COLUMNS
            x = GRID_OFFSET_X + col * (CELL_SIZE + CELL_GAP)
            y = GRID_OFFSET_Y + row * (CELL_SIZE + CELL_GAP)
            cell = DayCell(self.gridBoard, self, dayIndex)
            cell.SetPosition(x, y)
            cell.SetSize(CELL_SIZE, CELL_SIZE)
            cell.Show()
            self.cells.append(cell)

    def __LoadRewardConfig(self):
        # Reward config is fork-specific. Common pattern: read from a static
        # constInfo dict, OR from a per-account server-pushed payload at
        # OnRecvDailyState time. The anchor uses a static placeholder; swap
        # for whichever your fork uses.
        # TODO: replace with your fork's reward source (constInfo.DAILY_REWARDS
        # or server-pushed config payload).
        self.rewardConfig = [(0, 0)] * DAY_COUNT
        for index, cell in enumerate(self.cells):
            vnum, count = self.rewardConfig[index]
            cell.SetReward(vnum, count)

    # ---- Lifecycle ----

    def Open(self):
        self.SetCenterPosition()
        self.SetTop()
        self.Show()
        self.RequestState()

    def Close(self):
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True

    @ui.WindowDestroy
    def Destroy(self):
        if self.claimButton:
            self.claimButton.SetEvent(0)
        for cell in self.cells:
            if cell.slot:
                cell.slot.SetSelectEmptySlotEvent(0)
        self.cells = []
        self.ClearDictionary()
        self.__Initialize()

    # ---- Server contract ----

    def RequestState(self):
        # TODO: verify net.SendDailyRewardStateRequest exists in your fork
        # (bindings.md). The exact name varies; one fork-specific alternative
        # is sending via net.SendChatPacket with a "/daily_state" command.
        net.SendDailyRewardStateRequest()

    def OnRecvDailyState(self, claimedSet, todayDay, serverEpoch):
        # Server-pushed authoritative state. Do NOT compute todayDay locally
        # (failure-atlas entry 23). Always trust the server's value.
        self.claimedSet = set(claimedSet) if claimedSet else set()
        self.todayDay = int(todayDay)
        self.serverEpoch = int(serverEpoch)
        self.isClaimPending = False
        self.RefreshGrid()
        self.RefreshClaimButton()
        self.RefreshStatus()

    def OnRecvDailyClaimSuccess(self, dayIndex):
        # Server confirms the claim. Mark cell as claimed and disable claim
        # button until next eligible day.
        self.claimedSet.add(int(dayIndex))
        self.isClaimPending = False
        self.RefreshGrid()
        self.RefreshClaimButton()
        self.RefreshStatus()

    def OnRecvDailyClaimReject(self, reasonText):
        self.isClaimPending = False
        if reasonText:
            chat.AppendChat(chat.CHAT_TYPE_INFO, reasonText)
        self.RefreshClaimButton()

    # ---- Refresh ----

    def RefreshGrid(self):
        for index, cell in enumerate(self.cells):
            if index in self.claimedSet:
                cell.SetState(CELL_STATE_CLAIMED)
            elif index == self.todayDay:
                cell.SetState(CELL_STATE_TODAY)
            elif index < self.todayDay:
                cell.SetState(CELL_STATE_MISSED)
            else:
                cell.SetState(CELL_STATE_LOCKED)

    def RefreshClaimButton(self):
        eligible = self.__IsTodayEligible()
        if eligible and not self.isClaimPending:
            self.claimButton.Enable()
            self.claimButton.SetUp()
        else:
            self.claimButton.Disable()

    def RefreshStatus(self):
        if self.todayDay < 0:
            self.statusText.SetText("")
            return
        if self.todayDay in self.claimedSet:
            self.statusText.SetText(localeInfo.DAILY_REWARD_ALREADY_CLAIMED)
        else:
            self.statusText.SetText(localeInfo.DAILY_REWARD_AVAILABLE)

    def __IsTodayEligible(self):
        if self.todayDay < 0 or self.todayDay >= DAY_COUNT:
            return False
        return self.todayDay not in self.claimedSet

    # ---- Click flow ----

    def OnClickCell(self, dayIndex):
        # Cell click is informational only -- shows the reward tooltip.
        # Actual claim goes through the dedicated Claim button to prevent
        # accidental clicks consuming the daily slot.
        if self.tooltipItem:
            vnum, count = self.rewardConfig[dayIndex]
            if vnum > 0:
                self.tooltipItem.ClearToolTip()
                self.tooltipItem.AddItemData(vnum, [0, 0, 0], [(0, 0)] * 7)

    def OnClickClaim(self):
        if self.isClaimPending:
            return
        if not self.__IsTodayEligible():
            return
        self.isClaimPending = True
        self.RefreshClaimButton()
        # TODO: verify net.SendDailyRewardClaim exists in your fork
        # (bindings.md). Alternative shapes: net.SendChatPacket("/claim_daily").
        net.SendDailyRewardClaim(self.todayDay)

    def SetItemToolTip(self, tooltip):
        self.tooltipItem = tooltip
```

## Locale entries

```
DAILY_REWARD_TITLE              Daily Reward
DAILY_REWARD_INFO               Claim today's reward.
DAILY_REWARD_CLAIM_BUTTON       Claim
DAILY_REWARD_AVAILABLE          Today's reward is available.
DAILY_REWARD_ALREADY_CLAIMED    Today's reward has already been claimed.
DAILY_REWARD_NEXT_IN            Next reward in %s.
```

## interfacemodule.py integration snippet

```python
import uidailyrewardwindow

self.wndDailyReward = None  # lazy-built on first toggle

def ToggleDailyReward(self):
    if self.wndDailyReward is None:
        self.wndDailyReward = uidailyrewardwindow.DailyRewardWindow()
        if self.tooltipItem is not None:
            self.wndDailyReward.SetItemToolTip(self.tooltipItem)
    if self.wndDailyReward.IsShow():
        self.wndDailyReward.Close()
    else:
        self.wndDailyReward.Open()

# Recv handlers (network module)
def OnRecvDailyState(claimedSet, todayDay, serverEpoch):
    if interface.wndDailyReward is not None:
        interface.wndDailyReward.OnRecvDailyState(claimedSet, todayDay, serverEpoch)

def OnRecvDailyClaim(success, dayIndex, reasonText):
    if interface.wndDailyReward is None:
        return
    if success:
        interface.wndDailyReward.OnRecvDailyClaimSuccess(dayIndex)
    else:
        interface.wndDailyReward.OnRecvDailyClaimReject(reasonText)
```

Lazy-build is appropriate -- the daily-reward window is opened from a menu button, not always-on.

## Common variations

### Variation 1: 7-day single-week grid

Set `GRID_COLUMNS = 7`, `GRID_ROWS = 1`, `DAY_COUNT = 7`. The grid renders horizontally as a strip of 7 cells. Use this when rewards reset every week and the calendar is purely cyclical.

### Variation 2: 30-day month grid

Set `GRID_COLUMNS = 6`, `GRID_ROWS = 5`, `DAY_COUNT = 30`. Wider window: bump `width` in the uiscript dict to ~440px.

### Variation 3: Cumulative-bonus grid

Add a special "8th-day" cell that unlocks once the player claims 7 consecutive days. Track via a server-pushed `consecutiveCount` field in `OnRecvDailyState`; render an extra `bonusCell` widget; gate the bonus claim on `consecutiveCount >= 7`.

### Variation 4: Tier-based grid (basic / premium tabs)

Wrap the grid in a 2-tab tab strip (see `16-tabbed-content`). Each tab has its own `rewardConfig` and its own `claimedSet`. The `RequestState` send specifies which tier the player is querying.

### Variation 5: Auto-claim-on-login

Skip the Claim button entirely. On `OnRecvDailyState`, if `todayDay not in claimedSet`, immediately send `SendDailyRewardClaim(todayDay)`. The user sees a brief "Reward claimed" chat line and a tooltip-style overlay; no manual click required.

## Don't copy these obsolete bits

- **Client-`app.GetTime()`-based today computation (failure-atlas entry 23)** -- some daily-reward systems compute `today_idx = (app.GetTime() // 86400) % 7` locally so the grid feels responsive without a server roundtrip. This breaks at tz boundaries, DST transitions, and on player tz changes. Always use server-pushed `todayDay`.
- **Missing `isClaimPending` guard** -- rapid-clicking the Claim button before the server confirms can fire 5+ claim packets, all but one of which the server will reject (and the rejects may overwrite the success message in chat). Lock the button on Send, unlock on Recv.
- **Missing "already claimed today" reject UI** -- if the server returns a reject for "already claimed", show a chat line explaining why; do NOT silently re-enable the button.
- **Bare bound methods on cell click handlers** -- `self.slot.SetSelectEmptySlotEvent(self.OnClickCell)` leaks `self` into every cell. Use `lambda r=proxy(self), idx=dayIndex: r.OnClickCell(idx)` per `event-binding.md` matrix.
- **`SetSelectEmptySlotEvent` with extra args (Pattern B)** -- by default in stock `ui.py`, `SlotWindow.SetSelectEmptySlotEvent` is a 1-arg setter; passing extra args raises `TypeError` (Critical Rule 19). Either augment `ui.py` per `framework-augmentations.md`, or use the proxy-lambda Pattern C as shown in `DayCell.__init__`.
- **Loading reward config via hardcoded magic numbers in `__init__`** -- if `rewardConfig` is hardcoded in Python, server reward changes require a client patch. Prefer reading from `constInfo` (mod-friendly), OR sending the config in the server's `OnRecvDailyState` payload (always-current).
