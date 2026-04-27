# Anchor 12: Storage / Warehouse / Mall Window

## What this is + when to use it

A persistent slot grid for items the player stores OUTSIDE their inventory — bank/safebox, item-mall delivery box, dragon-soul refine storage. The chrome is a board + programmatically-created `GridSlotWindow` (sized to fit `safebox.SAFEBOX_PAGE_SIZE` per page) + page-radio buttons (typically 3 pages max) + Change Password button + Exit/Close button + (rarely) gold field. Password protection is canonical — the player enters a 4-digit password BEFORE the safebox opens; password modal is `01-simple-dialog`-shaped.

Use this archetype for: bank/safebox, item-mall delivery, account-shared storage, dragon-soul fragment storage. Distinct from `08-inventory-equipment` (player's per-character inventory; no password, attached to character) and `07-shop-exchange` (transient buy/sell; not persistent).

Layer augmentor `14-drag-and-drop` (slot↔inventory cross-window drag is the primary interaction). Layer `15-network-coupled-flow` for the `SafeboxSaveMoneyPacket` / `SafeboxWithdrawMoneyPacket` / `safebox_close` chat packet flow. Layer `05-feature-gated` if the storage feature itself is fork-gated (rare — most storage is core).

## Source

Pattern extracted from `pack/pack/root/uisafebox.py` (the `SafeboxWindow` class) and `pack/pack/uiscript/uiscript/safeboxwindow.py` from a real Metin2 fork. Anchor distills the safebox archetype: chrome + programmatic GridSlotWindow + password chain + page tabs + close-on-distance.

Real source has the slot grid CREATED IN CODE (not declared in uiscript), with `wndItem.ArrangeSlot(0, X_COUNT, size, 32, 32, 0, 0)` setting size at runtime. The reason: safebox grid size depends on the player's safebox-size purchase (3-page max from server). uiscript can't statically declare a runtime-sized grid; the class builds it.

Normalized to current m2ui rules:

- Added `__Initialize()` (real source uses inline `__init__` resets; consolidated)
- All callbacks via `ui.__mem_func__()` (real source uses this)
- `SetEvent(ui.__mem_func__(self.SelectPage), i)` — Pattern B with index arg. Verified `RadioButton.SetEvent(self, event, *args)` accepts `*args` in `pack/pack/root/ui.py`. If 1-arg only in fork, augment per `framework-augmentations.md` OR fall back to Pattern C (proxy lambda).
- `Destroy()` body preserved with `if self.X:` guards on owned dialogs (`dlgPickMoney`, `dlgChangePassword`)
- `Close()` sends `/safebox_close` chat command then hides; the server replies with the actual close confirmation
- ASCII-only

## Uiscript dict

```python
import uiScriptLocale

window = {
    "name" : "SafeboxWindow",

    "x" : 100,
    "y" : 20,

    "style" : ("movable", "float",),

    "width" : 176,
    "height" : 250,

    "children" :
    (
        {
            "name" : "board",
            "type" : "board",

            "x" : 0,
            "y" : 0,

            "width" : 176,
            "height" : 250,

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
                        { "name":"TitleName", "type":"text", "x":77, "y":3, "text":uiScriptLocale.SAFE_TITLE, "text_horizontal_align":"center" },
                    ),
                },

                ## Change Password button
                {
                    "name" : "ChangePasswordButton",
                    "type" : "button",

                    "x" : 0,
                    "y" : 58,

                    "text" : uiScriptLocale.SAFE_CHANGE_PASSWORD,
                    "horizontal_align" : "center",
                    "vertical_align"   : "bottom",

                    "default_image" : "d:/ymir work/ui/public/large_button_01.sub",
                    "over_image"    : "d:/ymir work/ui/public/large_button_02.sub",
                    "down_image"    : "d:/ymir work/ui/public/large_button_03.sub",
                },

                ## Exit / Close button
                {
                    "name" : "ExitButton",
                    "type" : "button",

                    "x" : 0,
                    "y" : 37,

                    "text" : uiScriptLocale.CLOSE,
                    "horizontal_align" : "center",
                    "vertical_align"   : "bottom",

                    "default_image" : "d:/ymir work/ui/public/large_button_01.sub",
                    "over_image"    : "d:/ymir work/ui/public/large_button_02.sub",
                    "down_image"    : "d:/ymir work/ui/public/large_button_03.sub",
                },
            ),
        },
    ),
}
```

Note the slot grid is NOT declared here — see Root class for the programmatic creation (`ui.GridSlotWindow()`).

## Root class

```python
import ui
import net
import player
import item
import safebox
import snd
import mouseModule
import localeInfo
import uiPickMoney
import uiCommon
from _weakref import proxy


class SafeboxWindow(ui.ScriptWindow):

    BOX_WIDTH = 176

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.__Initialize()
        self.__LoadWindow()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def __Initialize(self):
        self.tooltipItem = None
        self.sellingSlotNumber = -1
        self.pageButtonList = []
        self.curPageIndex = 0
        self.isLoaded = 0
        self.xSafeBoxStart = 0
        self.ySafeBoxStart = 0
        self.wndItem = None
        self.wndBoard = None
        self.dlgPickMoney = None
        self.dlgChangePassword = None

    @ui.WindowDestroy
    def Destroy(self):
        self.ClearDictionary()
        if self.dlgPickMoney:
            self.dlgPickMoney.Destroy()
            self.dlgPickMoney = None
        if self.dlgChangePassword:
            self.dlgChangePassword.Destroy()
            self.dlgChangePassword = None
        self.__Initialize()

    def __LoadWindow(self):
        if self.isLoaded == 1:
            return
        self.isLoaded = 1

        try:
            scriptLoader = ui.PythonScriptLoader()
            scriptLoader.LoadScriptFile(self, "UIScript/SafeboxWindow.py")
        except:
            import exception
            exception.Abort("SafeboxWindow.LoadWindow.LoadObject")

        # Create slot grid programmatically -- size determined at runtime
        # via SetTableSize (called from ShowWindow after server tells us
        # the player's safebox capacity).
        wndItem = ui.GridSlotWindow()
        wndItem.SetParent(self)
        wndItem.SetPosition(8, 35)
        wndItem.SetSelectEmptySlotEvent(ui.__mem_func__(self.SelectEmptySlot))
        wndItem.SetSelectItemSlotEvent(ui.__mem_func__(self.SelectItemSlot))
        wndItem.SetUnselectItemSlotEvent(ui.__mem_func__(self.UseItemSlot))
        wndItem.SetUseSlotEvent(ui.__mem_func__(self.UseItemSlot))
        wndItem.SetOverInItemEvent(ui.__mem_func__(self.OverInItem))
        wndItem.SetOverOutItemEvent(ui.__mem_func__(self.OverOutItem))
        wndItem.Show()

        # PickMoney dialog (for SafeboxSaveMoney / SafeboxWithdrawMoney)
        dlgPickMoney = uiPickMoney.PickMoneyDialog()
        dlgPickMoney.LoadDialog()
        dlgPickMoney.SetAcceptEvent(ui.__mem_func__(self.OnPickMoney))
        dlgPickMoney.Hide()

        # Change-password sub-dialog
        dlgChangePassword = ChangePasswordDialog()
        dlgChangePassword.LoadDialog()
        dlgChangePassword.Hide()

        # Static buttons
        self.GetChild("TitleBar").SetCloseEvent(ui.__mem_func__(self.Close))
        self.GetChild("ChangePasswordButton").SetEvent(ui.__mem_func__(self.OnChangePassword))
        self.GetChild("ExitButton").SetEvent(ui.__mem_func__(self.Close))

        self.wndItem = wndItem
        self.dlgPickMoney = dlgPickMoney
        self.dlgChangePassword = dlgChangePassword
        self.wndBoard = self.GetChild("board")

        # Default to 3-page table; ShowWindow re-sizes per server.
        self.SetTableSize(3)

    def ShowWindow(self, size):
        # Called from net.py RecvSafeboxSet after the server confirms password.
        (self.xSafeBoxStart, self.ySafeBoxStart, z) = player.GetMainCharacterPosition()
        self.SetTableSize(size)
        self.Show()

    def SetTableSize(self, size):
        # safebox.SAFEBOX_SLOT_Y_COUNT (engine binding) = rows per page.
        # safebox.SAFEBOX_SLOT_X_COUNT = columns per page.
        pageCount = max(1, size // safebox.SAFEBOX_SLOT_Y_COUNT)
        pageCount = min(3, pageCount)
        size = safebox.SAFEBOX_SLOT_Y_COUNT

        self.__MakePageButtons(pageCount)

        self.wndItem.ArrangeSlot(0, safebox.SAFEBOX_SLOT_X_COUNT, size, 32, 32, 0, 0)
        self.wndItem.RefreshSlot()
        self.wndItem.SetSlotBaseImage("d:/ymir work/ui/public/Slot_Base.sub", 1.0, 1.0, 1.0, 1.0)

        wnd_height = 130 + 32 * size
        self.wndBoard.SetSize(self.BOX_WIDTH, wnd_height)
        self.SetSize(self.BOX_WIDTH, wnd_height)
        self.UpdateRect()

    def __MakePageButtons(self, pageCount):
        self.curPageIndex = 0
        # Clear any prior buttons (re-init on size change)
        for btn in self.pageButtonList:
            btn.Hide()
        self.pageButtonList = []

        text = "I"
        pos = -int(float(pageCount - 1) / 2 * 52)
        for i in xrange(pageCount):
            button = ui.RadioButton()
            button.SetParent(self)
            button.SetUpVisual("d:/ymir work/ui/game/windows/tab_button_middle_01.sub")
            button.SetOverVisual("d:/ymir work/ui/game/windows/tab_button_middle_02.sub")
            button.SetDownVisual("d:/ymir work/ui/game/windows/tab_button_middle_03.sub")
            button.SetWindowHorizontalAlignCenter()
            button.SetWindowVerticalAlignBottom()
            button.SetPosition(pos, 85)
            button.SetText(text)
            # Pattern B: SetEvent(event, *args) -- RadioButton.SetEvent
            # accepts *args per ui.py. If fork's RadioButton.SetEvent is
            # 1-arg, augment ui.py OR use Pattern C lambda fallback.
            button.SetEvent(ui.__mem_func__(self.SelectPage), i)
            button.Show()
            self.pageButtonList.append(button)

            pos += 52
            text += "I"

        if self.pageButtonList:
            self.pageButtonList[0].Down()

    def SelectPage(self, index):
        self.curPageIndex = index
        for btn in self.pageButtonList:
            btn.SetUp()
        if 0 <= index < len(self.pageButtonList):
            self.pageButtonList[index].Down()
        self.RefreshSafebox()

    def __LocalPosToGlobalPos(self, local):
        return self.curPageIndex * safebox.SAFEBOX_PAGE_SIZE + local

    def RefreshSafebox(self):
        getItemID = safebox.GetItemID
        getItemCount = safebox.GetItemCount
        setItemID = self.wndItem.SetItemSlot

        for i in xrange(safebox.SAFEBOX_PAGE_SIZE):
            slotIndex = self.__LocalPosToGlobalPos(i)
            itemCount = getItemCount(slotIndex)
            if itemCount <= 1:
                itemCount = 0
            setItemID(i, getItemID(slotIndex), itemCount)

        self.wndItem.RefreshSlot()

    def Close(self):
        # Server-mediated close: send packet then hide.
        net.SendChatPacket("/safebox_close")
        self.Hide()

    def CommandCloseSafebox(self):
        # Called by net.py when server confirms close.
        if self.tooltipItem:
            self.tooltipItem.HideToolTip()
        if self.dlgPickMoney:
            self.dlgPickMoney.Close()
        if self.dlgChangePassword:
            self.dlgChangePassword.Close()
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True

    def OnUpdate(self):
        # Auto-close when player walks away (canonical 1000-unit threshold).
        # patterns.md section 7.15 documents this idiom.
        AUTO_CLOSE_DISTANCE = 1000
        (x, y, z) = player.GetMainCharacterPosition()
        if abs(x - self.xSafeBoxStart) > AUTO_CLOSE_DISTANCE or abs(y - self.ySafeBoxStart) > AUTO_CLOSE_DISTANCE:
            self.Close()

    # Slot events (typed for the safebox slot type).
    def SelectEmptySlot(self, selectedSlotPos):
        selectedSlotPos = self.__LocalPosToGlobalPos(selectedSlotPos)
        if not mouseModule.mouseController.isAttached():
            return

        attachedSlotType = mouseModule.mouseController.GetAttachedType()
        attachedSlotPos = mouseModule.mouseController.GetAttachedSlotNumber()
        attachedItemCount = mouseModule.mouseController.GetAttachedItemCount()

        if player.SLOT_TYPE_INVENTORY == attachedSlotType:
            net.SendSafeboxCheckinPacket(selectedSlotPos, attachedSlotPos)
            snd.PlaySound("sound/ui/drop.wav")
        elif player.SLOT_TYPE_SAFEBOX == attachedSlotType:
            net.SendSafeboxItemMovePacket(attachedSlotPos, selectedSlotPos, attachedItemCount)

        mouseModule.mouseController.DeattachObject()

    def SelectItemSlot(self, selectedSlotPos):
        selectedSlotPos = self.__LocalPosToGlobalPos(selectedSlotPos)
        itemIndex = safebox.GetItemID(selectedSlotPos)
        if 0 == itemIndex:
            return
        itemCount = safebox.GetItemCount(selectedSlotPos)
        mouseModule.mouseController.AttachObject(self, player.SLOT_TYPE_SAFEBOX, selectedSlotPos, itemIndex, itemCount)
        mouseModule.mouseController.SetCallBack("INVENTORY", ui.__mem_func__(self.OnDropToInventory))
        snd.PlaySound("sound/ui/pick.wav")

    def OnDropToInventory(self):
        attachedSlotPos = mouseModule.mouseController.GetAttachedSlotNumber()
        net.SendSafeboxCheckoutPacket(attachedSlotPos, 0)

    def UseItemSlot(self, slotIndex):
        # Right-click in safebox = withdraw to first free inventory slot.
        slotIndex = self.__LocalPosToGlobalPos(slotIndex)
        net.SendSafeboxCheckoutPacket(slotIndex, 0)

    def OverInItem(self, slotIndex):
        slotIndex = self.__LocalPosToGlobalPos(slotIndex)
        if self.tooltipItem:
            self.tooltipItem.SetSafeBoxItem(slotIndex)

    def OverOutItem(self):
        if self.tooltipItem:
            self.tooltipItem.HideToolTip()

    def OnChangePassword(self):
        if self.dlgChangePassword:
            self.dlgChangePassword.Open()

    def OpenPickMoneyDialog(self):
        if mouseModule.mouseController.isAttached():
            attachedSlotType = mouseModule.mouseController.GetAttachedType()
            if attachedSlotType == player.SLOT_TYPE_INVENTORY:
                if mouseModule.mouseController.GetAttachedItemIndex() == player.ITEM_MONEY:
                    net.SendSafeboxSaveMoneyPacket(mouseModule.mouseController.GetAttachedItemCount())
                    snd.PlaySound("sound/ui/money.wav")
            mouseModule.mouseController.DeattachObject()
            return

        curMoney = safebox.GetMoney()
        if curMoney <= 0:
            return
        self.dlgPickMoney.Open(curMoney)

    def OnPickMoney(self, money, cheque=0):
        net.SendSafeboxWithdrawMoneyPacket(money)
        snd.PlaySound("sound/ui/money.wav")

    def SetItemToolTip(self, tooltipItem):
        self.tooltipItem = tooltipItem
```

## Locale entries

Append to `locale_interface.txt`:

```
SAFE_TITLE	Storage
SAFE_CHANGE_PASSWORD	Change Password
CLOSE	Close
```

## interfacemodule.py integration snippet

```python
import uiSafebox

class Interface(object):

    def __init__(self):
        self.wndSafebox = None

    def MakeInterface(self):
        # ... other window creation ...
        self.wndSafebox = uiSafebox.SafeboxWindow()
        self.wndSafebox.SetItemToolTip(self.tooltipItem)

    def __DestroyDialogs(self):
        if self.wndSafebox:
            self.wndSafebox.Destroy()
            self.wndSafebox = None

    def HideAllWindows(self):
        if self.wndSafebox:
            self.wndSafebox.Close()

    def OpenSafeboxWindow(self, size):
        # Server-driven open: net.py's RecvSafeboxSet calls this after
        # password confirmation. The server passes the player's safebox
        # capacity (size = SAFEBOX_PAGE_SIZE * pageCount).
        if self.wndSafebox:
            self.wndSafebox.ShowWindow(size)

    def RefreshSafebox(self):
        # Called from net.py on RecvSafeboxItem packets.
        if self.wndSafebox:
            self.wndSafebox.RefreshSafebox()

    def CommandCloseSafebox(self):
        if self.wndSafebox:
            self.wndSafebox.CommandCloseSafebox()
```

In `net.py`:

```python
def OnSafeboxSet(size):
    interface = GetInterface()
    if interface:
        interface.OpenSafeboxWindow(size)

def OnSafeboxItem(slot, vnum, count):
    safebox.SetItemData(slot, vnum, count)  # safebox C++ binding
    interface = GetInterface()
    if interface:
        interface.RefreshSafebox()

def OnSafeboxClosed():
    interface = GetInterface()
    if interface:
        interface.CommandCloseSafebox()
```

## Common variations

1. **Mall window** (item-mall delivery box, no password) — drop the password chain (no `dlgChangePassword`, no `OnChangePassword`). The mall opens via a direct `MallWindow.Show()` call without password confirmation. Slot type changes to `player.SLOT_TYPE_MALL`. Otherwise identical chrome.
2. **Password-protected open path** (typical safebox flow) — Open() opens a `PasswordDialog` (anchor `01-simple-dialog`-shaped). Dialog Accept sends `net.SendSafeboxOpenPacket(password)`; server validates, replies with `RecvSafeboxSet(size)`; net.py calls `interface.OpenSafeboxWindow(size)` which calls `wndSafebox.ShowWindow(size)`. The actual safebox window only appears on server confirmation. Cross-link to `01-simple-dialog` for the password modal pattern.
3. **Variable page count from server** — the `size` param to `ShowWindow` arrives from the server based on the player's safebox-expansion purchase. `SetTableSize` clamps to 3 max pages. If the fork supports more (e.g., 5 pages with `safebox.SAFEBOX_MAX_PAGE_COUNT = 5`), update the `min(3, pageCount)` constant.
4. **Account-shared storage** — a safebox shared across all characters on one account. Use `account_safebox` C++ binding instead of `safebox`. Otherwise identical chrome and password logic. Layer augmentor `05-feature-gated` (`app.ENABLE_ACCOUNT_SAFEBOX`).
5. **Money slot** — for safeboxes that hold gold separately, add a `Money_Slot` button to uiscript and wire `OpenPickMoneyDialog` to it. Real source has this commented out — uncomment if the fork's safebox tracks gold. Pattern matches inventory's money-slot.

## Don't copy these obsolete bits

- Real source has `# @fixme009` in `Close()`. Anchor strips fork-internal review tags — they have no value generically.
- Real source uses `from _weakref import proxy` inside `__LoadWindow` (function scope import). Anchor preserves this — the proxy is needed only for the rare `BindInterface` path; keeping the import local minimizes module-load surface.
- Real source `SetTableSize` divides with `/` (Python 2 integer division when both ints). Anchor uses `//` per Critical Rule 14.
- Real source `RefreshSafeboxMoney` is a no-op (commented body). Anchor strips it — a function that does nothing is dead code. Re-add only if the fork wires a money widget.
- Real source `__MakePageButton` does NOT clear prior buttons before re-creating them on size change. Anchor adds the `for btn in self.pageButtonList: btn.Hide()` loop — without this, pages 4+ leak as orphan widgets when size shrinks (rare but observable).
- Real source has commented-out `Money` and `Money_Slot` GetChild calls (`#self.wndMoney = self.GetChild("Money")`). Anchor strips — see variation 5 if money support is needed.
