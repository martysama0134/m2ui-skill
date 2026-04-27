# Anchor 13: Craft / Refine / Item-Enhancement Window

## What this is + when to use it

A dialog for upgrading or transforming items: weapon refining (with success-rate display + Yang cost + Stone material), cube/dragon-soul refining (multiple input slots → one result), item-enhancement (level-up scrolls), socket-attaching, attribute-changing. The chrome is a board (auto-sized to content) + result-preview tooltip (live `ItemToolTip` embedded inside the dialog) + cost text + success-percentage text + Accept/Cancel buttons + (optional) material-slot rows appended dynamically below the result.

Use this archetype for: weapon refining, cube renewal, dragon-soul refining, attribute changing, socket-attaching, any window where the player commits ONE input → ONE OR MORE materials → ONE result preview before pressing Accept. Distinct from `07-shop-exchange` (slot grid, multiple items in one transaction) and `10-paginated-slot-grid` (composing a STAGED set, not a transformation).

Layer augmentor `14-drag-and-drop` for material-insertion via drag (some refine flows accept dragged materials). Layer `15-network-coupled-flow` for the canonical Send → Recv → close flow (`net.SendRefinePacket` → server validates → response → UI close + chat message).

## Source

Pattern extracted from `pack/pack/root/uirefine.py` (the `RefineDialogNew` class — modern replacement for the `RefineDialog` legacy class) and `pack/pack/uiscript/uiscript/refinedialog.py` from a real Metin2 fork. Real source has both `RefineDialog` (legacy, scroll+target items only) and `RefineDialogNew` (modern, supports multiple materials, percentage display, type-driven warning text). Anchor uses the modern variant.

Cross-references `pack/pack/root/uicube.py` for the cube-refine variant (multiple input slots) — covered in section 7 variation 3.

Normalized to current m2ui rules:

- `__Initialize()` (real source has it; preserved)
- All callbacks via `ui.__mem_func__()` (real source uses this)
- `Destroy()` body preserved with `if self.X:` guards (real source assigns `0` to widget refs; anchor uses `None`)
- The `self.children = []` list pattern collects dynamically-created widgets (slot, item-image, thin-board) so they don't get GC'd before Destroy. Real source uses this; anchor preserves.
- Type-coded refine path (`self.type` selects between weapon/armor/accessory warning text) — real source dispatches in `OpenQuestionDialog`; anchor preserves
- ASCII-only

## Uiscript dict

```python
import uiScriptLocale

window = {
    "name" : "RefineDialog",
    "style" : ("movable", "float",),

    "x" : SCREEN_WIDTH - 400,
    "y" : 70,

    "width"  : 0,
    "height" : 0,

    "children" :
    (
        {
            "name" : "Board",
            "type" : "board",
            "style" : ("attach",),

            "x" : 0,
            "y" : 0,

            "width"  : 0,
            "height" : 0,

            "children" :
            (
                {
                    "name" : "TitleBar",
                    "type" : "titlebar",
                    "style" : ("attach",),

                    "x" : 8,
                    "y" : 8,

                    "width" : 0,
                    "color" : "red",

                    "children" :
                    (
                        {
                            "name" : "TitleName",
                            "type" : "text",
                            "text" : uiScriptLocale.REFINE_TTILE,
                            "horizontal_align"      : "center",
                            "text_horizontal_align" : "center",
                            "x" : 0,
                            "y" : 3,
                        },
                    ),
                },
                {
                    "name" : "SuccessPercentage",
                    "type" : "text",
                    "text" : uiScriptLocale.REFINE_INFO,
                    "horizontal_align"      : "center",
                    "vertical_align"        : "bottom",
                    "text_horizontal_align" : "center",
                    "x" : 0,
                    "y" : 70,
                },
                {
                    "name" : "Cost",
                    "type" : "text",
                    "text" : uiScriptLocale.REFINE_COST,
                    "horizontal_align"      : "center",
                    "vertical_align"        : "bottom",
                    "text_horizontal_align" : "center",
                    "x" : 0,
                    "y" : 54,
                },
                {
                    "name" : "AcceptButton",
                    "type" : "button",

                    "x" : -35,
                    "y" : 35,

                    "text" : uiScriptLocale.OK,
                    "horizontal_align" : "center",
                    "vertical_align"   : "bottom",

                    "default_image" : "d:/ymir work/ui/public/Middle_Button_01.sub",
                    "over_image"    : "d:/ymir work/ui/public/Middle_Button_02.sub",
                    "down_image"    : "d:/ymir work/ui/public/Middle_Button_03.sub",
                },
                {
                    "name" : "CancelButton",
                    "type" : "button",

                    "x" : 35,
                    "y" : 35,

                    "text" : uiScriptLocale.CANCEL,
                    "horizontal_align" : "center",
                    "vertical_align"   : "bottom",

                    "default_image" : "d:/ymir work/ui/public/Middle_Button_01.sub",
                    "over_image"    : "d:/ymir work/ui/public/Middle_Button_02.sub",
                    "down_image"    : "d:/ymir work/ui/public/Middle_Button_03.sub",
                },
            ),
        },
    ),
}
```

The dialog dimensions (`width: 0, height: 0`) are intentional — `UpdateDialog()` resizes at runtime based on the embedded tooltip's content. The auto-resize pattern is canonical for refine-style windows.

## Root class

```python
import ui
import net
import player
import item
import uiToolTip
import uiCommon
import localeInfo
import constInfo


class RefineDialog(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.__Initialize()
        self.isLoaded = False

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def __Initialize(self):
        self.dlgQuestion = None
        self.children = []
        self.vnum = 0
        self.targetItemPos = 0
        self.dialogHeight = 0
        self.cost = 0
        self.percentage = 0
        self.type = 0
        self.board = None
        self.titleBar = None
        self.probText = None
        self.costText = None
        self.successPercentage = None
        self.toolTip = None
        self.itemImage = None
        self.slotList = []

    @ui.WindowDestroy
    def Destroy(self):
        self.ClearDictionary()
        if self.dlgQuestion:
            self.dlgQuestion.Close()
        self.__Initialize()

    def __LoadScript(self):
        try:
            scriptLoader = ui.PythonScriptLoader()
            scriptLoader.LoadScriptFile(self, "uiscript/refinedialog.py")
        except:
            import exception
            exception.Abort("RefineDialog.__LoadScript.LoadObject")

        try:
            self.board = self.GetChild("Board")
            self.titleBar = self.GetChild("TitleBar")
            self.probText = self.GetChild("SuccessPercentage")
            self.costText = self.GetChild("Cost")
            self.successPercentage = self.GetChild("SuccessPercentage")
            self.GetChild("AcceptButton").SetEvent(ui.__mem_func__(self.OpenQuestionDialog))
            self.GetChild("CancelButton").SetEvent(ui.__mem_func__(self.CancelRefine))
        except:
            import exception
            exception.Abort("RefineDialog.__LoadScript.BindObject")

        if constInfo.ENABLE_REFINE_PCT:
            self.successPercentage.Show()
        else:
            self.successPercentage.Hide()

        # Embedded tooltip — renders the result-item preview live inside the dialog.
        toolTip = uiToolTip.ItemToolTip()
        toolTip.SetParent(self)
        toolTip.SetFollow(False)
        toolTip.SetPosition(15, 38)
        toolTip.Show()
        self.toolTip = toolTip

        # Pre-allocate result-icon slots (max 3 rows of slot art).
        self.slotList = []
        for i in xrange(3):
            slot = self.__MakeSlot()
            slot.SetParent(toolTip)
            slot.SetWindowVerticalAlignCenter()
            self.slotList.append(slot)

        itemImage = self.__MakeItemImage()
        itemImage.SetParent(toolTip)
        itemImage.SetWindowVerticalAlignCenter()
        itemImage.SetPosition(-35, 0)
        self.itemImage = itemImage

        self.titleBar.SetCloseEvent(ui.__mem_func__(self.CancelRefine))
        self.isLoaded = True

    def __MakeSlot(self):
        slot = ui.ImageBox()
        slot.LoadImage("d:/ymir work/ui/public/slot_base.sub")
        slot.Show()
        self.children.append(slot)
        return slot

    def __MakeItemImage(self):
        itemImage = ui.ImageBox()
        itemImage.Show()
        self.children.append(itemImage)
        return itemImage

    def __MakeThinBoard(self):
        thinBoard = ui.ThinBoard()
        thinBoard.SetParent(self)
        thinBoard.Show()
        self.children.append(thinBoard)
        return thinBoard

    def Open(self, targetItemPos, nextGradeItemVnum, cost, prob, refineType):
        if not self.isLoaded:
            self.__LoadScript()

        # Reset per-open state but keep loaded chrome.
        self.children = [c for c in self.children if c is self.toolTip or c is self.itemImage or c in self.slotList]
        self.targetItemPos = targetItemPos
        self.vnum = nextGradeItemVnum
        self.cost = cost
        self.percentage = prob
        self.type = refineType
        self.dialogHeight = 0

        self.probText.SetText(localeInfo.REFINE_SUCCESS_PROBALITY % self.percentage)
        self.costText.SetText(localeInfo.REFINE_COST % self.cost)

        self.toolTip.ClearToolTip()
        metinSlot = []
        for i in xrange(player.METIN_SOCKET_MAX_NUM):
            metinSlot.append(player.GetItemMetinSocket(targetItemPos, i))

        attrSlot = []
        for i in xrange(player.ATTRIBUTE_SLOT_MAX_NUM):
            attrSlot.append(player.GetItemAttribute(targetItemPos, i))
        self.toolTip.AddRefineItemData(nextGradeItemVnum, metinSlot, attrSlot)

        item.SelectItem(nextGradeItemVnum)
        self.itemImage.LoadImage(item.GetIconImageFileName())
        xSlotCount, ySlotCount = item.GetItemSize()
        for slot in self.slotList:
            slot.Hide()
        for i in xrange(min(3, ySlotCount)):
            self.slotList[i].SetPosition(-35, i * 32 - (ySlotCount - 1) * 16)
            self.slotList[i].Show()

        self.dialogHeight = self.toolTip.GetHeight() + 46
        self.UpdateDialog()

        self.SetTop()
        self.Show()

    def Close(self):
        self.dlgQuestion = None
        self.Hide()

    def AppendMaterial(self, vnum, count):
        # Add a "X x N" material row below the result preview.
        slot = self.__MakeSlot()
        slot.SetParent(self)
        slot.SetPosition(15, self.dialogHeight)

        itemImage = self.__MakeItemImage()
        itemImage.SetParent(slot)
        item.SelectItem(vnum)
        itemImage.LoadImage(item.GetIconImageFileName())

        thinBoard = self.__MakeThinBoard()
        thinBoard.SetPosition(50, self.dialogHeight)
        thinBoard.SetSize(191, 20)

        textLine = ui.TextLine()
        textLine.SetParent(thinBoard)
        textLine.SetFontName(localeInfo.UI_DEF_FONT)
        textLine.SetPackedFontColor(0xffdddddd)
        textLine.SetText("%s x %02d" % (item.GetItemName(), count))
        textLine.SetOutline()
        textLine.SetFeather(False)
        textLine.SetWindowVerticalAlignCenter()
        textLine.SetVerticalAlignCenter()
        textLine.SetPosition(15, 0)
        textLine.Show()
        self.children.append(textLine)

        self.dialogHeight += 34
        self.UpdateDialog()

    def UpdateDialog(self):
        newWidth = self.toolTip.GetWidth() + 60
        newHeight = self.dialogHeight + 75 - 8  # -8 trim per source

        self.board.SetSize(newWidth, newHeight)
        self.toolTip.SetPosition(15 + 35, 38)
        self.titleBar.SetWidth(newWidth - 15)
        self.SetSize(newWidth, newHeight)

        (x, y) = self.GetLocalPosition()
        self.SetPosition(x, y)

    def OpenQuestionDialog(self):
        if 100 == self.percentage:
            self.Accept()
            return
        # Type 5 = no-warning instant accept (e.g., free re-roll)
        if 5 == self.type:
            self.Accept()
            return

        dlgQuestion = uiCommon.QuestionDialog2()
        dlgQuestion.SetText2(localeInfo.REFINE_WARNING2)
        dlgQuestion.SetAcceptEvent(ui.__mem_func__(self.Accept))
        dlgQuestion.SetCancelEvent(ui.__mem_func__(dlgQuestion.Close))

        # Type-driven warning text — different refine flows have different
        # consequences (destroy on fail, downgrade, etc.).
        if 3 == self.type:
            dlgQuestion.SetText1(localeInfo.REFINE_DESTROY_WARNING_WITH_BONUS_PERCENT_1)
            dlgQuestion.SetText2(localeInfo.REFINE_DESTROY_WARNING_WITH_BONUS_PERCENT_2)
        elif 2 == self.type:
            dlgQuestion.SetText1(localeInfo.REFINE_DOWN_GRADE_WARNING)
        else:
            dlgQuestion.SetText1(localeInfo.REFINE_DESTROY_WARNING)

        dlgQuestion.Open()
        self.dlgQuestion = dlgQuestion

    def Accept(self):
        net.SendRefinePacket(self.targetItemPos, self.type)
        self.Close()

    def CancelRefine(self):
        # Server expects an explicit cancel (sentinel 255).
        net.SendRefinePacket(255, 255)
        self.Close()

    def OnPressEscapeKey(self):
        self.CancelRefine()
        return True
```

## Locale entries

Append to `locale_interface.txt`:

```
REFINE_TTILE	Refine
OK	OK
CANCEL	Cancel
```

`REFINE_INFO`, `REFINE_COST`, `REFINE_SUCCESS_PROBALITY`, `REFINE_DESTROY_WARNING`, `REFINE_DESTROY_WARNING_WITH_BONUS_PERCENT_1/2`, `REFINE_DOWN_GRADE_WARNING`, `REFINE_WARNING2` are formatter helpers in `localeInfo.py` (callable with format-string arguments). Confirm these exist via grep before adding new ones.

Append to `locale_game.txt`:

```
REFINE_INFO	Success rate: %s%%
REFINE_COST	Cost: %s Yang
REFINE_SUCCESS_PROBALITY	Success rate: %d%%
REFINE_DESTROY_WARNING	If refining fails, the item will be destroyed.
REFINE_WARNING2	Are you sure?
REFINE_DOWN_GRADE_WARNING	If refining fails, the item will be downgraded.
```

(Format strings — exact wording varies per fork. Adjust to match your locale's voice.)

## interfacemodule.py integration snippet

```python
import uiRefine

class Interface(object):

    def __init__(self):
        self.refineDialog = None

    def MakeInterface(self):
        # ... other window creation ...
        # Refine dialogs are constructed eagerly at startup; the embedded
        # ItemToolTip needs Init time to set up font cache.
        self.refineDialog = uiRefine.RefineDialog()

    def __DestroyDialogs(self):
        if self.refineDialog:
            self.refineDialog.Destroy()
            self.refineDialog = None

    def HideAllWindows(self):
        if self.refineDialog:
            self.refineDialog.Close()

    def OpenRefineDialog(self, targetItemPos, nextGradeItemVnum, cost, prob, refineType):
        # net.py RecvRefineInformation calls this.
        if self.refineDialog:
            self.refineDialog.Open(targetItemPos, nextGradeItemVnum, cost, prob, refineType)

    def AppendMaterialToRefineDialog(self, vnum, count):
        # net.py RecvRefineInformation appends each material slot.
        if self.refineDialog:
            self.refineDialog.AppendMaterial(vnum, count)
```

In `net.py`:

```python
def OnRefineInformation(targetItemPos, nextGradeItemVnum, cost, prob, refineType, materials):
    interface = GetInterface()
    if not interface:
        return
    interface.OpenRefineDialog(targetItemPos, nextGradeItemVnum, cost, prob, refineType)
    for vnum, count in materials:
        interface.AppendMaterialToRefineDialog(vnum, count)
```

## Common variations

1. **Cube renewal** (multi-input → one result) — replace the single `targetItemPos` with a list of input slots. Uiscript adds an input-slot grid (typically 6-9 slots in a 3-col grid). `Open()` takes a `inputSlots` list; `Accept()` sends `net.SendCubePacket(inputSlots)`. Result-preview tooltip same as refine. See `pack/pack/root/uicube.py` for the full pattern.
2. **Dragon-soul refine** — three input slots in a triangular layout (representative of the three soul fragments). Result is the upgraded soul. Same auto-resize tooltip + cost + percentage. Layer augmentor `05-feature-gated` (`app.ENABLE_DRAGON_SOUL_SYSTEM`).
3. **Free-cost refine** (no cost text, no warning dialog) — drop `costText` from uiscript, drop the `OpenQuestionDialog` Accept-skip logic. Useful for quest-completion windows that present a refine UI without the destruction warnings.
4. **Drag-in material insertion** — instead of a server-pushed material list, accept dragged items into a material slot. Layer augmentor `14-drag-and-drop` and add `OnSelectEmptySlot` handlers on the material slots that consume `mouseModule.mouseController.GetAttachedItemIndex()`. Useful for socket-attachment dialogs.
5. **Result-preview without tooltip** — for refines where the result is a flat icon (no stats), drop the `uiToolTip.ItemToolTip` and use a plain `ui.ImageBox` with `item.GetIconImageFileName(nextGradeItemVnum)`. Smaller dialog, faster open. Suitable for cosmetic-only refines.

## Don't copy these obsolete bits

- Real source has both `RefineDialog` (legacy class) and `RefineDialogNew`. Anchor uses the modern variant only — discard the legacy class.
- Real source uses `RefineDialogNew.__Initialize` to clear `self.children = []` on Open. Anchor preserves this pattern but adds protection: keep refs to permanently-allocated chrome (toolTip, itemImage, slotList) across Opens. Without protection, the chrome's parent reference gets cleared and the next Open re-creates it, leaking the prior allocation.
- Real source has commented `##if 936 == app.GetDefaultCodePage(): newHeight -= 8` (CJK font fix). Anchor unconditionally subtracts 8 — the height fix matches CJK fonts but is harmless on Western locales (board is sized to content + chrome).
- Real source has `if localeInfo.IsARABIC(): self.board.SetPosition(newWidth, 0)` (RTL flip). Anchor strips this — locale-specific layout flips belong in the locale module, not in every window. If your fork supports RTL, layer the position-flip in a locale wrapper.
- Real source assigns `0` to widget refs in `Destroy` (`self.board = 0`). Anchor uses `None` consistently with `Initialize()` defaults (matches `08-inventory-equipment` etc.).
- Real source has typo `REFINE_TTILE` (TT instead of TL). Anchor preserves the typo for compatibility — locale files reference `uiScriptLocale.REFINE_TTILE` so renaming requires touching every locale file. If renaming, rename atomically across uiscript + class + locale_interface + locale_game.
