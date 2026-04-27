# Anchor 08: Inventory / Equipment Grid Window

## What this is + when to use it

A window that renders the player's inventory or equipped gear as a 5-column slot grid (inventory) plus fixed-position equipment cells (head/body/weapon/shoes/etc.). The chrome is a board + paginated slot grid (multiple tabs for inventory pages) + equipment-base image with named slot rectangles + gold/cheque field at the bottom. The window pulls data from the `player` C++ Python module (`player.GetItemIndex`, `player.GetItemCount`, `player.GetMainCharacterIndex`, `player.INVENTORY_PAGE_SIZE`).

Use this archetype for: main inventory, equipment loadout, dragon-soul inventory, costume inventory, belt inventory. Do NOT use this for shop slot grids (use anchor `07-shop-exchange`) — different lifecycle, different server-driven refresh path. Do NOT use for storage/safebox (use `12-storage-warehouse`) — needs password / persistence chrome.

Layer augmentor `14-drag-and-drop` for slot↔slot drag (every inventory has drag). Layer `15-network-coupled-flow` for server-driven refresh (`RecvX` packets that touch `player.GetItemIndex`). Layer `16-tabbed-content` for multi-page inventory tabs.

## Source

Pattern extracted from `pack/pack/root/uiinventory.py` and `pack/pack/uiscript/uiscript/inventorywindow.py` from a real Metin2 fork. Real source is 1400+ lines and folds in feature-flagged extensions (cheque slot, dragon-soul button, costume button, belt inventory, accessory combination) — anchor extracts the BASE inventory archetype only. Augmentor and feature-flag wrappers are left to the relevant other anchors (05 for gating, 14 for drag, etc.).

Normalized to current m2ui rules:

- Class-attribute defaults (`questionDialog = None` at class scope) preserved — Python lookup falls through to class when instance attr is absent. Keeps the `if self.X:` guards in Destroy non-AttributeError-y even before `__init__` finishes.
- Added explicit `Initialize()` (real source uses lazy `__LoadWindow` + class defaults; consolidated for clarity)
- All callbacks via `ui.__mem_func__()` (real source already uses this consistently)
- `SetEvent` 2-arg form on `wndChequeSlot.SetEvent(ui.__mem_func__(self.OpenPickMoneyDialog), 1)` — Pattern B verified against `Button.SetEvent(self, event, *args)` in `pack/pack/root/ui.py`. If `Button.SetEvent` is 1-arg in the fork, augment per `framework-augmentations.md` OR fall back to `lambda r=proxy(self): r.OpenPickMoneyDialog(1)`.
- `SAFE_SetEvent` for tab buttons (Pattern E — fork-augmented helper that wraps the bound method idempotently). Anchor uses `SAFE_SetEvent` directly; if the fork doesn't provide it, fall back to `Pattern C` proxy lambda.
- `Destroy()` body preserved — direct method calls on owned dialogs (`self.dlgPickMoney.Destroy()`) wrapped with `if self.X:` (Critical Rule 17)
- `Hide()` calls `tooltipItem.HideToolTip()` to prevent stale tooltip on close
- ASCII-only in code AND inline comments

## Uiscript dict

```python
import uiScriptLocale
import item

EQUIPMENT_START_INDEX = 90

window = {
    "name" : "InventoryWindow",

    "x" : SCREEN_WIDTH - 176 - 200,
    "y" : SCREEN_HEIGHT - 37 - 565,

    "style" : ("movable", "float",),

    "width" : 176,
    "height" : 565,

    "children" :
    (
        {
            "name" : "board",
            "type" : "board",
            "style" : ("attach",),

            "x" : 0,
            "y" : 0,

            "width" : 176,
            "height" : 565,

            "children" :
            (
                ## Title
                {
                    "name" : "TitleBar",
                    "type" : "titlebar",
                    "style" : ("attach",),

                    "x" : 8,
                    "y" : 7,

                    "width" : 161,
                    "color" : "yellow",

                    "children" :
                    (
                        { "name":"TitleName", "type":"text", "x":77, "y":3, "text":uiScriptLocale.INVENTORY_TITLE, "text_horizontal_align":"center" },
                    ),
                },

                ## Equipment area (named slots over a base image)
                {
                    "name" : "Equipment_Base",
                    "type" : "image",

                    "x" : 10,
                    "y" : 33,

                    "image" : "d:/ymir work/ui/game/windows/equipment_base.sub",

                    "children" :
                    (
                        {
                            "name" : "EquipmentSlot",
                            "type" : "slot",

                            "x" : 3,
                            "y" : 3,

                            "width" : 150,
                            "height" : 182,

                            "slot" : (
                                {"index":item.EQUIPMENT_BODY,    "x":39, "y":37,  "width":32, "height":64},
                                {"index":item.EQUIPMENT_HEAD,    "x":39, "y":2,   "width":32, "height":32},
                                {"index":item.EQUIPMENT_SHOES,   "x":39, "y":145, "width":32, "height":32},
                                {"index":item.EQUIPMENT_WRIST,   "x":75, "y":67,  "width":32, "height":32},
                                {"index":item.EQUIPMENT_WEAPON,  "x":3,  "y":3,   "width":32, "height":96},
                                {"index":item.EQUIPMENT_NECK,    "x":114,"y":84,  "width":32, "height":32},
                                {"index":item.EQUIPMENT_EAR,     "x":114,"y":52,  "width":32, "height":32},
                                {"index":item.EQUIPMENT_UNIQUE1, "x":2,  "y":113, "width":32, "height":32},
                                {"index":item.EQUIPMENT_UNIQUE2, "x":75, "y":113, "width":32, "height":32},
                                {"index":item.EQUIPMENT_ARROW,   "x":114,"y":1,   "width":32, "height":32},
                                {"index":item.EQUIPMENT_SHIELD,  "x":75, "y":35,  "width":32, "height":32},
                            ),
                        },
                    ),
                },

                ## Inventory page tab buttons (radio-button group)
                {
                    "name" : "Inventory_Tab_01",
                    "type" : "radio_button",

                    "x" : 10,
                    "y" : 33 + 191,

                    "default_image" : "d:/ymir work/ui/game/windows/tab_button_large_01.sub",
                    "over_image" : "d:/ymir work/ui/game/windows/tab_button_large_02.sub",
                    "down_image" : "d:/ymir work/ui/game/windows/tab_button_large_03.sub",
                    "tooltip_text" : uiScriptLocale.INVENTORY_PAGE_BUTTON_TOOLTIP_1,

                    "children" :
                    (
                        { "name" : "Inventory_Tab_01_Print", "type" : "text", "x" : 0, "y" : 0, "all_align" : "center", "text" : "I" },
                    ),
                },
                {
                    "name" : "Inventory_Tab_02",
                    "type" : "radio_button",

                    "x" : 10 + 78,
                    "y" : 33 + 191,

                    "default_image" : "d:/ymir work/ui/game/windows/tab_button_large_01.sub",
                    "over_image" : "d:/ymir work/ui/game/windows/tab_button_large_02.sub",
                    "down_image" : "d:/ymir work/ui/game/windows/tab_button_large_03.sub",
                    "tooltip_text" : uiScriptLocale.INVENTORY_PAGE_BUTTON_TOOLTIP_2,

                    "children" :
                    (
                        { "name" : "Inventory_Tab_02_Print", "type" : "text", "x" : 0, "y" : 0, "all_align" : "center", "text" : "II" },
                    ),
                },

                ## Item slot grid (5 cols x 9 rows for one inventory page)
                {
                    "name" : "ItemSlot",
                    "type" : "grid_table",

                    "x" : 8,
                    "y" : 246,

                    "start_index" : 0,
                    "x_count" : 5,
                    "y_count" : 9,
                    "x_step" : 32,
                    "y_step" : 32,

                    "image" : "d:/ymir work/ui/public/Slot_Base.sub",
                },

                ## Money slot
                {
                    "name" : "Money_Slot",
                    "type" : "button",

                    "x" : 8,
                    "y" : 28,

                    "horizontal_align" : "center",
                    "vertical_align"   : "bottom",

                    "default_image" : "d:/ymir work/ui/public/parameter_slot_05.sub",
                    "over_image"    : "d:/ymir work/ui/public/parameter_slot_05.sub",
                    "down_image"    : "d:/ymir work/ui/public/parameter_slot_05.sub",

                    "children" :
                    (
                        {
                            "name" : "Money_Icon",
                            "type" : "image",
                            "x" : -18, "y" : 20,
                            "image" : "d:/ymir work/ui/game/windows/money_icon.sub",
                        },
                        {
                            "name" : "Money",
                            "type" : "text",
                            "x" : 3, "y" : 3,
                            "horizontal_align" : "right",
                            "text_horizontal_align" : "right",
                            "text" : "0",
                        },
                    ),
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
import wndMgr
import snd
import net
import mouseModule
import localeInfo
import constInfo
from _weakref import proxy


class InventoryWindow(ui.ScriptWindow):

    # Class defaults — guard reads before __init__ finishes
    questionDialog = None
    tooltipItem = None
    isLoaded = 0

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.Initialize()
        self.__LoadWindow()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def Initialize(self):
        self.inventoryPageIndex = 0
        self.equipmentPageIndex = 0
        self.tooltipItem = None
        self.questionDialog = None
        self.dlgPickMoney = None
        self.wndItem = None
        self.wndEquip = None
        self.wndMoney = None
        self.wndMoneySlot = None
        self.inventoryTab = []
        self.equipmentTab = []
        self.interface = None

    @ui.WindowDestroy
    def Destroy(self):
        self.ClearDictionary()
        if self.dlgPickMoney:
            self.dlgPickMoney.Destroy()
            self.dlgPickMoney = None
        self.Initialize()

    def __LoadWindow(self):
        if self.isLoaded == 1:
            return
        self.isLoaded = 1

        try:
            scriptLoader = ui.PythonScriptLoader()
            scriptLoader.LoadScriptFile(self, "UIScript/InventoryWindow.py")
        except:
            import exception
            exception.Abort("InventoryWindow.LoadWindow.LoadObject")

        try:
            wndItem = self.GetChild("ItemSlot")
            wndEquip = self.GetChild("EquipmentSlot")
            self.GetChild("TitleBar").SetCloseEvent(ui.__mem_func__(self.Close))
            self.wndMoney = self.GetChild("Money")
            self.wndMoneySlot = self.GetChild("Money_Slot")

            self.inventoryTab = []
            for i in xrange(player.INVENTORY_PAGE_COUNT):
                self.inventoryTab.append(self.GetChild("Inventory_Tab_%02d" % (i + 1)))

            self.equipmentTab = []
            self.equipmentTab.append(self.GetChild("Equipment_Tab_01"))
            self.equipmentTab.append(self.GetChild("Equipment_Tab_02"))
        except:
            import exception
            exception.Abort("InventoryWindow.LoadWindow.BindObject")

        # Item slot events (Pattern A — 1-arg setters per ui.py SlotWindow)
        wndItem.SetSelectEmptySlotEvent(ui.__mem_func__(self.SelectEmptySlot))
        wndItem.SetSelectItemSlotEvent(ui.__mem_func__(self.SelectItemSlot))
        wndItem.SetUnselectItemSlotEvent(ui.__mem_func__(self.UseItemSlot))
        wndItem.SetUseSlotEvent(ui.__mem_func__(self.UseItemSlot))
        wndItem.SetOverInItemEvent(ui.__mem_func__(self.OverInItem))
        wndItem.SetOverOutItemEvent(ui.__mem_func__(self.OverOutItem))

        # Equipment slot events (same wiring, separate widget)
        wndEquip.SetSelectEmptySlotEvent(ui.__mem_func__(self.SelectEmptySlot))
        wndEquip.SetSelectItemSlotEvent(ui.__mem_func__(self.SelectItemSlot))
        wndEquip.SetUnselectItemSlotEvent(ui.__mem_func__(self.UseItemSlot))
        wndEquip.SetUseSlotEvent(ui.__mem_func__(self.UseItemSlot))
        wndEquip.SetOverInItemEvent(ui.__mem_func__(self.OverInItem))
        wndEquip.SetOverOutItemEvent(ui.__mem_func__(self.OverOutItem))

        # PickMoney dialog
        dlgPickMoney = uiPickMoney.PickMoneyDialog()
        dlgPickMoney.LoadDialog()
        dlgPickMoney.Hide()

        # Money slot click — Pattern A (no extra args).
        self.wndMoneySlot.SetEvent(ui.__mem_func__(self.OpenPickMoneyDialog))

        # Inventory tab buttons (SAFE_SetEvent = Pattern E with index arg).
        # If fork lacks SAFE_SetEvent, fall back to Pattern C proxy lambda:
        #   self.inventoryTab[i].SetEvent(lambda r=proxy(self), idx=i: r.SetInventoryPage(idx))
        for i in xrange(player.INVENTORY_PAGE_COUNT):
            self.inventoryTab[i].SAFE_SetEvent(self.SetInventoryPage, i)
        self.inventoryTab[0].Down()

        self.equipmentTab[0].SAFE_SetEvent(self.SetEquipmentPage, 0)
        self.equipmentTab[1].SAFE_SetEvent(self.SetEquipmentPage, 1)
        self.equipmentTab[0].Down()
        self.equipmentTab[0].Hide()
        self.equipmentTab[1].Hide()

        self.wndItem = wndItem
        self.wndEquip = wndEquip
        self.dlgPickMoney = dlgPickMoney

        self.SetInventoryPage(0)
        self.SetEquipmentPage(0)
        self.RefreshItemSlot()
        self.RefreshStatus()

    def Show(self):
        self.__LoadWindow()
        ui.ScriptWindow.Show(self)

    def Hide(self):
        if constInfo.GET_ITEM_QUESTION_DIALOG_STATUS():
            self.OnCloseQuestionDialog()
            return
        if self.tooltipItem:
            self.tooltipItem.HideToolTip()
        if self.dlgPickMoney:
            self.dlgPickMoney.Close()
        wndMgr.Hide(self.hWnd)

    def Open(self):
        self.Show()

    def Close(self):
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True

    def OnMouseWheel(self, delta):
        if delta < 0:
            next_page = min(self.inventoryPageIndex + 1, player.INVENTORY_PAGE_COUNT - 1)
            self.SetInventoryPage(next_page)
            self.inventoryTab[next_page].Down()
        else:
            prev_page = max(self.inventoryPageIndex - 1, 0)
            self.SetInventoryPage(prev_page)
            self.inventoryTab[prev_page].Down()
        return True

    def SetInventoryPage(self, page):
        self.inventoryPageIndex = page
        for i in xrange(player.INVENTORY_PAGE_COUNT):
            if i != page:
                self.inventoryTab[i].SetUp()
        self.RefreshBagSlotWindow()

    def SetEquipmentPage(self, page):
        self.equipmentPageIndex = page
        self.equipmentTab[1 - page].SetUp()
        self.RefreshEquipSlotWindow()

    def __InventoryLocalSlotPosToGlobalSlotPos(self, local):
        if player.IsEquipmentSlot(local) or player.IsCostumeSlot(local):
            return local
        return self.inventoryPageIndex * player.INVENTORY_PAGE_SIZE + local

    def RefreshBagSlotWindow(self):
        getItemVNum = player.GetItemIndex
        getItemCount = player.GetItemCount
        setItemVNum = self.wndItem.SetItemSlot

        for i in xrange(player.INVENTORY_PAGE_SIZE):
            slotNumber = self.__InventoryLocalSlotPosToGlobalSlotPos(i)

            itemCount = getItemCount(slotNumber)
            if 0 == itemCount:
                self.wndItem.ClearSlot(i)
                continue
            elif 1 == itemCount:
                itemCount = 0

            itemVnum = getItemVNum(slotNumber)
            setItemVNum(i, itemVnum, itemCount)

        self.wndItem.RefreshSlot()

    def RefreshEquipSlotWindow(self):
        getItemVNum = player.GetItemIndex
        getItemCount = player.GetItemCount
        setItemVNum = self.wndEquip.SetItemSlot

        for i in xrange(player.EQUIPMENT_PAGE_SIZE):
            slotNumber = player.EQUIPMENT_SLOT_START + i
            itemCount = getItemCount(slotNumber)
            if itemCount <= 1:
                itemCount = 0
            setItemVNum(slotNumber, getItemVNum(slotNumber), itemCount)

        self.wndEquip.RefreshSlot()

    def RefreshItemSlot(self):
        self.RefreshBagSlotWindow()
        self.RefreshEquipSlotWindow()

    def RefreshStatus(self):
        money = player.GetElk()
        self.wndMoney.SetText(localeInfo.NumberToMoneyString(money))

    def SetItemToolTip(self, tooltipItem):
        self.tooltipItem = tooltipItem

    def SelectEmptySlot(self, selectedSlotPos):
        if mouseModule.mouseController.isAttached():
            attachedSlotType = mouseModule.mouseController.GetAttachedType()
            attachedSlotPos = mouseModule.mouseController.GetAttachedSlotNumber()
            attachedItemCount = mouseModule.mouseController.GetAttachedItemCount()
            attachedItemIndex = mouseModule.mouseController.GetAttachedItemIndex()
            globalSlotPos = self.__InventoryLocalSlotPosToGlobalSlotPos(selectedSlotPos)

            if player.SLOT_TYPE_INVENTORY == attachedSlotType:
                net.SendItemMovePacket(attachedSlotPos, globalSlotPos, attachedItemCount)
            mouseModule.mouseController.DeattachObject()

    def SelectItemSlot(self, itemSlotIndex):
        # Drag start: attach the slot's item to the cursor and register a
        # drop callback. See augmentor 14-drag-and-drop for the full pattern.
        globalSlotPos = self.__InventoryLocalSlotPosToGlobalSlotPos(itemSlotIndex)
        itemIndex = player.GetItemIndex(globalSlotPos)
        if 0 == itemIndex:
            return

        itemCount = player.GetItemCount(globalSlotPos)
        mouseModule.mouseController.AttachObject(self, player.SLOT_TYPE_INVENTORY, globalSlotPos, itemIndex, itemCount)
        mouseModule.mouseController.SetCallBack("INVENTORY", ui.__mem_func__(self.OnDropToInventory))
        snd.PlaySound("sound/ui/pick.wav")

    def OnDropToInventory(self):
        # Cross-slot move within inventory.
        attachedSlotPos = mouseModule.mouseController.GetAttachedSlotNumber()
        net.SendItemUseToItemPacket(attachedSlotPos, attachedSlotPos)

    def UseItemSlot(self, slotIndex):
        slotIndex = self.__InventoryLocalSlotPosToGlobalSlotPos(slotIndex)
        net.SendItemUsePacket(slotIndex)

    def OverInItem(self, slotIndex):
        slotIndex = self.__InventoryLocalSlotPosToGlobalSlotPos(slotIndex)
        if self.tooltipItem:
            self.tooltipItem.SetInventoryItem(slotIndex)

    def OverOutItem(self):
        if self.tooltipItem:
            self.tooltipItem.HideToolTip()

    def OpenPickMoneyDialog(self):
        if mouseModule.mouseController.isAttached():
            mouseModule.mouseController.DeattachObject()
            return

        curMoney = player.GetElk()
        if curMoney <= 0:
            return

        self.dlgPickMoney.SetTitleName(localeInfo.PICK_MONEY_TITLE)
        self.dlgPickMoney.SetAcceptEvent(ui.__mem_func__(self.OnPickMoney))
        self.dlgPickMoney.Open(curMoney, 0)
        self.dlgPickMoney.SetMax(9)

    def OnPickMoney(self, money, cheque=0):
        mouseModule.mouseController.AttachMoney(self, player.SLOT_TYPE_INVENTORY, money, cheque)

    def OnCloseQuestionDialog(self):
        if not self.questionDialog:
            return
        self.questionDialog.Close()
        self.questionDialog = None
        constInfo.SET_ITEM_QUESTION_DIALOG_STATUS(0)

    def BindInterfaceClass(self, interface):
        from _weakref import proxy as weakproxy
        self.interface = weakproxy(interface)
```

## Locale entries

Append to `locale_interface.txt`:

```
INVENTORY_TITLE	Inventory
INVENTORY_PAGE_BUTTON_TOOLTIP_1	Page 1
INVENTORY_PAGE_BUTTON_TOOLTIP_2	Page 2
PICK_MONEY_TITLE	How much?
```

## interfacemodule.py integration snippet

```python
import uiInventory

class Interface(object):

    def __init__(self):
        # ... unrelated init ...
        self.wndInventory = None

    def MakeInterface(self):
        # ... other window creation ...

        self.wndInventory = uiInventory.InventoryWindow()
        self.wndInventory.SetItemToolTip(self.tooltipItem)
        self.wndInventory.BindInterfaceClass(self)

    def __DestroyDialogs(self):
        # ... other destroys ...
        if self.wndInventory:
            self.wndInventory.Destroy()
            self.wndInventory = None

    def HideAllWindows(self):
        # ... other hides ...
        if self.wndInventory:
            self.wndInventory.Close()

    def ToggleInventoryWindow(self):
        if not self.wndInventory:
            return
        if self.wndInventory.IsShow():
            self.wndInventory.Close()
        else:
            self.wndInventory.Open()

    def RefreshInventory(self):
        # Called from net.py on RecvX packets that touch player.GetItemIndex
        if self.wndInventory:
            self.wndInventory.RefreshItemSlot()
            self.wndInventory.RefreshStatus()
```

## Common variations

1. **Multi-page inventory (3+ pages)** — increase `player.INVENTORY_PAGE_COUNT` (engine binding) and emit additional `Inventory_Tab_NN` widgets in uiscript. The class-side loop `for i in xrange(player.INVENTORY_PAGE_COUNT)` already scales. Layer augmentor `16-tabbed-content` for the radio-group wiring.
2. **Equipment-only window (no inventory grid)** — drop the `ItemSlot` grid_table and `Inventory_Tab_*` radios; keep `Equipment_Base` + `EquipmentSlot`. Class-side: drop `wndItem`, `inventoryTab`, `RefreshBagSlotWindow`. Useful for character sheet preview.
3. **Costume / dragon-soul inventory** — duplicate the archetype with different `player.SLOT_TYPE_*` constants (`SLOT_TYPE_DRAGON_SOUL_INVENTORY` etc.) in `SelectItemSlot` / `OnDropToInventory`. The tooltip uses `tooltipItem.SetXXXSlot` variants instead of `SetInventoryItem`. Layer augmentor `05-feature-gated` (`app.ENABLE_DRAGON_SOUL_SYSTEM`).
4. **Refresh on server packet** — add `RecvX` handler in `net.py` that calls `interface.RefreshInventory()`. The flow is: server mutates inventory → server sends `ItemSet` packet → `net.py` `RecvItemSet` handler calls `player.SetItemData` → handler calls `interface.RefreshInventory()` → `RefreshItemSlot()` walks the grid. Layer augmentor `15-network-coupled-flow` for the full Send/Recv contract.
5. **Auto-potion highlighting** — call `wndItem.ActivateSlot(i)` for slots holding active auto-potions, and `wndItem.DeactivateSlot(i)` for inactive ones (engine renders activated slots with a glow). Layer this in `RefreshBagSlotWindow` based on `constInfo.IS_AUTO_POTION` checks.

## Don't copy these obsolete bits

- Real source uses `self.X = 0` in Destroy for widget refs. Anchor uses `None` in `Initialize()` for consistency.
- Real source has class-attribute defaults like `questionDialog = None` AND instance `self.questionDialog = None` in `__init__`. Anchor consolidates into class-attr only — Python's lookup chain handles both reads and writes correctly.
- Real source `__LoadWindow` is called lazily from `Show()` AND `__init__`. Anchor calls it from `__init__` only — `Show()` is called many times per session, but `isLoaded == 1` short-circuits anyway. Picking one canonical call site reduces confusion. If memory pressure matters (rare), defer construction to first `Show()` and remove from `__init__`.
- Real source has scattered `print` statements (`print("click_mall_button")`, `print("Is Opening Belt Inven??", ...)`). These are fork-debug remnants and should be stripped or replaced with `dbg.TraceError` for production.
- Some forks define `wndItem.SetUnselectItemSlotEvent` to do something different from `SetUseSlotEvent`. Anchor wires both to `UseItemSlot` (engine semantics: unselect = right-click, use = double-click; both fire the use action in canonical Metin2). If your fork distinguishes them, split into `UseItemSlot` and `OnRightClickItem`.
- Real source has `if app.ENABLE_NEW_EQUIPMENT_SYSTEM: self.wndBelt = BeltInventoryWindow(self)`. Anchor strips belt-inventory specifics — those belong in a separate generation pass with `05-feature-gated` layered.
