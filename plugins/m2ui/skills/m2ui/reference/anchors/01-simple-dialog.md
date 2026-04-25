# Anchor 01: Simple Dialog (Modal Yes/No)

## What this is + when to use it

A modal yes/no confirmation dialog with a body text line and two buttons (Accept, Cancel). Use this when you need to ask the user "are you sure?" before a destructive action, or to confirm a non-trivial choice. NOT for messages with no choice (use `MessageDialog` for that). NOT for windows with more than 2 actions (build a custom Board for those). NOT for free-form text input (use `uipickmoney.py` style EditLine + Accept).

## Source

Extracted from `pack/pack/root/uicommon.py` class `QuestionDialog` (line 219+) and matching `pack/pack/uiscript/uiscript/questiondialog.py` (commit-time snapshot). Normalized to current m2ui rules:

- `//` for int division, not `/`
- All callbacks via `SAFE_SetEvent` (this fork defines it; vanilla Metin2 falls back to `ui.__mem_func__()`)
- No lambda capturing `self`
- `OnPressEscapeKey()` returns `True`
- `"style": ("not_pick",)` on the message text widget (decorative — must not swallow clicks meant for buttons)
- Added missing `Initialize()` and `Destroy()` (real source omits them — children leak otherwise)
- Locale strings via `uiScriptLocale.*` (uiscript) and `localeInfo.*` (root class)

## Uiscript dict

```python
import uiScriptLocale

window = {
    "name" : "QuestionDialog",
    "style" : ("movable", "float",),

    "x" : SCREEN_WIDTH // 2 - 125,
    "y" : SCREEN_HEIGHT // 2 - 52,

    "width" : 340,
    "height" : 105,

    "children" :
    (
        {
            "name" : "board",
            "type" : "board",

            "x" : 0,
            "y" : 0,

            "width" : 340,
            "height" : 105,

            "children" :
            (
                {
                    "name" : "message",
                    "type" : "text",
                    "style" : ("not_pick",),

                    "x" : 0,
                    "y" : 38,

                    "horizontal_align" : "center",
                    "text" : uiScriptLocale.MESSAGE,

                    "text_horizontal_align" : "center",
                    "text_vertical_align" : "center",
                },
                {
                    "name" : "accept",
                    "type" : "button",

                    "x" : -40,
                    "y" : 63,

                    "width" : 61,
                    "height" : 21,

                    "horizontal_align" : "center",
                    "text" : uiScriptLocale.YES,

                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },
                {
                    "name" : "cancel",
                    "type" : "button",

                    "x" : 40,
                    "y" : 63,

                    "width" : 61,
                    "height" : 21,

                    "horizontal_align" : "center",
                    "text" : uiScriptLocale.NO,

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
import ui

class QuestionDialog(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.Initialize()
        self.__CreateDialog()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def Initialize(self):
        self.board = None
        self.textLine = None
        self.acceptButton = None
        self.cancelButton = None

    def __CreateDialog(self):
        pyScrLoader = ui.PythonScriptLoader()
        pyScrLoader.LoadScriptFile(self, "uiscript/questiondialog.py")

        self.board = self.GetChild("board")
        self.textLine = self.GetChild("message")
        self.acceptButton = self.GetChild("accept")
        self.cancelButton = self.GetChild("cancel")

    @ui.WindowDestroy
    def Destroy(self):
        self.ClearDictionary()
        self.Initialize()

    def Open(self):
        self.SetCenterPosition()
        self.SetTop()
        self.Show()

    def Close(self):
        self.Hide()

    def SetWidth(self, width):
        height = self.GetHeight()
        self.SetSize(width, height)
        self.board.SetSize(width, height)
        self.SetCenterPosition()
        self.UpdateRect()

    def SetText(self, text):
        self.textLine.SetText(text)

    def SetAcceptText(self, text):
        self.acceptButton.SetText(text)

    def SetCancelText(self, text):
        self.cancelButton.SetText(text)

    def SAFE_SetAcceptEvent(self, event):
        self.acceptButton.SAFE_SetEvent(event)

    def SAFE_SetCancelEvent(self, event):
        self.cancelButton.SAFE_SetEvent(event)

    def SetAcceptEvent(self, event):
        # Caller must wrap event with ui.__mem_func__ or pass a free function.
        # Prefer SAFE_SetAcceptEvent if the fork defines SAFE_SetEvent on Button.
        self.acceptButton.SetEvent(event)

    def SetCancelEvent(self, event):
        self.cancelButton.SetEvent(event)

    def OnPressEscapeKey(self):
        self.Close()
        return True
```

## Locale entries

`QuestionDialog` reuses existing `uiScriptLocale.MESSAGE`, `uiScriptLocale.YES`, `uiScriptLocale.NO`. For your custom dialogs, append the question text to the locale module:

```python
# In locale/<lang>/ui/locale_game.txt or locale_interface.txt
RESET_SKILLS_QUESTION    Are you sure you want to reset your skills?
TRADE_CONFIRM_QUESTION   Are you sure you want to trade?
```

Then access via `localeInfo.RESET_SKILLS_QUESTION` (root class) or via `uiScriptLocale.RESET_SKILLS_QUESTION` (uiscript dict).

## interfacemodule.py integration snippet

Caller-side usage. The window class itself is in `uicommon.py` and reused; no per-feature root class needed:

```python
import uicommon
import localeInfo
import ui

# In your interface or feature class:
def AskResetConfirmation(self):
    self.questionDlg = uicommon.QuestionDialog()
    self.questionDlg.SetText(localeInfo.RESET_SKILLS_QUESTION)
    self.questionDlg.SAFE_SetAcceptEvent(ui.__mem_func__(self.OnConfirmReset))
    self.questionDlg.SAFE_SetCancelEvent(ui.__mem_func__(self.OnCancelReset))
    self.questionDlg.Open()

def OnConfirmReset(self):
    # do the reset
    self.questionDlg.Close()

def OnCancelReset(self):
    self.questionDlg.Close()
```

In `__del__` / cleanup of the owning class:

```python
def __del__(self):
    if self.questionDlg:
        self.questionDlg.Destroy()
        self.questionDlg = None
```

## Common variations

1. **Yes/No instead of OK/Cancel** — already the default (uiScriptLocale.YES / NO). For OK/Cancel, call `SetAcceptText(localeInfo.UI_OK)` and `SetCancelText(localeInfo.UI_CANCEL)` after `Open()`.
2. **Two-line message** — use `uicommon.QuestionDialog2` (uiscript `questiondialog2.py`) which exposes `SetText1` / `SetText2`.
3. **Auto-close after N seconds** — use `uicommon.QuestionDialogWithTimeLimit` (line 302+) which counts down on `OnUpdate`.
4. **Pass extra context to callback** — use the event setter's extra-args feature: `self.acceptButton.SetEvent(ui.__mem_func__(self.OnAccept), itemIndex)`. The trailing arg is delivered to the callback.
5. **Wider dialog for long text** — call `dlg.SetWidth(500)` after `Open()`. Height stays fixed.

## Don't copy these obsolete bits

- Source `__CreateDialog` does NOT call `self.Initialize()` first — ADDED. Without this, `Destroy()` cannot reset cleanly.
- Source has NO `Destroy()` method — ADDED with `@ui.WindowDestroy`. Children leak otherwise.
- Source uiscript uses `SCREEN_WIDTH/2` (Python 2 division) — REPLACED with `SCREEN_WIDTH // 2`.
- Source uiscript message text has no `"style": ("not_pick",)` — ADDED. Decorative text widgets must not swallow clicks (defensive; vanilla text widgets typically don't intercept, but `not_pick` is the explicit guarantee).
- Source `SetAcceptEvent` accepts a bare callable — caller is responsible for wrapping. The DOC string ADDED here makes that explicit. Prefer `SAFE_SetAcceptEvent` if fork has it.
- Source has NO `OnPressEscapeKey` returning explicit `True` in the original-original ymir base class — current rule REQUIRES `return True` always.
