# Anchor 02: Board With Scrollable Dynamic List

## What this is + when to use it

A script-backed window with board chrome (background image/board widget + titlebar), a scrollbar wired to a list of slots, and dynamic-row content populated at runtime via `Refresh()`. Use this when you have N rows of similar items where N varies at runtime (item lists, quest lists, member lists, cube result/material rows). NOT for static layouts where all elements are known at design time (use a flat uiscript dict listing every child). NOT for paginated content (use button-based pagination instead — see `uiprivateshopbuilder.py`).

## Source

Distilled from `pack/pack/root/uicube.py` class `CubeWindow` (line 87+) and `pack/pack/uiscript/uiscript/cubewindow.py` (commit-time snapshot). The real cube code has 5×3 material grids and recipe-specific business logic — this anchor extracts the structural pattern (board + scrollbar + dynamic-row container + slot wiring) without the cube-specific recipe machinery.

Normalized to current m2ui rules:

- `//` for int division, not `/`
- All callbacks via `ui.__mem_func__()` — extra args via the event setter's trailing-args feature, NOT self-capturing lambdas
- `OnPressEscapeKey()` returns `True`
- `"style": ("not_pick",)` on decorative children (titlebar text, board background)
- Added `Initialize()` listing every `self.X` (real source omits — `Destroy` cannot reset cleanly otherwise)
- `Destroy()` decorated with `@ui.WindowDestroy` and calls `ClearDictionary()`
- Locale strings via `uiScriptLocale.*` / `localeInfo.*`

## Uiscript dict

```python
import localeInfo
import uiScriptLocale

window = {
    "name" : "ResultListWindow",

    "x" : SCREEN_WIDTH - 285 - 80,
    "y" : SCREEN_HEIGHT - 521 - 37,

    "style" : ("movable", "float",),

    "width" : 285,
    "height" : 521,

    "children" :
    (
        {
            "name" : "board",
            "type" : "expanded_image",
            "style" : ("attach", "not_pick",),

            "x" : 0,
            "y" : 0,

            "width"  : 285,
            "height" : 521,

            "image"  : uiScriptLocale.LOCALE_UISCRIPT_PATH + "list_window_bg.tga",

            "children" :
            (
                {
                    "name" : "TitleBar",
                    "type" : "titlebar",
                    "style" : ("attach",),

                    "x" : 5,
                    "y" : 5,

                    "width" : 273,
                    "color" : "yellow",

                    "children" :
                    (
                        {
                            "name" : "TitleName",
                            "type" : "text",
                            "style" : ("not_pick",),

                            "x" : 77,
                            "y" : 3,

                            "text" : uiScriptLocale.RESULT_LIST_TITLE,
                            "text_horizontal_align" : "center",
                        },
                    ),
                },

                {
                    "name" : "contentScrollbar",
                    "type" : "thin_scrollbar",

                    "x" : 253,
                    "y" : 38,

                    "size" : 315,
                },

                # Three result-row containers; each row hosts one result slot
                # plus 5 material slots populated at runtime.
                {
                    "name" : "result1board",
                    "type" : "window",

                    "x" : 25,
                    "y" : 41,

                    "width" : 216,
                    "height" : 64,

                    "children" :
                    (
                        {
                            "name" : "result1",
                            "type" : "grid_table",
                            "start_index" : 0,
                            "x_count" : 1,
                            "y_count" : 3,
                            "x_step" : 32,
                            "y_step" : 32,
                            "x" : 0,
                            "y" : 0,
                        },
                        {
                            "name" : "material11",
                            "type" : "grid_table",
                            "start_index" : 0,
                            "x_count" : 1,
                            "y_count" : 3,
                            "x_step" : 32,
                            "y_step" : 32,
                            "x" : 57,
                            "y" : 0,
                        },
                        # ... material12..material15 follow same pattern, x += 33 each ...
                    ),
                },
                # ... result2board, result3board same shape, y offset by 106 each ...

                {
                    "name" : "AcceptButton",
                    "type" : "button",

                    "x" : 148,
                    "y" : 32,
                    "vertical_align" : "bottom",

                    "text" : uiScriptLocale.OK,

                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },
                {
                    "name" : "CancelButton",
                    "type" : "button",

                    "x" : 211,
                    "y" : 32,
                    "vertical_align" : "bottom",

                    "text" : uiScriptLocale.CANCEL,

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
import player
import item
import grp
import localeInfo
import uiScriptLocale


class ResultListWindow(ui.ScriptWindow):

    RESULT_SLOT_COUNT = 3
    MATERIAL_COLS = 5

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.Initialize()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def Initialize(self):
        self.titleBar = None
        self.btnAccept = None
        self.btnCancel = None
        self.contentScrollbar = None
        self.resultSlots = []
        self.materialSlots = []
        self.tooltipItem = None

        self.firstSlotIndex = 0
        self.resultInfos = []           # list of (itemVnum, count)
        self.materialInfos = {}         # {resultIndex: [[(vnum,count), ...], ...]} — 5 cols per row

    def LoadWindow(self):
        try:
            pyScrLoader = ui.PythonScriptLoader()
            pyScrLoader.LoadScriptFile(self, "uiscript/resultlistwindow.py")
        except:
            import exception
            exception.Abort("ResultListWindow.LoadWindow.LoadScript")

        try:
            GetObject = self.GetChild
            self.titleBar = GetObject("TitleBar")
            self.btnAccept = GetObject("AcceptButton")
            self.btnCancel = GetObject("CancelButton")
            self.contentScrollbar = GetObject("contentScrollbar")
            self.resultSlots = [GetObject("result1"), GetObject("result2"), GetObject("result3")]
            self.materialSlots = [
                [GetObject("material1%d" % (col + 1)) for col in xrange(self.MATERIAL_COLS)],
                [GetObject("material2%d" % (col + 1)) for col in xrange(self.MATERIAL_COLS)],
                [GetObject("material3%d" % (col + 1)) for col in xrange(self.MATERIAL_COLS)],
            ]
        except:
            import exception
            exception.Abort("ResultListWindow.LoadWindow.BindObject")

        # Slot event wiring — the per-slot extra args (row, col) are passed via
        # the event setter's trailing-args feature, NOT a self-capturing lambda.
        for row, materialRow in enumerate(self.materialSlots):
            for col, material in enumerate(materialRow):
                material.SetOverInItemEvent(ui.__mem_func__(self.__OverInMaterialSlot), row, col)
                material.SetSelectItemSlotEvent(ui.__mem_func__(self.__OnSelectMaterialSlot), row, col)
                material.SetOverOutItemEvent(ui.__mem_func__(self.__OverOutMaterialSlot))

        for row, resultSlot in enumerate(self.resultSlots):
            resultSlot.SetOverInItemEvent(ui.__mem_func__(self.__OverInResultSlot), row)
            resultSlot.SetOverOutItemEvent(ui.__mem_func__(self.__OverOutMaterialSlot))

        self.contentScrollbar.SetScrollStep(0.15)
        self.contentScrollbar.SetScrollEvent(ui.__mem_func__(self.OnScrollResultList))

        self.titleBar.SetCloseEvent(ui.__mem_func__(self.__OnCloseButtonClick))
        self.btnCancel.SetEvent(ui.__mem_func__(self.__OnCloseButtonClick))
        self.btnAccept.SetEvent(ui.__mem_func__(self.__OnAcceptButtonClick))

    @ui.WindowDestroy
    def Destroy(self):
        self.ClearDictionary()
        self.Initialize()

    def SetItemToolTip(self, itemTooltip):
        self.tooltipItem = itemTooltip

    def Open(self):
        self.firstSlotIndex = 0
        self.Refresh()
        self.Show()

    def Close(self):
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True

    def OnMouseWheel(self, nLen):
        # Delegate to scrollbar so wheel pans the list. Returns True (consumed).
        if self.contentScrollbar:
            self.contentScrollbar.OnMouseWheel(nLen)
        return True

    # --- Dynamic row population ---

    def AddResultItem(self, itemVnum, count):
        self.resultInfos.append((itemVnum, count))

    def AddMaterialInfo(self, resultIndex, colIndex, itemVnum, itemCount):
        if resultIndex not in self.materialInfos:
            self.materialInfos[resultIndex] = [[] for _ in xrange(self.MATERIAL_COLS)]
        self.materialInfos[resultIndex][colIndex].append((itemVnum, itemCount))

    def ClearResults(self):
        self.resultInfos = []
        self.materialInfos = {}
        self.Refresh()

    def GetResultCount(self):
        return len(self.resultInfos)

    def OnScrollResultList(self):
        count = self.GetResultCount()
        scrollLineCount = max(0, count - self.RESULT_SLOT_COUNT)
        startIndex = int(scrollLineCount * self.contentScrollbar.GetPos())

        if startIndex != self.firstSlotIndex:
            self.firstSlotIndex = startIndex
            self.Refresh()

    def Refresh(self):
        # Clear all slots, then re-fill the visible window.
        for resultSlot in self.resultSlots:
            resultSlot.ClearSlot(0)
        for materialRow in self.materialSlots:
            for material in materialRow:
                material.ClearSlot(0)

        for visibleRow in xrange(self.RESULT_SLOT_COUNT):
            absoluteRow = visibleRow + self.firstSlotIndex
            if absoluteRow >= len(self.resultInfos):
                break
            itemVnum, itemCount = self.resultInfos[absoluteRow]
            self.resultSlots[visibleRow].SetItemSlot(0, itemVnum, itemCount)

            if absoluteRow in self.materialInfos:
                for col, materialEntries in enumerate(self.materialInfos[absoluteRow]):
                    if materialEntries:
                        firstVnum, firstCount = materialEntries[0]
                        self.materialSlots[visibleRow][col].SetItemSlot(0, firstVnum, firstCount)

    # --- Slot event handlers ---

    def __OverInResultSlot(self, slotIndex, resultIndex):
        if not self.tooltipItem:
            return
        absoluteIndex = resultIndex + self.firstSlotIndex
        if absoluteIndex >= len(self.resultInfos):
            return
        itemVnum, _ = self.resultInfos[absoluteIndex]
        self.tooltipItem.ClearToolTip()
        self.tooltipItem.AddItemData(itemVnum, [], [])

    def __OverInMaterialSlot(self, slotIndex, resultIndex, colIndex):
        if not self.tooltipItem:
            return
        absoluteIndex = resultIndex + self.firstSlotIndex
        if absoluteIndex not in self.materialInfos:
            return
        self.tooltipItem.ClearToolTip()
        for itemVnum, _ in self.materialInfos[absoluteIndex][colIndex]:
            item.SelectItem(itemVnum)
            self.tooltipItem.AppendTextLine(item.GetItemName(),
                grp.GenerateColor(0.5411, 0.7254, 0.5568, 1.0)).SetFeather()
        self.tooltipItem.Show()

    def __OverOutMaterialSlot(self):
        if self.tooltipItem:
            self.tooltipItem.HideToolTip()

    def __OnSelectMaterialSlot(self, slotIndex, resultIndex, colIndex):
        # Hook for click handling — left empty for the anchor.
        pass

    def __OnAcceptButtonClick(self):
        # Hook for submit logic.
        self.Close()

    def __OnCloseButtonClick(self):
        self.Close()
```

## Locale entries

```python
# In locale/<lang>/ui/locale_game.txt or uiScriptLocale module
RESULT_LIST_TITLE        Result List
RESULT_LIST_REQUIRES     Requires:
```

Plus reuse `uiScriptLocale.OK`, `uiScriptLocale.CANCEL` for the buttons.

## interfacemodule.py integration snippet

```python
import resultlistwindow

# In MakeInterface or __init__:
self.wndResults = resultlistwindow.ResultListWindow()
self.wndResults.LoadWindow()
self.wndResults.SetItemToolTip(self.tooltipItem)

# Populate from net handler / game state:
def RecvResultList(self, payload):
    self.wndResults.ClearResults()
    for entry in payload.results:
        self.wndResults.AddResultItem(entry.vnum, entry.count)
    for resultIdx, mats in enumerate(payload.materials):
        for colIdx, matEntries in enumerate(mats):
            for matVnum, matCount in matEntries:
                self.wndResults.AddMaterialInfo(resultIdx, colIdx, matVnum, matCount)
    self.wndResults.Open()

# In HideAllWindows:
def HideAllWindows(self):
    if self.wndResults:
        self.wndResults.Close()

# In __del__:
def __del__(self):
    if self.wndResults:
        self.wndResults.Destroy()
        self.wndResults = None
```

## Common variations

1. **Replace scrollbar with paginated buttons** — drop `contentScrollbar` from uiscript; add Prev/Next buttons; drive `firstSlotIndex` via button events. See `uiprivateshopbuilder.py` for the pagination pattern.
2. **Add column headers above the viewport** — extra static `text` children in the uiscript above the result rows. Mark them `"style": ("not_pick",)`.
3. **Bind item slots to per-slot tooltips** — already wired here via `SetItemToolTip`. For skill tooltips, use `SetSkillToolTip` and call `SetSkill(skillIndex)` on the tooltip object. See anchor `06-tooltip-bound.md`.
4. **Click headers to sort** — wire `header.SetEvent(ui.__mem_func__(self.SortBy), sortKey)` on each header text widget (use `text` widget with `"style": ("not_pick",)` REMOVED so it can intercept clicks; OR use a transparent button overlay).
5. **Filter via typed input** — add `EditLine` in the uiscript above the viewport; wire its `OnIMEUpdate` to a `Filter(typed_text)` method that subsets `self.resultInfos` and calls `Refresh()`.

## Don't copy these obsolete bits

- Source uses `lambda trash=0, rowIndex=row, col=j: self.__OverInMaterialSlot(trash, rowIndex, col)` — REPLACED with `material.SetOverInItemEvent(ui.__mem_func__(self.__OverInMaterialSlot), row, col)`. The lambda captures `self` by closure (leak); the extra-args feature on the event setter delivers the same args without capturing `self`.
- Source `Destroy()` clears individual `self.X = None` lines instead of calling `Initialize()` — REPLACED with `self.Initialize()`. Keeps the reset list in one place; new instance vars don't drift.
- Source `__init__` does NOT call `Initialize()` — ADDED. Without it, instance vars exist only after `LoadWindow()`, so any pre-load access raises `AttributeError`.
- Source has NO `OnMouseWheel` — ADDED with explicit `return True`. Otherwise wheel events fall through to siblings.
- Source uses `int(slotPos / self.CUBE_SLOT_COUNTX)` (Python 2 division) — REPLACED with `slotPos // self.CUBE_SLOT_COUNTX` where applicable.
- Source `Open()` blindly resets state via assignment instead of calling `ClearResults()` — REPLACED with `firstSlotIndex` reset + explicit `Refresh()`. State cleanup belongs in one helper, not scattered.
