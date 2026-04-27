# Anchor 07: Shop / Exchange / Trade Window

## What this is + when to use it

A window for buying, selling, or exchanging items between the player and either an NPC vendor or another player. The chrome is a board + slot grid (typically 5 columns x 8 rows) + Buy/Sell toggle buttons + (optional) tab radio-buttons + (in private/exchange variants) a gold field + Accept/Close buttons. The window is server-driven — buy/sell calls `net.SendShopBuyPacket` / `net.SendShopSellPacketNew` and the server responds by mutating the shop slots; refresh hooks pull from the `shop` C++ Python module.

Use this archetype for: NPC shops, player-to-player exchanges, mall pages with item lists, private shops (player-as-vendor), guild stores. Do NOT use this for storage/safebox windows (use anchor `12-storage-warehouse` instead — different password/persistence chrome). Do NOT use this for crafting/refining (use anchor `13-craft-refine-window` — different result-preview chrome).

Layer augmentor `14-drag-and-drop` on top when the player drags items from inventory onto a shop slot to sell, or from a shop slot back into inventory to buy. Layer `15-network-coupled-flow` on top to document the Send/Recv/refresh contract.

## Source

Pattern extracted from `pack/pack/root/uishop.py` and `pack/pack/uiscript/uiscript/shopdialog.py` from a real Metin2 fork (also cross-checks `pack/pack/root/uiexchange.py` for the player-to-player exchange variant). Real source has both NPC-shop and private-shop modes in one class branched by `player.IsMainCharacterIndex(vid)`. Anchor consolidates the NPC-shop path (the more common case); private-shop differences called out in section 7 variations.

Normalized to current m2ui rules:

- Added explicit `Initialize()` method (real source scatters resets across `__init__` and `Destroy`)
- All callbacks verified per `event-binding.md` matrix:
  - `SAFE_SetButtonEvent("LEFT", "EMPTY", self.SelectEmptySlot)` — Pattern E (3-arg setter form, fork-augmented; falls back to Pattern A if absent)
  - `SetOverInItemEvent`/`SetOverOutItemEvent`/`SetToggleUpEvent`/`SetToggleDownEvent`/`SetEvent`/`SetCloseEvent` — all wrapped via `ui.__mem_func__`
  - Tab callbacks via `lambda argSelf=proxy(self): argSelf.OnClickTabButton(N)` (Pattern C with proxy)
  - `SetCallBack("INVENTORY", ui.__mem_func__(self.DropToInventory))` — drag drop callback (Pattern A; SetCallBack signature confirmed 2-arg in `mouseModule.mouseController`)
- Pattern B verified for `grid_table.SetOverInItemEvent` and `grid_table.SetOverOutItemEvent` against `pack/pack/root/ui.py` — both 1-arg setters, so no extra-arg form is emitted
- `OnPressEscapeKey()` returns `True`
- `Destroy()` body preserved with `if self.X:` guards on owned-widget refs
- Asset paths verified against `D:\ymir work\ui\` — `Slot_Base.sub`, `middle_button_01.sub`, `large_button_01.sub`, `small_button_01.sub` exist
- Locale keys generic uppercase (`SHOP_TITLE`, `SHOP_BUY`, `DO_YOU_BUY_ITEM`, etc.)
- ASCII-only in code AND comments

## Uiscript dict

```python
import uiScriptLocale

window = {
    "name" : "ShopDialog",

    "x" : SCREEN_WIDTH - 400,
    "y" : 10,

    "style" : ("movable", "float",),

    "width" : 184,
    "height" : 328,

    "children" :
    (
        {
            "name" : "board",
            "type" : "board",
            "style" : ("attach",),

            "x" : 0,
            "y" : 0,

            "width" : 184,
            "height" : 328,

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
                        { "name":"TitleName", "type":"text", "x":84, "y":4, "text":uiScriptLocale.SHOP_TITLE, "text_horizontal_align":"center" },
                    ),
                },

                ## Item Slot
                {
                    "name" : "ItemSlot",
                    "type" : "grid_table",

                    "x" : 12,
                    "y" : 34,

                    "start_index" : 0,
                    "x_count" : 5,
                    "y_count" : 8,
                    "x_step" : 32,
                    "y_step" : 32,

                    "image" : "d:/ymir work/ui/public/Slot_Base.sub",
                },

                ## Buy
                {
                    "name" : "BuyButton",
                    "type" : "toggle_button",

                    "x" : 21,
                    "y" : 295,

                    "width" : 61,
                    "height" : 21,

                    "text" : uiScriptLocale.SHOP_BUY,

                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },

                ## Sell
                {
                    "name" : "SellButton",
                    "type" : "toggle_button",

                    "x" : 104,
                    "y" : 295,

                    "width" : 61,
                    "height" : 21,

                    "text" : uiScriptLocale.SHOP_SELL,

                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },

                ## Close (private-shop variant; hidden in NPC-shop mode)
                {
                    "name" : "CloseButton",
                    "type" : "button",

                    "x" : 0,
                    "y" : 295,

                    "horizontal_align" : "center",

                    "text" : uiScriptLocale.PRIVATE_SHOP_CLOSE_BUTTON,

                    "default_image" : "d:/ymir work/ui/public/large_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/large_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/large_button_03.sub",
                },

                ## Tab radio-buttons (shown when shop has 2 or 3 tabs)
                {
                    "name" : "MiddleTab1",
                    "type" : "radio_button",
                    "x" : 21, "y" : 295,
                    "width" : 61, "height" : 21,
                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },
                {
                    "name" : "MiddleTab2",
                    "type" : "radio_button",
                    "x" : 104, "y" : 295,
                    "width" : 61, "height" : 21,
                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },
                {
                    "name" : "SmallTab1",
                    "type" : "radio_button",
                    "x" : 21, "y" : 295,
                    "width" : 43, "height" : 21,
                    "default_image" : "d:/ymir work/ui/public/small_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/small_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/small_button_03.sub",
                },
                {
                    "name" : "SmallTab2",
                    "type" : "radio_button",
                    "x" : 71, "y" : 295,
                    "width" : 43, "height" : 21,
                    "default_image" : "d:/ymir work/ui/public/small_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/small_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/small_button_03.sub",
                },
                {
                    "name" : "SmallTab3",
                    "type" : "radio_button",
                    "x" : 120, "y" : 295,
                    "width" : 43, "height" : 21,
                    "default_image" : "d:/ymir work/ui/public/small_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/small_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/small_button_03.sub",
                },
            ),
        },
    ),
}
```

## Root class

```python
import net
import player
import item
import snd
import shop
import wndMgr
import app
import chat

import ui
import uiCommon
import mouseModule
import localeInfo
import constInfo
from _weakref import proxy


class ShopDialog(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.Initialize()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def Initialize(self):
        self.tooltipItem = 0
        self.itemSlotWindow = None
        self.btnBuy = None
        self.btnSell = None
        self.btnClose = None
        self.titleBar = None
        self.smallRadioButtonGroup = None
        self.middleRadioButtonGroup = None
        self.questionDialog = None
        self.popup = None
        self.itemBuyQuestionDialog = None
        self.tabIdx = 0
        self.coinType = 0
        self.xShopStart = 0
        self.yShopStart = 0

    @ui.WindowDestroy
    def Destroy(self):
        self.ClearDictionary()
        if self.questionDialog:
            self.questionDialog.Close()
        if self.popup:
            self.popup.Close()
        if self.itemBuyQuestionDialog:
            self.itemBuyQuestionDialog.Close()
        self.Initialize()

    def __GetRealIndex(self, i):
        return self.tabIdx * shop.SHOP_SLOT_COUNT + i

    def Refresh(self):
        getItemID = shop.GetItemID
        getItemCount = shop.GetItemCount
        setItemID = self.itemSlotWindow.SetItemSlot
        for i in xrange(shop.SHOP_SLOT_COUNT):
            idx = self.__GetRealIndex(i)
            itemCount = getItemCount(idx)
            if itemCount <= 1:
                itemCount = 0
            setItemID(i, getItemID(idx), itemCount)

        wndMgr.RefreshSlot(self.itemSlotWindow.GetWindowHandle())

    def LoadDialog(self):
        try:
            scriptLoader = ui.PythonScriptLoader()
            scriptLoader.LoadScriptFile(self, "UIScript/shopdialog.py")
        except:
            import exception
            exception.Abort("ShopDialog.LoadDialog.LoadObject")

        try:
            GetObject = self.GetChild
            self.itemSlotWindow = GetObject("ItemSlot")
            self.btnBuy = GetObject("BuyButton")
            self.btnSell = GetObject("SellButton")
            self.btnClose = GetObject("CloseButton")
            self.titleBar = GetObject("TitleBar")
            middleTab1 = GetObject("MiddleTab1")
            middleTab2 = GetObject("MiddleTab2")
            smallTab1 = GetObject("SmallTab1")
            smallTab2 = GetObject("SmallTab2")
            smallTab3 = GetObject("SmallTab3")
        except:
            import exception
            exception.Abort("ShopDialog.LoadDialog.BindObject")

        self.itemSlotWindow.SetSlotStyle(wndMgr.SLOT_STYLE_NONE)
        # SAFE_SetButtonEvent is a fork helper that wraps the bound method
        # idempotently (proxy-cached). Equivalent: SlotWindow.SetButtonEvent
        # with a Pattern C lambda. See event-binding.md Pattern E.
        self.itemSlotWindow.SAFE_SetButtonEvent("LEFT", "EMPTY", self.SelectEmptySlot)
        self.itemSlotWindow.SAFE_SetButtonEvent("LEFT", "EXIST", self.SelectItemSlot)
        self.itemSlotWindow.SAFE_SetButtonEvent("RIGHT", "EXIST", self.UnselectItemSlot)

        self.itemSlotWindow.SetOverInItemEvent(ui.__mem_func__(self.OverInItem))
        self.itemSlotWindow.SetOverOutItemEvent(ui.__mem_func__(self.OverOutItem))

        self.btnBuy.SetToggleUpEvent(ui.__mem_func__(self.CancelShopping))
        self.btnBuy.SetToggleDownEvent(ui.__mem_func__(self.OnBuy))

        self.btnSell.SetToggleUpEvent(ui.__mem_func__(self.CancelShopping))
        self.btnSell.SetToggleDownEvent(ui.__mem_func__(self.OnSell))

        self.btnClose.SetEvent(ui.__mem_func__(self.AskClosePrivateShop))

        self.titleBar.SetCloseEvent(ui.__mem_func__(self.Close))

        # Tab callbacks use Pattern C (proxy lambda) to bind the tab index.
        # ui.__mem_func__ does NOT support extra args without ui.py augmentation.
        self.smallRadioButtonGroup = ui.RadioButtonGroup.Create([
            [smallTab1, lambda argSelf=proxy(self): argSelf.OnClickTabButton(0), None],
            [smallTab2, lambda argSelf=proxy(self): argSelf.OnClickTabButton(1), None],
            [smallTab3, lambda argSelf=proxy(self): argSelf.OnClickTabButton(2), None],
        ])
        self.middleRadioButtonGroup = ui.RadioButtonGroup.Create([
            [middleTab1, lambda argSelf=proxy(self): argSelf.OnClickTabButton(0), None],
            [middleTab2, lambda argSelf=proxy(self): argSelf.OnClickTabButton(1), None],
        ])

        self.__HideMiddleTabs()
        self.__HideSmallTabs()

        self.tabIdx = 0
        self.coinType = shop.SHOP_COIN_TYPE_GOLD

        self.Refresh()

    def __ShowBuySellButton(self):
        self.btnBuy.Show()
        self.btnSell.Show()

    def __HideBuySellButton(self):
        self.btnBuy.Hide()
        self.btnSell.Hide()

    def __ShowMiddleTabs(self):
        if self.middleRadioButtonGroup:
            self.middleRadioButtonGroup.Show()

    def __HideMiddleTabs(self):
        if self.middleRadioButtonGroup:
            self.middleRadioButtonGroup.Hide()

    def __ShowSmallTabs(self):
        if self.smallRadioButtonGroup:
            self.smallRadioButtonGroup.Show()

    def __HideSmallTabs(self):
        if self.smallRadioButtonGroup:
            self.smallRadioButtonGroup.Hide()

    def __SetTabNames(self):
        if shop.GetTabCount() == 2:
            self.middleRadioButtonGroup.SetText(0, shop.GetTabName(0))
            self.middleRadioButtonGroup.SetText(1, shop.GetTabName(1))
        elif shop.GetTabCount() == 3:
            for i in xrange(3):
                self.smallRadioButtonGroup.SetText(i, shop.GetTabName(i))

    def Open(self, vid):
        import chr
        isPrivateShop = not chr.IsNPC(vid)
        isMainPlayerPrivateShop = player.IsMainCharacterIndex(vid)

        if isMainPlayerPrivateShop:
            self.btnBuy.Hide()
            self.btnSell.Hide()
            self.btnClose.Show()
        else:
            self.btnBuy.Show()
            self.btnSell.Show()
            self.btnClose.Hide()

        shop.Open(isPrivateShop, isMainPlayerPrivateShop)

        self.tabIdx = 0

        if isPrivateShop:
            self.__HideMiddleTabs()
            self.__HideSmallTabs()
        else:
            tabCount = shop.GetTabCount()
            if tabCount == 1:
                self.__ShowBuySellButton()
                self.__HideMiddleTabs()
                self.__HideSmallTabs()
            elif tabCount == 2:
                self.__HideBuySellButton()
                self.__ShowMiddleTabs()
                self.__HideSmallTabs()
                self.__SetTabNames()
                self.middleRadioButtonGroup.OnClick(0)
            elif tabCount == 3:
                self.__HideBuySellButton()
                self.__HideMiddleTabs()
                self.__ShowSmallTabs()
                self.__SetTabNames()
                self.smallRadioButtonGroup.OnClick(0)

        self.Refresh()
        self.SetTop()
        self.Show()

        (self.xShopStart, self.yShopStart, z) = player.GetMainCharacterPosition()

    def Close(self):
        if self.itemBuyQuestionDialog:
            self.itemBuyQuestionDialog.Close()
            self.itemBuyQuestionDialog = None
            constInfo.SET_ITEM_QUESTION_DIALOG_STATUS(0)
        if self.questionDialog:
            self.OnCloseQuestionDialog()
        shop.Close()
        net.SendShopEndPacket()
        self.CancelShopping()
        if self.tooltipItem:
            self.tooltipItem.HideToolTip()
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True

    def OnPressExitKey(self):
        self.Close()
        return True

    def OnClickTabButton(self, idx):
        self.tabIdx = idx
        self.Refresh()

    def OnBuy(self):
        chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.SHOP_BUY_INFO)
        app.SetCursor(app.BUY)
        self.btnSell.SetUp()

    def OnSell(self):
        chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.SHOP_SELL_INFO)
        app.SetCursor(app.SELL)
        self.btnBuy.SetUp()

    def CancelShopping(self):
        self.btnBuy.SetUp()
        self.btnSell.SetUp()
        app.SetCursor(app.NORMAL)

    def AskClosePrivateShop(self):
        questionDialog = uiCommon.QuestionDialog()
        questionDialog.SetText(localeInfo.PRIVATE_SHOP_CLOSE_QUESTION)
        questionDialog.SetAcceptEvent(ui.__mem_func__(self.OnClosePrivateShop))
        questionDialog.SetCancelEvent(ui.__mem_func__(self.OnCloseQuestionDialog))
        questionDialog.Open()
        self.questionDialog = questionDialog
        constInfo.SET_ITEM_QUESTION_DIALOG_STATUS(1)
        return True

    def OnClosePrivateShop(self):
        net.SendChatPacket("/close_shop")
        self.OnCloseQuestionDialog()
        return True

    def OnCloseQuestionDialog(self):
        if not self.questionDialog:
            return
        self.questionDialog.Close()
        self.questionDialog = None
        constInfo.SET_ITEM_QUESTION_DIALOG_STATUS(0)

    def SelectEmptySlot(self, selectedSlotPos):
        if mouseModule.mouseController.isAttached():
            self.SellAttachedItem()

    def UnselectItemSlot(self, selectedSlotPos):
        if constInfo.GET_ITEM_QUESTION_DIALOG_STATUS() == 1:
            return
        if shop.IsPrivateShop():
            self.AskBuyItem(selectedSlotPos)
        else:
            net.SendShopBuyPacket(self.__GetRealIndex(selectedSlotPos))

    def SelectItemSlot(self, selectedSlotPos):
        if constInfo.GET_ITEM_QUESTION_DIALOG_STATUS() == 1:
            return

        isAttached = mouseModule.mouseController.isAttached()
        selectedSlotPos = self.__GetRealIndex(selectedSlotPos)

        if isAttached:
            self.SellAttachedItem()
            return

        if shop.IsMainPlayerPrivateShop():
            return

        curCursorNum = app.GetCursor()
        if app.BUY == curCursorNum:
            self.AskBuyItem(selectedSlotPos)
        elif app.SELL == curCursorNum:
            chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.SHOP_SELL_INFO)
        else:
            selectedItemID = shop.GetItemID(selectedSlotPos)
            itemCount = shop.GetItemCount(selectedSlotPos)
            slotType = player.SLOT_TYPE_SHOP
            if shop.IsPrivateShop():
                slotType = player.SLOT_TYPE_PRIVATE_SHOP
            mouseModule.mouseController.AttachObject(self, slotType, selectedSlotPos, selectedItemID, itemCount)
            mouseModule.mouseController.SetCallBack("INVENTORY", ui.__mem_func__(self.DropToInventory))
            snd.PlaySound("sound/ui/pick.wav")

    def DropToInventory(self):
        attachedSlotPos = mouseModule.mouseController.GetAttachedSlotNumber()
        self.AskBuyItem(attachedSlotPos)

    def SellAttachedItem(self):
        if shop.IsPrivateShop():
            mouseModule.mouseController.DeattachObject()
            return

        attachedSlotType = mouseModule.mouseController.GetAttachedType()
        attachedSlotPos = mouseModule.mouseController.GetAttachedSlotNumber()
        attachedCount = mouseModule.mouseController.GetAttachedItemCount()
        attachedItemIndex = mouseModule.mouseController.GetAttachedItemIndex()

        if attachedSlotType not in (player.SLOT_TYPE_INVENTORY, player.SLOT_TYPE_DRAGON_SOUL_INVENTORY):
            snd.PlaySound("sound/ui/loginfail.wav")
            mouseModule.mouseController.DeattachObject()
            return

        item.SelectItem(attachedItemIndex)

        if item.IsAntiFlag(item.ANTIFLAG_SELL):
            popup = uiCommon.PopupDialog()
            popup.SetText(localeInfo.SHOP_CANNOT_SELL_ITEM)
            popup.SetAcceptEvent(ui.__mem_func__(self.__OnClosePopupDialog))
            popup.Open()
            self.popup = popup
            mouseModule.mouseController.DeattachObject()
            return

        itemtype = player.INVENTORY
        if player.SLOT_TYPE_DRAGON_SOUL_INVENTORY == attachedSlotType:
            itemtype = player.DRAGON_SOUL_INVENTORY

        if player.IsValuableItem(itemtype, attachedSlotPos):
            itemPrice = item.GetISellItemPrice()
            if item.Is1GoldItem():
                itemPrice = attachedCount // itemPrice
            else:
                itemPrice = itemPrice * max(1, attachedCount)
            if not app.ENABLE_NO_SELL_PRICE_DIVIDED_BY_5:
                itemPrice //= 5

            itemName = item.GetItemName()
            questionDialog = uiCommon.QuestionDialog()
            questionDialog.SetText(localeInfo.DO_YOU_SELL_ITEM(itemName, attachedCount, itemPrice))
            questionDialog.SetAcceptEvent(lambda a=attachedSlotPos, b=attachedCount, c=itemtype, r=proxy(self): r.OnSellItem(a, b, c))
            questionDialog.SetCancelEvent(ui.__mem_func__(self.OnCloseQuestionDialog))
            questionDialog.Open()
            self.questionDialog = questionDialog
            constInfo.SET_ITEM_QUESTION_DIALOG_STATUS(1)
        else:
            self.OnSellItem(attachedSlotPos, attachedCount, itemtype)

        mouseModule.mouseController.DeattachObject()

    def OnSellItem(self, slotPos, count, itemtype):
        net.SendShopSellPacketNew(slotPos, count, itemtype)
        snd.PlaySound("sound/ui/money.wav")
        self.OnCloseQuestionDialog()

    def __OnClosePopupDialog(self):
        self.popup = None
        constInfo.SET_ITEM_QUESTION_DIALOG_STATUS(0)

    def AskBuyItem(self, slotPos):
        slotPos = self.__GetRealIndex(slotPos)
        itemIndex = shop.GetItemID(slotPos)
        itemPrice = shop.GetItemPrice(slotPos)
        itemCount = shop.GetItemCount(slotPos)

        item.SelectItem(itemIndex)
        itemName = item.GetItemName()

        itemBuyQuestionDialog = uiCommon.QuestionDialog()
        itemBuyQuestionDialog.SetText(localeInfo.DO_YOU_BUY_ITEM(itemName, itemCount, localeInfo.NumberToMoneyString(itemPrice)))
        itemBuyQuestionDialog.SetAcceptEvent(lambda r=proxy(self): r.AnswerBuyItem(True))
        itemBuyQuestionDialog.SetCancelEvent(lambda r=proxy(self): r.AnswerBuyItem(False))
        itemBuyQuestionDialog.Open()
        itemBuyQuestionDialog.pos = slotPos
        self.itemBuyQuestionDialog = itemBuyQuestionDialog
        constInfo.SET_ITEM_QUESTION_DIALOG_STATUS(1)

    def AnswerBuyItem(self, flag):
        if flag:
            pos = self.itemBuyQuestionDialog.pos
            net.SendShopBuyPacket(pos)
        if self.itemBuyQuestionDialog:
            self.itemBuyQuestionDialog.Close()
            self.itemBuyQuestionDialog = None
        constInfo.SET_ITEM_QUESTION_DIALOG_STATUS(0)

    def SetItemToolTip(self, tooltipItem):
        self.tooltipItem = tooltipItem

    def OverInItem(self, slotIndex):
        slotIndex = self.__GetRealIndex(slotIndex)
        if mouseModule.mouseController.isAttached():
            return
        if 0 != self.tooltipItem:
            if shop.SHOP_COIN_TYPE_GOLD == shop.GetTabCoinType(self.tabIdx):
                self.tooltipItem.SetShopItem(slotIndex)
            else:
                self.tooltipItem.SetShopItemBySecondaryCoin(slotIndex)

    def OverOutItem(self):
        if 0 != self.tooltipItem:
            self.tooltipItem.HideToolTip()

    def OnUpdate(self):
        # Auto-close when player walks away from NPC.
        USE_SHOP_LIMIT_RANGE = 1000
        (x, y, z) = player.GetMainCharacterPosition()
        if abs(x - self.xShopStart) > USE_SHOP_LIMIT_RANGE or abs(y - self.yShopStart) > USE_SHOP_LIMIT_RANGE:
            self.Close()
```

## Locale entries

Append to `locale_interface.txt`:

```
SHOP_TITLE	Shop
SHOP_BUY	Buy
SHOP_SELL	Sell
PRIVATE_SHOP_CLOSE_BUTTON	Close
```

Append to `locale_game.txt`:

```
SHOP_BUY_INFO	Click an item in the shop to buy it.
SHOP_SELL_INFO	Click an item in your inventory to sell it.
SHOP_CANNOT_SELL_ITEM	You cannot sell this item.
PRIVATE_SHOP_CLOSE_QUESTION	Are you sure you want to close your private shop?
```

`DO_YOU_BUY_ITEM` and `DO_YOU_SELL_ITEM` are formatter helpers in `localeInfo.py` (callable: `localeInfo.DO_YOU_BUY_ITEM(name, count, price_string)`); they typically already exist. Confirm via grep before adding.

## interfacemodule.py integration snippet

```python
import uiShop

class Interface(object):

    def __init__(self):
        # ... unrelated init ...
        self.dlgShop = None

    def MakeInterface(self):
        # ... other window creation ...

        self.dlgShop = uiShop.ShopDialog()
        self.dlgShop.LoadDialog()
        self.dlgShop.SetItemToolTip(self.tooltipItem)

    def __DestroyDialogs(self):
        # ... other destroys ...
        if self.dlgShop:
            self.dlgShop.Destroy()
            self.dlgShop = None

    def HideAllWindows(self):
        # ... other hides ...
        if self.dlgShop:
            self.dlgShop.Close()

    def OpenShopDialog(self, vid):
        # Server triggers this via OnShop / OnShopBuy callbacks in net.py
        if self.dlgShop:
            self.dlgShop.Open(vid)
```

In `net.py` (server-driven open):

```python
def OnShop():
    interface = GetInterface()  # or however the fork accesses interface
    if interface:
        vid = shop.GetVID()  # or similar — confirm shop binding
        interface.OpenShopDialog(vid)
```

## Common variations

1. **Player-to-player exchange** — replace `ShopDialog` with an `ExchangeDialog` class (see `pack/pack/root/uiexchange.py` for the parallel structure). Differences: two slot grids (mine + partner's), gold input fields on both sides, shared Accept button (engine pairs accept signals across both clients), no Buy/Sell toggle. Same lifecycle (`Open(vid)`, `Close`), same callback wrapping. Cross-link to `15-network-coupled-flow` — exchange flows through `net.SendExchangeStart` / `net.SendExchangeAccept` / `RecvExchange*`.
2. **Mall page** (web-embedded) — replace the slot grid with an `app.ShowWebPage(url, rect)` call in `Open()` and `app.HideWebPage()` in `Close()`. The shop chrome (board + close button) stays. Uiscript dict drops the `ItemSlot` widget. Use this when items are sold via an external HTTP backend (cash shop) rather than the `shop` Python module.
3. **Cheque (secondary currency) shop** — wrap price-formatting in `if app.ENABLE_CHEQUE_SYSTEM:` and switch between `localeInfo.DO_YOU_BUY_ITEM_CHEQUE_SIN_YANG` (cheque-only), `DO_YOU_BUY_ITEM` (gold-only), and `DO_YOU_BUY_ITEM_YANG_CHEQUE` (mixed) based on `shop.GetItemPrice(slotPos)` vs `shop.GetItemCheque(slotPos)`. Layer augmentor `05-feature-gated` over this anchor when the entire window is gated by the cheque flag.
4. **Read-only shop browsing** — for showing a vendor's wares without allowing buy (e.g., a preview window), keep `__ShowBuySellButton` always-hidden, drop `SAFE_SetButtonEvent` registrations, and remove `Net.SendShopBuyPacket` from `UnselectItemSlot`. The slot tooltip still works (`OverInItem` / `tooltipItem.SetShopItem`).
5. **Private-shop variant only** (player-as-vendor) — keep `Open(vid)` but force `isMainPlayerPrivateShop = True` early; show `btnClose`, hide `btnBuy`/`btnSell`. The `AskClosePrivateShop` confirmation dialog routes to `net.SendChatPacket("/close_shop")`.

## Don't copy these obsolete bits

- Some forks set `self.tooltipItem = 0` (integer) and check `if 0 != self.tooltipItem:` in OverInItem. The integer-0 sentinel is legacy; modern code uses `None` and checks `if self.tooltipItem:`. Anchor preserves `0` for compatibility with `SetShopItem` C++ binding which tolerates it; if rewriting from scratch, prefer `None`.
- Some forks bind `SAFE_SetButtonEvent` AND `SetSelectItemSlotEvent` for the same slot — duplicate registration. Only one is needed; pick `SAFE_SetButtonEvent` if the fork provides it (handles LEFT/RIGHT and EMPTY/EXIST in one call), otherwise use the four individual setters (`SetSelectItemSlotEvent`, `SetUnselectItemSlotEvent`, `SetSelectEmptySlotEvent`, `SetUseSlotEvent`).
- Real source has `import net` twice at the top (lines 1 and 6). Anchor strips duplicate.
- Real source uses `itemPrice /= 5` (integer division in py2 with int operands). Anchor uses `//=` for explicit Py2/Py3-portable integer division per Critical Rule 14.
- Some forks omit the `OnUpdate` distance-check entirely; the shop stays open until the user manually closes. Anchor includes the auto-close because every NPC interaction in canonical Metin2 should respect the engagement-range invariant. If fork-policy says NPC shops persist across map changes, drop `OnUpdate`.
- Real source's `Destroy` body resets attrs to `0` for some widgets (`self.itemSlotWindow = 0`). Anchor uses `None` for consistency with `Initialize()` defaults — picking-bound widget refs should be `None` when not held.
- Real source has `# @fixme002` style internal-tracking comments. Anchor strips these — they reference fork-internal review tags and have no value in a generic anchor.
