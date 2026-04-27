# Anchor 10: Paginated Slot Grid Window

## What this is + when to use it

A window for staging items into a slot grid with auxiliary widgets (name input, price input dialog, Ok/Cancel buttons). The chrome is a board + name slot bar + main slot grid (5x8 typical) + Ok/Close buttons. Items arrive via drag-from-inventory (`OnSelectEmptySlot` consumes the attached object) and persist in a per-slot dict (`self.itemStock`) until Ok confirms or Close discards.

Use this archetype for: private-shop builder (player-as-vendor staging), trade-window staging, item-quest submission, any window where the player COMPOSES an item set before committing. Distinct from `07-shop-exchange` (consume vendor's items) and `08-inventory-equipment` (browse player's items) by virtue of the COMPOSITION semantic — the slot grid is empty initially and fills as the player drops items in.

When the staged set spans more slots than fit on one page, layer pagination as documented in section 7 variation 1 — `__pageIndex` instance var, Prev/Next buttons, page-state preserved across close/reopen. The base archetype is single-page; pagination is a layered swap.

Layer augmentor `14-drag-and-drop` for the drag-in/drag-out wiring (`SelectEmptySlot` consumes attached object, `SelectItemSlot` removes). Layer `15-network-coupled-flow` for the `Ok` → `net.Send*Packet` confirmation flow.

## Source

Pattern extracted from `pack/pack/root/uiprivateshopbuilder.py` and `pack/pack/uiscript/uiscript/privateshopbuilder.py` from a real Metin2 fork. Real source has a `MoneyInputDialog` opened on each `OnSelectEmptySlot` (price-per-item input) — anchor preserves this since pricing-on-attach is the canonical staging flow.

Normalized to current m2ui rules:

- Added explicit `__Initialize()` (real source uses inline `__init__` resets)
- All callbacks via `ui.__mem_func__()` (real source already uses this)
- Replaced `self.itemStock.has_key(i)` with `i in self.itemStock` (Critical Rule 14 — py2/py3 portable)
- `Destroy()` body preserved with `self.priceInputBoard = None` reset (priceInputBoard is the only owned dialog; the engine will Hide it via WOC if visible)
- Stripped `print` debug statements (real source has commented-out prints in `__init__`/`__del__`)
- ASCII-only

## Uiscript dict

```python
import uiScriptLocale

window = {
    "name" : "PrivateShopBuilder",

    "x" : 0,
    "y" : 0,

    "style" : ("movable", "float",),

    "width" : 184,
    "height" : 354,

    "children" :
    (
        {
            "name" : "board",
            "type" : "board",
            "style" : ("attach",),

            "x" : 0,
            "y" : 0,

            "width" : 184,
            "height" : 354,

            "children" :
            (
                ## Title
                {
                    "name" : "TitleBar",
                    "type" : "titlebar",
                    "style" : ("attach",),

                    "x" : 8,
                    "y" : 8,

                    "width" : 169,
                    "color" : "gray",

                    "children" :
                    (
                        { "name":"TitleName", "type":"text", "x":84, "y":4, "text":uiScriptLocale.PRIVATE_SHOP_TITLE, "text_horizontal_align":"center" },
                    ),
                },

                ## Name slot (display-only here; can be made editable via EditLine)
                {
                    "name" : "NameSlot",
                    "type" : "slotbar",
                    "x" : 13,
                    "y" : 35,
                    "width" : 157,
                    "height" : 18,

                    "children" :
                    (
                        {
                            "name" : "NameLine",
                            "type" : "text",
                            "x" : 3,
                            "y" : 3,
                            "width" : 157,
                            "height" : 15,
                            "input_limit" : 25,
                            "text" : "",
                        },
                    ),
                },

                ## Item Slot grid
                {
                    "name" : "ItemSlot",
                    "type" : "grid_table",

                    "x" : 12,
                    "y" : 60,

                    "start_index" : 0,
                    "x_count" : 5,
                    "y_count" : 8,
                    "x_step" : 32,
                    "y_step" : 32,

                    "image" : "d:/ymir work/ui/public/Slot_Base.sub",
                },

                ## Ok
                {
                    "name" : "OkButton",
                    "type" : "button",

                    "x" : 21,
                    "y" : 321,

                    "width" : 61,
                    "height" : 21,

                    "text" : uiScriptLocale.OK,

                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image"    : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image"    : "d:/ymir work/ui/public/middle_button_03.sub",
                },

                ## Close
                {
                    "name" : "CloseButton",
                    "type" : "button",

                    "x" : 104,
                    "y" : 321,

                    "width" : 61,
                    "height" : 21,

                    "text" : uiScriptLocale.CLOSE,

                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image"    : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image"    : "d:/ymir work/ui/public/middle_button_03.sub",
                },
            ),
        },
    ),
}
```

## Root class

```python
import ui
import net
import player
import item
import shop
import snd
import chat
import app
import mouseModule
import uiCommon
import localeInfo
from _weakref import proxy


g_isBuildingPrivateShop = False


def IsBuildingPrivateShop():
    return g_isBuildingPrivateShop


class PrivateShopBuilder(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.__Initialize()
        self.__LoadWindow()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def __Initialize(self):
        self.itemStock = {}
        self.tooltipItem = None
        self.priceInputBoard = None
        self.title = ""
        self.nameLine = None
        self.itemSlot = None
        self.btnOk = None
        self.btnClose = None
        self.titleBar = None

    @ui.WindowDestroy
    def Destroy(self):
        self.ClearDictionary()
        if self.priceInputBoard:
            self.priceInputBoard.Close()
        self.__Initialize()

    def __LoadWindow(self):
        try:
            scriptLoader = ui.PythonScriptLoader()
            scriptLoader.LoadScriptFile(self, "UIScript/PrivateShopBuilder.py")
        except:
            import exception
            exception.Abort("PrivateShopBuilder.LoadWindow.LoadObject")

        try:
            GetObject = self.GetChild
            self.nameLine = GetObject("NameLine")
            self.itemSlot = GetObject("ItemSlot")
            self.btnOk = GetObject("OkButton")
            self.btnClose = GetObject("CloseButton")
            self.titleBar = GetObject("TitleBar")
        except:
            import exception
            exception.Abort("PrivateShopBuilder.LoadWindow.BindObject")

        self.btnOk.SetEvent(ui.__mem_func__(self.OnOk))
        self.btnClose.SetEvent(ui.__mem_func__(self.OnClose))
        self.titleBar.SetCloseEvent(ui.__mem_func__(self.OnClose))

        self.itemSlot.SetSelectEmptySlotEvent(ui.__mem_func__(self.OnSelectEmptySlot))
        self.itemSlot.SetSelectItemSlotEvent(ui.__mem_func__(self.OnSelectItemSlot))
        self.itemSlot.SetOverInItemEvent(ui.__mem_func__(self.OnOverInItem))
        self.itemSlot.SetOverOutItemEvent(ui.__mem_func__(self.OnOverOutItem))

    def Open(self, title):
        self.title = title

        if len(title) > 25:
            title = title[:22] + "..."

        self.itemStock = {}
        shop.ClearPrivateShopStock()
        self.nameLine.SetText(title)
        self.SetCenterPosition()
        self.Refresh()
        self.Show()

        global g_isBuildingPrivateShop
        g_isBuildingPrivateShop = True

    def Close(self):
        global g_isBuildingPrivateShop
        g_isBuildingPrivateShop = False

        self.title = ""
        self.itemStock = {}
        shop.ClearPrivateShopStock()
        self.Hide()

    def OnClose(self):
        self.Close()
        return True

    def OnPressEscapeKey(self):
        self.Close()
        return True

    def SetItemToolTip(self, tooltipItem):
        self.tooltipItem = tooltipItem

    def Refresh(self):
        getItemVNum = player.GetItemIndex
        getItemCount = player.GetItemCount
        setItemVNum = self.itemSlot.SetItemSlot
        clearSlot = self.itemSlot.ClearSlot

        for i in xrange(shop.SHOP_SLOT_COUNT):
            if i not in self.itemStock:
                clearSlot(i)
                continue

            pos = self.itemStock[i]
            itemCount = getItemCount(*pos)
            if itemCount <= 1:
                itemCount = 0
            setItemVNum(i, getItemVNum(*pos), itemCount)

        self.itemSlot.RefreshSlot()

    def OnSelectEmptySlot(self, selectedSlotPos):
        # Drag-in: consume the attached object and open price input dialog.
        if not mouseModule.mouseController.isAttached():
            return

        attachedSlotType = mouseModule.mouseController.GetAttachedType()
        attachedSlotPos = mouseModule.mouseController.GetAttachedSlotNumber()
        mouseModule.mouseController.DeattachObject()

        if attachedSlotType not in (player.SLOT_TYPE_INVENTORY, player.SLOT_TYPE_DRAGON_SOUL_INVENTORY):
            return

        attachedInvenType = player.SlotTypeToInvenType(attachedSlotType)
        itemVNum = player.GetItemIndex(attachedInvenType, attachedSlotPos)
        item.SelectItem(itemVNum)

        if item.IsAntiFlag(item.ANTIFLAG_GIVE) or item.IsAntiFlag(item.ANTIFLAG_MYSHOP):
            chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.PRIVATE_SHOP_CANNOT_SELL_ITEM)
            return

        priceInputBoard = uiCommon.MoneyInputDialog()
        priceInputBoard.SetTitle(localeInfo.PRIVATE_SHOP_INPUT_PRICE_DIALOG_TITLE)
        priceInputBoard.SetAcceptEvent(ui.__mem_func__(self.AcceptInputPrice))
        priceInputBoard.SetCancelEvent(ui.__mem_func__(self.CancelInputPrice))
        priceInputBoard.Open()

        self.priceInputBoard = priceInputBoard
        self.priceInputBoard.itemVNum = itemVNum
        self.priceInputBoard.sourceWindowType = attachedInvenType
        self.priceInputBoard.sourceSlotPos = attachedSlotPos
        self.priceInputBoard.targetSlotPos = selectedSlotPos

    def OnSelectItemSlot(self, selectedSlotPos):
        # Click on a staged slot — remove from stock.
        if mouseModule.mouseController.isAttached():
            snd.PlaySound("sound/ui/loginfail.wav")
            mouseModule.mouseController.DeattachObject()
            return

        if selectedSlotPos not in self.itemStock:
            return

        invenType, invenPos = self.itemStock[selectedSlotPos]
        shop.DelPrivateShopItemStock(invenType, invenPos)
        snd.PlaySound("sound/ui/drop.wav")

        del self.itemStock[selectedSlotPos]
        self.Refresh()

    def AcceptInputPrice(self):
        if not self.priceInputBoard:
            return True

        text = self.priceInputBoard.GetText()
        if not text or not text.isdigit():
            return True

        price = int(text)
        if price <= 0:
            return True

        attachedInvenType = self.priceInputBoard.sourceWindowType
        sourceSlotPos = self.priceInputBoard.sourceSlotPos
        targetSlotPos = self.priceInputBoard.targetSlotPos

        # Replace any prior staging of this same source slot.
        for privatePos, (itemWindowType, itemSlotIndex) in list(self.itemStock.items()):
            if itemWindowType == attachedInvenType and itemSlotIndex == sourceSlotPos:
                shop.DelPrivateShopItemStock(itemWindowType, itemSlotIndex)
                del self.itemStock[privatePos]

        shop.AddPrivateShopItemStock(attachedInvenType, sourceSlotPos, targetSlotPos, price)
        self.itemStock[targetSlotPos] = (attachedInvenType, sourceSlotPos)
        snd.PlaySound("sound/ui/drop.wav")

        self.Refresh()
        self.priceInputBoard = None
        return True

    def CancelInputPrice(self):
        self.priceInputBoard = None
        return True

    def OnOk(self):
        if not self.title:
            return
        if 0 == len(self.itemStock):
            return
        # Send to server: title + staged items.
        net.SendBuildPrivateShopPacket(self.title)
        self.Close()

    def OnOverInItem(self, slotIndex):
        if not self.tooltipItem:
            return
        if slotIndex in self.itemStock:
            invenType, invenPos = self.itemStock[slotIndex]
            self.tooltipItem.SetInventoryItem(invenPos, invenType)

    def OnOverOutItem(self):
        if self.tooltipItem:
            self.tooltipItem.HideToolTip()
```

## Locale entries

Append to `locale_interface.txt`:

```
PRIVATE_SHOP_TITLE	Set up Shop
PRIVATE_SHOP_INPUT_PRICE_DIALOG_TITLE	Item Price
OK	OK
CLOSE	Close
```

Append to `locale_game.txt`:

```
PRIVATE_SHOP_CANNOT_SELL_ITEM	This item cannot be sold in your private shop.
```

## interfacemodule.py integration snippet

```python
import uiPrivateShopBuilder

class Interface(object):

    def __init__(self):
        self.privateShopBuilder = None

    def MakeInterface(self):
        # ... other window creation ...
        # PrivateShopBuilder is constructed lazily on first /buildshop command
        # to save startup memory. See integration.md Variation 2.
        pass

    def __DestroyDialogs(self):
        if self.privateShopBuilder:
            self.privateShopBuilder.Destroy()
            self.privateShopBuilder = None

    def HideAllWindows(self):
        if self.privateShopBuilder:
            self.privateShopBuilder.Close()

    def OpenPrivateShopBuilderDialog(self, title):
        if not self.privateShopBuilder:
            self.privateShopBuilder = uiPrivateShopBuilder.PrivateShopBuilder()
            self.privateShopBuilder.SetItemToolTip(self.tooltipItem)
        self.privateShopBuilder.Open(title)
```

In `net.py` (server-driven open):

```python
def OnPrivateShopBuilderOpen(title):
    interface = GetInterface()
    if interface:
        interface.OpenPrivateShopBuilderDialog(title)
```

## Common variations

1. **True pagination** (multi-page slot grid) — add Prev/Next buttons to uiscript and a `self.__pageIndex` instance var. `Refresh()` walks `range(__pageIndex * SLOTS_PER_PAGE, (__pageIndex+1) * SLOTS_PER_PAGE)` instead of all slots; the slot grid itself stays at 5x8 with `i % SLOTS_PER_PAGE` as the local index. Persist `__pageIndex` across close/reopen by NOT resetting in `Close()` (real source clears `itemStock` on Close — pagination should preserve that too if the shop persists).
2. **Editable name field** — replace the `text` widget inside `NameSlot` with an `EditLine`. Class side: `self.nameLine.SetReturnEvent(ui.__mem_func__(self.OnEnterName))`. EditLine `SetReturnEvent` is 1-arg per `ui.py`; verify before extra-arg use.
3. **No price input** (gift-staging window) — drop the `priceInputBoard` chain. `OnSelectEmptySlot` calls `shop.AddPrivateShopItemStock(attachedInvenType, sourceSlotPos, selectedSlotPos, 0)` directly with price=0. Useful for trade-staging windows where price is determined by the receiving party.
4. **Cheque (secondary currency)** — add `getTextCheque()` calls and `SetValueCheque()` on the price dialog; pass both `price` and `chequep` to `shop.AddPrivateShopItemStock`. Layer augmentor `05-feature-gated` (`app.ENABLE_CHEQUE_SYSTEM`).
5. **Per-slot price tag rendering** — wrap each grid slot with a price text overlay showing `localeInfo.NumberToMoneyString(price)`. The overlay is a `text` widget child of `ItemSlot`; reposition on Refresh per slot's `__GetSlotPosition(i)` calculation. Adds visual price feedback.

## Don't copy these obsolete bits

- Real source uses `self.itemStock.has_key(i)` (Python 2 only). Anchor uses `i in self.itemStock` (portable per Critical Rule 14).
- Real source has commented-out `print` statements in `__init__` and `__del__`. Strip — use `dbg.TraceError` for production logging.
- Real source `Refresh()` iterates with `getitemVNum=player.GetItemIndex` shadowing — anchor preserves the local-binding optimization (it IS measurably faster for tight inner loops that call C++ bindings).
- Real source `priceInputBoard` is set on `self` directly with attribute injection (`self.priceInputBoard.itemVNum = itemVNum`). This works but is fragile — if the dialog is recycled, prior attributes leak. Consider a structured holder: `self.pendingItem = {"vnum": itemVNum, "src": (attachedInvenType, attachedSlotPos), "tgt": selectedSlotPos}` instead.
- Real source has separate `cheque`/`text` parsing branches inside `AcceptInputPrice`. Anchor strips the cheque branch — handle that as a `05-feature-gated` layer to keep the base anchor lean.
- Real source `Destroy()` body sets `self.X = None` for each widget ref directly (no `__Initialize()` call). Anchor consolidates into `self.__Initialize()` — single source of truth for default values, matches the pattern used in 02 and 03.
