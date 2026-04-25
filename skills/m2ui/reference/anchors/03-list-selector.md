# Anchor 03: List Selector (Radio Buttons + Accept)

## What this is + when to use it

A form-style window where the user picks ONE option from a list of mutually-exclusive choices, then clicks Accept. The choices are radio buttons constructed at runtime — count varies based on data (e.g., available channels, races, server slots). Use this for "choose your channel," "choose your race," "choose a target" pickers. NOT for multi-select (use checkboxes; see widgets.md). NOT for free-form input (use EditLine; see `uipickmoney.py` for input + accept). NOT for >10 options (use a `listbox` widget instead — radios get unwieldy).

## Source

Extracted from `pack/pack/root/uimovechannel.py` (full file, 127 lines) and `pack/pack/uiscript/uiscript/movechanneldialog.py` (commit-time snapshot). Normalized to current m2ui rules:

- `//` for int division, not `/`
- All callbacks via `ui.__mem_func__()` — extra args via the event setter's trailing-args feature
- Replaced source's `lambda arg=i: self.SelectChannel(arg)` (leaks — body references `self`)
- `OnPressEscapeKey()` returns `True`
- Locale strings via `localeInfo.*` (uiscript dict OK to use either source)

## Uiscript dict

The uiscript provides ONLY the wrapper container (board + titlebar + accept/cancel + an empty `BlackBoard` to host the runtime-built radio buttons). Radio buttons themselves are constructed programmatically in the root class via `ui.MakeRadioButton(...)`.

```python
import localeInfo

window = {
    "name" : "MoveChannelDialog",
    "style" : ("movable", "float", "ltr"),

    "x" : (SCREEN_WIDTH // 2) - (190 // 2),
    "y" : (SCREEN_HEIGHT // 2) - 100,

    "width" : 0,
    "height" : 0,

    "children" :
    (
        {
            "name" : "MoveChannelBoard",
            "type" : "board",
            "style" : ("attach", "ltr"),

            "x" : 0,
            "y" : 0,

            "width" : 0,
            "height" : 0,

            "children" :
            (
                {
                    "name" : "MoveChannelTitle",
                    "type" : "titlebar",
                    "style" : ("attach",),

                    "x" : 6, "y" : 7, "width" : 190 - 13,

                    "children" :
                    (
                        {
                            "name" : "TitleName",
                            "type" : "text",
                            "style" : ("not_pick",),

                            "x" : 0, "y" : 0,
                            "text" : localeInfo.MOVE_CHANNEL_TITLE,
                            "all_align" : "center",
                        },
                    ),
                },

                {
                    "name" : "BlackBoard",
                    "type" : "thinboard_circle",
                    "x" : 13, "y" : 36,
                    "width" : 0, "height" : 0,
                },

                {
                    "name" : "AcceptButton",
                    "type" : "button",

                    "x" : 15,
                    "y" : 30,
                    "vertical_align" : "bottom",

                    "width" : 61,
                    "height" : 21,

                    "text" : localeInfo.MOVE_CHANNEL_SELECT,

                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },
                {
                    "name" : "CancelButton",
                    "type" : "button",

                    "x" : 115,
                    "y" : 30,
                    "vertical_align" : "bottom",

                    "width" : 61,
                    "height" : 21,

                    "text" : localeInfo.MOVE_CHANNEL_CANCEL,

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

```python
import app
import ui
import exception
import localeInfo
import chat
import serverInfo
import net


def GetServerID():
    serverID = 0
    for k in serverInfo.REGION_DICT[0].keys():
        if serverInfo.REGION_DICT[0][k]["name"] == net.GetServerInfo().split(",")[0]:
            serverID = k
            break
    return serverID


class MoveChannelWindow(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.__Initialize()
        self.__LoadWindow()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def __Initialize(self):
        self.board = None
        self.titleBar = None
        self.blackBoard = None
        self.acceptButton = None
        self.cancelButton = None
        self.channelButtonList = []
        self.currentChannel = 0
        self.ingameChannel = 1

    @ui.WindowDestroy
    def Destroy(self):
        self.__Initialize()
        self.ClearDictionary()
        self.Hide()

    def __LoadWindow(self):
        if getattr(self, "IsLoaded", False):
            return
        self.IsLoaded = True

        try:
            pyScrLoader = ui.PythonScriptLoader()
            pyScrLoader.LoadScriptFile(self, "uiscript/movechanneldialog.py")
        except:
            exception.Abort("MoveChannelWindow.__LoadWindow.LoadScript")

        try:
            self.board = self.GetChild("MoveChannelBoard")
            self.titleBar = self.GetChild("MoveChannelTitle")
            self.blackBoard = self.GetChild("BlackBoard")
            self.acceptButton = self.GetChild("AcceptButton")
            self.cancelButton = self.GetChild("CancelButton")
        except:
            exception.Abort("MoveChannelWindow.__LoadWindow.BindObject")

        self.titleBar.SetCloseEvent(ui.__mem_func__(self.Close))
        self.acceptButton.SetEvent(ui.__mem_func__(self.ChangeChannel))
        self.cancelButton.SetEvent(ui.__mem_func__(self.Close))

        self.__AddChannelButtons()

    def Open(self):
        if self.ingameChannel < 99:
            self.SelectChannel(self.ingameChannel - 1)
        else:
            self.__RefreshChannelButtons()
        self.SetCenterPosition()
        self.Show()

    def Close(self):
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True

    def GetChannelCount(self):
        return len(serverInfo.REGION_DICT[0][GetServerID()]["channel"])

    def __AddChannelButtons(self):
        ELEM_SIZE = 30
        BOARD_SIZE = ELEM_SIZE * self.GetChannelCount()
        self.SetSize(190, 80 + BOARD_SIZE)
        self.board.SetSize(190, 80 + BOARD_SIZE)
        self.blackBoard.SetSize(163, 7 + BOARD_SIZE)

        for i in xrange(self.GetChannelCount()):
            radioBtn = ui.MakeRadioButton(
                self.blackBoard,
                7,
                7 + ELEM_SIZE * i,
                "d:/ymir work/ui/game/myshop_deco/",
                "select_btn_01.sub",
                "select_btn_02.sub",
                "select_btn_03.sub",
            )
            radioBtn.SetText(serverInfo.REGION_DICT[0][GetServerID()]["channel"][i]["name"])
            # Extra-args feature on SetEvent: i is delivered to SelectChannel
            # WITHOUT capturing self in a lambda closure.
            radioBtn.SetEvent(ui.__mem_func__(self.SelectChannel), i)
            radioBtn.Show()
            self.channelButtonList.append(radioBtn)

    def __RefreshChannelButtons(self):
        for i in xrange(self.GetChannelCount()):
            if i == self.currentChannel:
                self.channelButtonList[i].Down()
            else:
                self.channelButtonList[i].SetUp()

    def SelectChannel(self, channel):
        self.currentChannel = channel
        self.__RefreshChannelButtons()

    def ChangeChannel(self):
        channelID = self.currentChannel + 1
        if channelID <= 0:
            chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.MOVE_CHANNEL_NOT_MOVE)
            return

        self.Close()
        net.SendChatPacket("/change_channel {}".format(channelID))
```

## Locale entries

```python
# In locale/<lang>/ui/locale_game.txt or locale_interface.txt
MOVE_CHANNEL_TITLE       Select Channel
MOVE_CHANNEL_SELECT      Move
MOVE_CHANNEL_CANCEL      Cancel
MOVE_CHANNEL_NOT_MOVE    Cannot move to this channel.
```

Channel names themselves come from `serverInfo.REGION_DICT[server][channel][i]["name"]` — already locale-aware via the server config.

## interfacemodule.py integration snippet

```python
import uimovechannel

# In MakeInterface or __init__:
self.wndMoveChannel = uimovechannel.MoveChannelWindow()

# Public entry — opened from a menu/keybind/quest dialog:
def OpenMoveChannelWindow(self):
    self.wndMoveChannel.ingameChannel = net.GetCurrentChannel()  # verify exact API in bindings.md
    self.wndMoveChannel.Open()

# In HideAllWindows:
def HideAllWindows(self):
    if self.wndMoveChannel:
        self.wndMoveChannel.Close()

# In __del__:
def __del__(self):
    if self.wndMoveChannel:
        self.wndMoveChannel.Destroy()
        self.wndMoveChannel = None
```

## Common variations

1. **Replace radios with a `listbox` widget** — better for >10 options. Build the listbox in uiscript, populate via `lb.AppendItem(text, key)`; read selection via `lb.GetSelectedItem()`.
2. **Add per-option icons** — `ui.MakeRadioButton` only supports text. For icons, hand-roll: create an `image` widget + a transparent `button` overlay; wire the button's `SetEvent` per row.
3. **Pre-select a default option** — call `self.SelectChannel(default_index)` after `__AddChannelButtons()` returns. Manual radio simulation already handles the visual `Down()`.
4. **Disable certain options** — call `self.channelButtonList[i].Disable()` on those (and skip them in the `SelectChannel` callback).
5. **Cancel button alongside Accept** — already in this anchor (CancelButton wired to `Close`). For destructive submit, swap to `uicommon.QuestionDialog` confirmation before the actual `ChangeChannel()` call.

## Don't copy these obsolete bits

- Source uses `lambda arg=i: self.SelectChannel(arg)` — REPLACED with `radioBtn.SetEvent(ui.__mem_func__(self.SelectChannel), i)`. Even with `arg=i` capturing `i`, the lambda body references `self` (closure leak). The extra-args feature on the event setter delivers `i` without any closure.
- AVOID `ui.RadioButtonGroup` even if the fork defines it. Its internal implementation uses self-capturing lambdas (same leak). The hand-rolled `MakeRadioButton` + manual `Down()`/`SetUp()` pattern in this anchor is leak-safe because each button gets `ui.__mem_func__` directly.
- Source uiscript uses `SCREEN_WIDTH/2` / `190/2` (Python 2 division) — REPLACED with `//`.
- Source `LoadScriptFile` arg `"UIScript/MoveChannelDialog.py"` (mixed case) — REPLACED with lowercase `"uiscript/movechanneldialog.py"`. Linux servers are case-sensitive; mixed-case paths break under Linux.
- Source `Destroy()` calls `Hide()` AFTER `ClearDictionary()` — order is fine, but reset (`__Initialize`) MUST come BEFORE `ClearDictionary()` so cleared widget refs aren't accessed during the ClearDictionary teardown.
