# Anchor 11: Quest / NPC Dialog Window

## What this is + when to use it

A modal-style dialog driven by server-pushed content: the player walks up to an NPC, the server pushes a `RecvQuestDialog` packet, and the client renders the packet's text + reward items + reply-button list. The window's content is mostly DYNAMIC (not declared in uiscript) — the chrome is a board + thin background, and the body is populated at runtime by the `event` C++ Python module (`event.SetEventSet`, `event.UpdateEventSet`).

Use this archetype for: NPC quest offers, NPC reply dialogs, story cutscene boxes, dungeon-entrance prompts, anything where the SERVER decides what text and which buttons to show. Distinct from `01-simple-dialog` because content is server-driven (not hardcoded), and from `02-board-with-list` because button text and count vary per packet.

This window also implements the canonical "auto-close on distance" pattern — the player walking away from the NPC closes the dialog without explicit cancel. Cross-link to patterns.md §7.15 for the polling code.

Layer augmentor `15-network-coupled-flow` to document the full Recv → setter → render flow. Layer `05-feature-gated` if the quest system itself is fork-gated.

## Source

Pattern extracted from `pack/pack/root/uiquest.py` (the `QuestDialog` class) and `pack/pack/uiscript/uiscript/questdialog.py` from a real Metin2 fork. Real source is 906 lines — anchor extracts the LIFECYCLE pattern (load + close + auto-close + event-handler binding) and treats the dynamic body content as an opaque `event` module call. Forks that customize the dynamic body should reference the fork's `event` Python binding directly.

Normalized to current m2ui rules:

- Added explicit `__Initialize()` (real source uses inline `__init__` resets; consolidation reduces drift between init and Destroy)
- `@ui.WindowDestroy` on `Destroy` (real source has it — preserved verbatim)
- All callbacks via `ui.__mem_func__()` (real source uses the same)
- `event.SetEventHandler(idx, self)` registers the window as the event handler — real binding from `pack/pack/root/uiquest.py`; verify in `bindings.md` `event` module section
- `OnPressEscapeKey()` returns `True`
- Distance-polling pattern in `OnUpdate` is canonical Metin2 — see patterns.md §7.15 ("close-on-distance")
- ASCII-only

## Uiscript dict

```python
ROOT = "d:/ymir work/ui/public/"

window = {
    "name" : "QuestDialog",
    "style" : ("float",),

    "x" : 0,
    "y" : 0,

    "width" : 800,
    "height" : 450,

    "children" :
    (
        {
            "name" : "board",
            "type" : "thinboard",
            "style" : ("attach", "ignore_size",),

            "x" : 0,
            "y" : 0,

            "horizontal_align" : "center",
            "vertical_align"   : "center",

            "width" : 350,
            "height" : 300,
        },
    ),
}
```

The body is intentionally bare — the `event` Python module renders text, buttons, and reward slots dynamically over the board at runtime. The board itself is just chrome.

## Root class

```python
import ui
import dbg
import wndMgr
import event
import net
import player
import chr
import constInfo
from _weakref import proxy


class QuestDialog(ui.ScriptWindow):

    SKIN_NONE = 0
    SKIN_CINEMA = 5

    AUTO_CLOSE_DISTANCE = 1000

    def __init__(self, skin, idx):
        ui.ScriptWindow.__init__(self)
        self.SetWindowName("quest dialog")
        self.__Initialize(skin, idx)
        self.__LoadDialog()

        # Register for event-module callbacks. The C++ event module pushes
        # text + buttons + reward items into this window's idx slot.
        event.SetEventHandler(idx, self)

        # Snapshot starting position for distance polling.
        (self.startX, self.startY, self.startZ) = player.GetMainCharacterPosition()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def __Initialize(self, skin, idx):
        self.focusIndex = 0
        self.board = None
        self.sx = 0
        self.sy = 0
        self.skin = skin
        self.descIndex = idx
        self.OnCloseEvent = None
        self.btnAnswer = None
        self.btnNext = None
        self.imgTitle = None
        self.images = []
        self.prevbutton = None
        self.nextbutton = None
        self.needInputString = False
        self.editSlot = None
        self.editLine = None
        self.startX = 0
        self.startY = 0
        self.startZ = 0

    def __LoadDialog(self):
        try:
            scriptLoader = ui.PythonScriptLoader()
            scriptLoader.LoadScriptFile(self, "uiscript/questdialog.py")
        except RuntimeError:
            dbg.TraceError("QuestDialog.LoadDialog")

        try:
            self.board = self.GetChild('board')
        except RuntimeError:
            dbg.TraceError("QuestDialog.BindObject")

        self.SetCenterPosition()
        if self.SKIN_CINEMA == self.skin:
            self.board.Hide()

    @ui.WindowDestroy
    def Destroy(self):
        self.ClearDestroy()

    def ClearDestroy(self):
        # Real source's destroy path. Triggers any pending OnCloseEvent
        # before tearing down the descIndex.
        self.ClearDictionary()
        if self.OnCloseEvent:
            self.OnCloseEvent()
            self.OnCloseEvent = None

            # Quest-input variant: when the dialog had an EditLine,
            # commit its content to the server on close.
            if self.needInputString and self.editLine:
                text = self.editLine.GetText()
                net.SendQuestInputStringPacket(text)

        self.imgTitle = None
        self.images = None
        self.board = None
        if self.descIndex:
            event.ClearEventSet(self.descIndex)
            self.descIndex = None
        self.focusIndex = 0

    def Open(self):
        self.SetTop()
        self.Show()

    def Close(self):
        # Quest dialogs are typically closed via Destroy (one-shot lifetime).
        # Use Destroy when the user accepts/declines and the dialog should
        # not be reopenable; use Hide if the dialog persists.
        self.Hide()

    def CloseSelf(self):
        # Real source's helper for the explicit-cancel path.
        self.btnNext = None
        self.btnAnswer = None
        self.ClearDestroy()

    def OnPressEscapeKey(self):
        self.CloseSelf()
        return True

    def OnPressExitKey(self):
        self.CloseSelf()
        return True

    def OnUpdate(self):
        # Auto-close: if the player walked away from the starting NPC, close.
        if self.skin == self.SKIN_CINEMA:
            event.UpdateEventSet(self.descIndex, 50, -(wndMgr.GetScreenHeight() - 44))
        elif self.skin and self.board:
            event.UpdateEventSet(
                self.descIndex,
                self.board.GetGlobalPosition()[0] + 20,
                -self.board.GetGlobalPosition()[1] - 20,
            )
            event.SetEventSetWidth(self.descIndex, self.board.GetWidth() - 40)
        else:
            event.UpdateEventSet(self.descIndex, 0, 0)

        # Distance polling — close when the player walks away from the NPC.
        # patterns.md section 7.15 documents this idiom.
        (x, y, z) = player.GetMainCharacterPosition()
        if abs(x - self.startX) > self.AUTO_CLOSE_DISTANCE or abs(y - self.startY) > self.AUTO_CLOSE_DISTANCE:
            self.CloseSelf()

    def SetCloseEvent(self, event):
        self.OnCloseEvent = event

    # Event-module-driven button callbacks. The event module dispatches
    # button clicks back into this window via these methods (registered
    # via event.SetEventHandler(idx, self) in __init__).

    def OnReplyButtonClicked(self, replyIndex):
        # Send the player's choice to the server.
        net.SendQuestReplyPacket(self.descIndex, replyIndex)
        self.CloseSelf()

    def OnAcceptButtonClicked(self):
        net.SendQuestReplyPacket(self.descIndex, 1)
        self.CloseSelf()

    def OnDeclineButtonClicked(self):
        net.SendQuestReplyPacket(self.descIndex, 0)
        self.CloseSelf()
```

## Locale entries

Quest dialogs are content-driven — the dialog text comes from the server (`RecvQuestDialog`'s payload), not from `localeInfo`. There are typically NO locale entries for the quest archetype itself. Static action labels (Accept/Decline/Cancel) come from the server-pushed button list.

If the fork hardcodes Accept/Decline button labels client-side, append:

```
QUEST_ACCEPT	Accept
QUEST_DECLINE	Decline
QUEST_NEXT	Next
QUEST_PREV	Previous
```

## interfacemodule.py integration snippet

Quest dialogs are typically created on-demand via the `event` module — `interfacemodule.py` does NOT construct them at MakeInterface time. Instead, register the event handler factory:

```python
import event
import uiQuest

# Top-level: register the QuestDialog class as the factory for the
# event module's quest-dialog slot. The event module calls this
# factory whenever the server pushes a RecvQuestDialog packet.
event.RegisterEventSetFactory(uiQuest.QuestDialog)
```

In `net.py`:

```python
def OnQuestDialog(skin, idx, text, buttonLabels, rewards):
    # The event module handles instantiation; net.py just dispatches.
    event.SetEventSet(idx, skin, text)
    for i, label in enumerate(buttonLabels):
        event.AddEventSetButton(idx, i, label)
    for slot, vnum, count in rewards:
        event.AddEventSetReward(idx, slot, vnum, count)
```

The `interfacemodule.py` cleanup point is the destroy in `__DestroyDialogs` — the event module owns the dialog instance, so cleanup is:

```python
class Interface(object):

    def HideAllWindows(self):
        # Quest dialogs auto-close on their own OnUpdate distance check,
        # but global-hide should also clear them.
        event.ClearAllEventSets()
```

## Common variations

1. **Cinema skin** (cutscene-style fullscreen black bars) — `__init__(self, skin=5, idx=...)`. The skin-5 path in `__LoadDialog` calls `self.board.Hide()` so the dialog appears as text-only over the curtain. Useful for story cutscenes that don't need a board.
2. **Quest-input dialog** (player types a string back to the server) — set `self.needInputString = True` and create an `EditLine` widget over the board. `ClearDestroy` commits the text via `net.SendQuestInputStringPacket(text)` automatically. The button list reduces to a single Submit.
3. **Multi-page dialog** (Prev/Next paging through long text) — wire `prevbutton` and `nextbutton` widgets to call `event.NextPage(idx)` / `event.PrevPage(idx)`. The event module advances the page; `OnUpdate` re-renders.
4. **Auto-resize board** (board grows to fit content height) — used when the server can't predict text length. In `OnUpdate`, recompute board size from `event.GetEventSetHeight(idx)` and call `self.board.SetSize(self.board.GetWidth(), height)`. The content stays anchored to the board's resized rect.
5. **Reply-button grid** (large NPC menu with 8+ reply options) — render replies as a vertical button stack instead of horizontal. Layout is server-driven; the client just iterates `event.GetEventSetButtonCount(idx)` and positions each.

## Don't copy these obsolete bits

- Real source uses `hasattr(QuestDialog, 'QuestCurtain')` to lazy-create a class-level curtain singleton. Anchor strips this — the curtain (cinema mode) belongs in a separate widget, not as a QuestDialog class attribute. Refactor: define `QuestCurtain` as a separate window in `uiQuestCurtain.py` and reference it via `interface.questCurtain` from interfacemodule.
- Real source has commented-out `# QUEST_INPUT` / `# QUEST_CANCEL` blocks marking optional features. Anchor inlines QUEST_INPUT (used in variation 2) and removes the markers. QUEST_CANCEL maps to `OnPressEscapeKey` calling `CloseSelf` — already covered.
- Real source has a `BarButton(ui.Button)` subclass with custom render. Skipped — the event module handles button rendering; subclassing `ui.Button` here is over-engineering. Use plain `ui.Button` instances appended via `event.AddEventSetButton`.
- Real source's `__init__` mixes business logic (curtain creation, height calculation) with init. Anchor splits into `__Initialize()` (state defaults) + `__LoadDialog()` (uiscript load + chrome bind) + curtain logic in interfacemodule.
- Real source uses `RuntimeError` exception type in `__LoadDialog` `try/except`. Anchor preserves this — the engine's `LoadScriptFile` raises `RuntimeError` specifically when the uiscript file fails to load. Don't replace with bare `except` — would mask unrelated bugs.
- Some forks call `self.descWindow = DescriptionWindow(idx)` to create an inner widget for the description text. Anchor skips this — the event module handles description rendering directly. Use a `DescriptionWindow` only if the fork's event module requires a Python-side widget (rare).
