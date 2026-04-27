# Anchor 14: Drag-and-Drop (Augmentor)

## What this is + when to use it

Slot-to-slot or slot-to-window drag-and-drop interactions. Items, skills, emotions, money — anything visible in a slot can be picked up by clicking, dragged across the screen with the cursor showing a translucent icon, and dropped onto another slot or window. The mechanic is owned by the global `mouseModule.mouseController` singleton (instance lives in `interfacemodule`); each window participating in drag wires its slot-events into the controller's `AttachObject` / `SetCallBack` / drop-handler API.

This is an AUGMENTOR — it layers slot-drag mechanics onto any archetype with item slots (07, 08, 10, 12, 13). Body content lives in section 6.

Use this augmentor when: any window with `grid_table` or `slot` widgets needs to source OR receive dragged items. Do NOT use for windows that ONLY display items without movement (use `06-tooltip-bound` alone). Do NOT use for non-slot drags (window dragging is `"movable"` flag in uiscript — different system).

## Source

Pattern extracted from `pack/pack/root/uiinventory.py`, `pack/pack/root/uishop.py`, `pack/pack/root/uisafebox.py`, `pack/pack/root/uiprivateshopbuilder.py`, and `pack/pack/root/mousemodule.py` (the central API) from a real Metin2 fork. The augmentor consolidates the SHARED drag-and-drop pattern across all four item-window archetypes.

`mouseController` is created once in `interfacemodule.py` (`self.mouseController = mouseModule.CMouseController()`) and exposed globally via `mouseModule.mouseController` after `Create()` runs. Every window that drags items reads/writes through this singleton.

Normalized to current m2ui rules:

- All callbacks via `ui.__mem_func__()` (real source uses this consistently)
- `SetCallBack(type, event)` Pattern A — `mouseController.SetCallBack` is 2-arg (`type, event`); event is the wrapped callback. No extra args needed.
- `AttachObject` argument order verified against `mousemodule.py:172` — `(Owner, Type, SlotNumber, ItemIndex, count=0)`. Forks may have variations (additional `cheque` param when `app.ENABLE_CHEQUE_SYSTEM` is set); verify before passing extra args.
- AntiFlag validation pattern: `item.SelectItem(idx); item.IsAntiFlag(item.ANTIFLAG_*)` — must call `SelectItem` BEFORE `IsAntiFlag` (the C++ binding uses internal selection state)
- `DeattachObject()` MUST be called in every drop-handler exit path, including error paths. Not calling it leaves the cursor stuck holding the item.
- ASCII-only

## Uiscript dict

Same as augmented archetype (07-shop-exchange, 08-inventory-equipment, 10-paginated-slot-grid, 12-storage-warehouse, 13-craft-refine-window). The drag mechanic is wired entirely in the root class — no uiscript changes.

## Root class

Augmentor-only decoration: the slot-event wiring + drop-handler methods that the augmented archetype's `__LoadWindow` (or equivalent) MUST call. Same body shape as 06-tooltip-bound's wiring section.

```python
# In the augmented archetype's __LoadWindow / __LoadDialog:
wndItem.SetSelectEmptySlotEvent(ui.__mem_func__(self.OnSelectEmptySlot))
wndItem.SetSelectItemSlotEvent(ui.__mem_func__(self.OnSelectItemSlot))
wndItem.SetUnselectItemSlotEvent(ui.__mem_func__(self.OnUnselectItemSlot))
wndItem.SetUseSlotEvent(ui.__mem_func__(self.OnUseSlot))
```

Plus the source-side handler (the slot the user clicks first):

```python
def OnSelectItemSlot(self, selectedSlotPos):
    if mouseModule.mouseController.isAttached():
        # Already holding an item — let the source-side cancellation fire
        # via OnSelectEmptySlot in another window, OR cancel here.
        return

    globalSlotPos = self.__LocalPosToGlobalPos(selectedSlotPos)
    itemIndex = player.GetItemIndex(globalSlotPos)
    if 0 == itemIndex:
        return

    itemCount = player.GetItemCount(globalSlotPos)

    # AntiFlag validation: prevent picking up un-droppable items.
    item.SelectItem(itemIndex)
    if item.IsAntiFlag(item.ANTIFLAG_GIVE):
        # Item is bound; can't be moved out of inventory.
        chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.ITEM_CANNOT_DROP)
        return

    mouseModule.mouseController.AttachObject(
        self,
        player.SLOT_TYPE_INVENTORY,  # or whichever SLOT_TYPE_X the source is
        globalSlotPos,
        itemIndex,
        itemCount,
    )
    mouseModule.mouseController.SetCallBack("INVENTORY", ui.__mem_func__(self.OnDropToInventory))
    snd.PlaySound("sound/ui/pick.wav")
```

And the destination-side handler (the slot the user drops onto):

```python
def OnSelectEmptySlot(self, selectedSlotPos):
    if not mouseModule.mouseController.isAttached():
        return

    attachedSlotType = mouseModule.mouseController.GetAttachedType()
    attachedSlotPos = mouseModule.mouseController.GetAttachedSlotNumber()
    attachedItemCount = mouseModule.mouseController.GetAttachedItemCount()

    globalSlotPos = self.__LocalPosToGlobalPos(selectedSlotPos)

    if attachedSlotType == player.SLOT_TYPE_INVENTORY:
        # Inventory→inventory move (re-arrange).
        net.SendItemMovePacket(attachedSlotPos, globalSlotPos, attachedItemCount)
    elif attachedSlotType == player.SLOT_TYPE_SHOP:
        # Buy from shop.
        net.SendShopBuyPacket(attachedSlotPos)
    elif attachedSlotType == player.SLOT_TYPE_SAFEBOX:
        # Withdraw from safebox to inventory.
        net.SendSafeboxCheckoutPacket(attachedSlotPos, globalSlotPos)

    mouseModule.mouseController.DeattachObject()
```

## Locale entries

Augmentor-specific user-visible strings:

```
ITEM_CANNOT_DROP	You can't move this item.
ITEM_CANNOT_SELL	You can't sell this item.
ITEM_CANNOT_GIVE	You can't give this item.
```

(Most forks already have these in `localeInfo`. Confirm before adding.)

## interfacemodule.py integration snippet

This is the heart of the drag-and-drop augmentor. Drag plumbing sits in three places: `interfacemodule.MakeInterface` (controller creation + `Create()` call), the augmented window's `OnSelect*Slot` methods (consume the attached object), and the augmented window's `Hide()` (cancel drag if window closes mid-op).

### Step 1: Create mouseController in interfacemodule

```python
import mouseModule

class Interface(object):

    def __init__(self):
        self.mouseController = None

    def MakeInterface(self):
        # Create FIRST — before any window's __LoadWindow runs, since
        # those windows reference mouseModule.mouseController via the
        # module-level singleton.
        if not mouseModule.mouseController:
            self.mouseController = mouseModule.CMouseController()
            self.mouseController.Create()
            mouseModule.mouseController = self.mouseController

        # ... rest of MakeInterface (window construction) ...
```

### Step 2: Source-side wiring (the window the drag starts from)

```python
class InventoryWindow(ui.ScriptWindow):

    def __LoadWindow(self):
        # ... uiscript load + GetChild calls ...

        wndItem.SetSelectItemSlotEvent(ui.__mem_func__(self.OnSelectItemSlot))
        wndItem.SetSelectEmptySlotEvent(ui.__mem_func__(self.OnSelectEmptySlot))
        wndItem.SetOverInItemEvent(ui.__mem_func__(self.OnOverInItem))
        wndItem.SetOverOutItemEvent(ui.__mem_func__(self.OnOverOutItem))

    def OnSelectItemSlot(self, selectedSlotPos):
        # Drag start: attach + register drop callback.
        if mouseModule.mouseController.isAttached():
            return
        globalSlotPos = self.__LocalPosToGlobalPos(selectedSlotPos)
        itemIndex = player.GetItemIndex(globalSlotPos)
        if 0 == itemIndex:
            return
        itemCount = player.GetItemCount(globalSlotPos)

        item.SelectItem(itemIndex)
        if item.IsAntiFlag(item.ANTIFLAG_GIVE):
            chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.ITEM_CANNOT_DROP)
            return

        mouseModule.mouseController.AttachObject(self, player.SLOT_TYPE_INVENTORY, globalSlotPos, itemIndex, itemCount)
        mouseModule.mouseController.SetCallBack("INVENTORY", ui.__mem_func__(self.OnDropToInventory))
        snd.PlaySound("sound/ui/pick.wav")

    def OnDropToInventory(self):
        # Same-window drop: cross-slot move within inventory.
        attachedSlotPos = mouseModule.mouseController.GetAttachedSlotNumber()
        # The destination slot is determined by where the engine fires
        # the OnSelectEmptySlot — see Step 3.
```

### Step 3: Destination-side wiring (the window receiving the drop)

```python
class SafeboxWindow(ui.ScriptWindow):

    def OnSelectEmptySlot(self, selectedSlotPos):
        if not mouseModule.mouseController.isAttached():
            return

        attachedSlotType = mouseModule.mouseController.GetAttachedType()
        attachedSlotPos = mouseModule.mouseController.GetAttachedSlotNumber()
        attachedItemCount = mouseModule.mouseController.GetAttachedItemCount()
        selectedSlotPos = self.__LocalPosToGlobalPos(selectedSlotPos)

        if attachedSlotType == player.SLOT_TYPE_INVENTORY:
            # Deposit inventory item into safebox.
            net.SendSafeboxCheckinPacket(selectedSlotPos, attachedSlotPos)
        elif attachedSlotType == player.SLOT_TYPE_SAFEBOX:
            # Re-arrange within safebox.
            net.SendSafeboxItemMovePacket(attachedSlotPos, selectedSlotPos, attachedItemCount)

        mouseModule.mouseController.DeattachObject()
```

### Step 4: Window-hide cancellation (release drag if window closes mid-op)

```python
def Hide(self):
    # If the user closes this window while holding an item, the engine
    # cancels the drag — but the cursor visual stays stuck. Defensive
    # detach prevents the stuck-cursor failure-atlas entry 16.
    if mouseModule.mouseController.isAttached():
        if mouseModule.mouseController.GetAttachedOwner() is self:
            mouseModule.mouseController.DeattachObject()
    ui.ScriptWindow.Hide(self)
```

### Step 5: Right-click handlers (the cancellation path)

```python
def OnUnselectItemSlot(self, selectedSlotPos):
    # Right-click in canonical Metin2 = unselect/use the slot's item.
    # No context menu widget exists in the engine.
    selectedSlotPos = self.__LocalPosToGlobalPos(selectedSlotPos)
    net.SendItemUsePacket(selectedSlotPos)
```

## Common variations

1. **Drop to empty cell** — `OnSelectEmptySlot` consumes the drop. The grid_table widget fires this event when the user releases over a slot whose `SetItemSlot` count is 0.
2. **Swap between same-type slots** — when `attachedSlotType == self.slotType` (the destination's own type), the operation is a re-arrange (same-window). When they differ, it's a transfer (cross-window). Both paths typically end with `net.Send*Packet` to validate server-side.
3. **Drag validation failure path** — when the destination rejects the drop (e.g., antiflag, wrong type, server-rejected), call `DeattachObject()` to release the cursor. Optionally play a "fail" sound: `snd.PlaySound("sound/ui/loginfail.wav")` and surface a chat message via `chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.X)`.
4. **Money drag** — `mouseController.AttachMoney(self, type, count, cheque=0)` instead of `AttachObject`. Money has no item slot (uses sentinel `SlotNumber=-1`). Used for safebox-deposit-money and inventory-money-pick flows. Drop handler reads `mouseController.GetAttachedItemIndex() == player.ITEM_MONEY` to detect money vs item.
5. **Shop buy via drag** — drag from shop slot drops into inventory; the drop handler fires `net.SendShopBuyPacket(attachedSlotPos)` instead of an item-move. Shops typically also accept click-to-buy (without drag) — see `07-shop-exchange.md` for the dual path.

## Don't copy these obsolete bits

- Some forks call `mouseModule.mouseController.AttachObject(self, ...)` with `self` from the wrong class context (e.g., a sub-window passes its parent inventory's `self` instead of its own). The Owner pointer is used by `DeattachObject` to identify the owning window — passing the wrong `self` makes the engine cancel the wrong window's drag state. Always pass the calling class's `self`.
- Real source `mouseModule.py:248-250` has duplicated lines (assigning `AttachedIconHalfWidth` and `AttachedIconHalfHeight` twice). Anchor doesn't need to copy that bug; if augmenting `mouseModule.py` itself, fix the duplicate.
- Real source uses `self.callbackDict.has_key(type)` (Python 2 only). Anchor uses `type in self.callbackDict` (portable per Critical Rule 14). If you need to AUGMENT `mouseModule.py`, replace `has_key`.
- Real source has a commented-out `AttachedCountTextLineHandle = grpText.Generate()` block. The modern path uses `ui.NumberLine("CURTAIN")` for count display. Strip the commented block when copying.
- Some forks call `DeattachObject` AFTER `RunCallBack` finishes. The canonical mouseModule path calls callbacks-then-deattach internally (`RunCallBack` + `DeattachObject` happens in `wndMgr` C++ binding, not in Python). Don't call `DeattachObject` inside the drop callback unless the callback's logic explicitly requires it (e.g., AntiFlag rejection that returns early before the engine's automatic detach).
- Some forks register a callback with the wrong type string. The type strings are: `"INVENTORY"`, `"BELT_INVENTORY"`, `"DRAGON_SOUL_INVENTORY"`, `"COSTUME"`, `"SHOP"`, `"PRIVATE_SHOP"`, `"SAFEBOX"`, `"MALL"`, `"QUICK_SLOT"`, `"SKILL"`. Match the destination window's type exactly — typos silently swallow the drop.
