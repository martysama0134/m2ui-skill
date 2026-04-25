# Anchor 06: Tooltip-Bound Slot Window

## What this is + when to use it

A window with item or skill slots that shows a tooltip when the user hovers over them. The tooltip object is owned by `interfacemodule` (one shared `tooltipItem` per type) and is wired into the window via `SetItemToolTip(tooltipItem)`. Slot hover events feed the tooltip via `SetInventoryItem` / `AddItemData` / `Show`. Use this for any window displaying items, skills, or anything that needs hover-detail (inventory, shop, mall, dragon soul, cube, exchange). NOT for static labels (use `text` widget directly). NOT for windows that own their own tooltip (rare; usually shared from interfacemodule).

## Source

Distilled from `pack/pack/root/uiinventory.py` (12 SetItemToolTip references confirmed). The full file is 1400+ lines and handles inventory-specific business logic; this anchor extracts ONLY the tooltip-binding pattern (slot wiring + tooltip setter + Close-time hide). Normalized to current m2ui rules:

- `//` for int division, not `/`
- All callbacks via `ui.__mem_func__()`
- `OnPressEscapeKey()` returns `True`
- `Destroy()` decorated with `@ui.WindowDestroy` (real `uiinventory.Destroy` is NOT decorated — this is one of the most common Phase 1 audit findings)
- `Initialize()` lists every `self.X` (real source scatters resets across `__init__` and `Destroy` — consolidated here)
- `Close()` calls `tooltipItem.HideToolTip()` (real source forgets in some forks — tooltip stays visible after window close)

## Uiscript dict

```python
import uiScriptLocale

window = {
    "name" : "ItemSlotWindow",
    "style" : ("movable", "float",),

    "x" : SCREEN_WIDTH // 2 - 100,
    "y" : SCREEN_HEIGHT // 2 - 110,

    "width"  : 200,
    "height" : 220,

    "children" :
    (
        {
            "name"   : "board",
            "type"   : "board_with_titlebar",

            "x" : 0,
            "y" : 0,

            "width"  : 200,
            "height" : 220,

            "title" : uiScriptLocale.ITEM_SLOT_WINDOW_TITLE,

            "children" :
            (
                {
                    "name"  : "ItemSlot",
                    "type"  : "grid_table",

                    "x" : 8,
                    "y" : 32,

                    "start_index" : 0,
                    "x_count" : 5,
                    "y_count" : 5,
                    "x_step" : 32,
                    "y_step" : 32,

                    "image" : "d:/ymir work/ui/public/Slot_Base.sub",
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


class ItemSlotWindow(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.Initialize()
        self.__LoadWindow()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def Initialize(self):
        self.tooltipItem = None
        self.interface = None
        self.itemSlot = None
        self.itemSlotData = {}    # {slotIndex: itemVnum} — populate via SetItem

    def __LoadWindow(self):
        try:
            pyScrLoader = ui.PythonScriptLoader()
            pyScrLoader.LoadScriptFile(self, "uiscript/itemslotwindow.py")
        except:
            import exception
            exception.Abort("ItemSlotWindow.__LoadWindow.LoadScript")

        try:
            self.itemSlot = self.GetChild("ItemSlot")
            # board_with_titlebar exposes its inner titlebar via the window's
            # GetChild("TitleBar") directly — NOT nested under GetChild("board").
            self.GetChild("TitleBar").SetCloseEvent(ui.__mem_func__(self.Close))
        except:
            import exception
            exception.Abort("ItemSlotWindow.__LoadWindow.BindObject")

        # Slot event wiring — every callback wrapped via ui.__mem_func__.
        self.itemSlot.SetOverInItemEvent(ui.__mem_func__(self.OverInItem))
        self.itemSlot.SetOverOutItemEvent(ui.__mem_func__(self.OverOutItem))
        self.itemSlot.SetSelectItemSlotEvent(ui.__mem_func__(self.SelectItemSlot))

    @ui.WindowDestroy
    def Destroy(self):
        self.ClearDictionary()
        self.Initialize()

    # --- Tooltip + interface binding (called by interfacemodule) ---

    def SetItemToolTip(self, tooltipItem):
        # interfacemodule passes its shared tooltip ref. Stored, not owned.
        # The window does NOT call tooltipItem.Destroy() — interfacemodule does.
        self.tooltipItem = tooltipItem

    def BindInterfaceClass(self, interface):
        # interfacemodule passes itself for back-callbacks. Stored, not owned.
        self.interface = interface

    # --- Public API: populate slots ---

    def SetItem(self, slotIndex, itemVnum, itemCount):
        self.itemSlotData[slotIndex] = itemVnum
        self.itemSlot.SetItemSlot(slotIndex, itemVnum, itemCount)

    def ClearItem(self, slotIndex):
        if slotIndex in self.itemSlotData:
            del self.itemSlotData[slotIndex]
        self.itemSlot.ClearSlot(slotIndex)

    def ClearAllItems(self):
        self.itemSlotData = {}
        self.itemSlot.ClearAllSlot()

    # --- Hover handlers — feed the shared tooltip ---

    def OverInItem(self, slotIndex):
        if not self.tooltipItem:
            return
        if slotIndex not in self.itemSlotData:
            return

        itemVnum = self.itemSlotData[slotIndex]
        item.SelectItem(itemVnum)

        self.tooltipItem.ClearToolTip()
        # SetInventoryItem looks up the item at this player.INVENTORY slot index.
        # If your slots represent items NOT in the player inventory (e.g., shop
        # listings), use AddItemData(itemVnum, [], []) directly instead.
        self.tooltipItem.AddItemData(itemVnum, [], [])
        self.tooltipItem.Show()

    def OverOutItem(self):
        if self.tooltipItem:
            self.tooltipItem.HideToolTip()

    def SelectItemSlot(self, slotIndex):
        # Hook for click — left as a no-op pass-through here.
        pass

    # --- Lifecycle ---

    def Open(self):
        self.SetCenterPosition()
        self.SetTop()
        self.Show()

    def Close(self):
        # IMPORTANT: hide the shared tooltip when the window closes,
        # otherwise it remains visible (overlapping the next window the
        # user opens). Real uiinventory.py omits this and has a known
        # cosmetic bug because of it.
        if self.tooltipItem:
            self.tooltipItem.HideToolTip()
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True
```

## Locale entries

```python
ITEM_SLOT_WINDOW_TITLE    Items
```

The slot tooltips themselves pull text from item data (`item.GetItemName()`, etc.) — no per-slot locale entries needed in this window.

## interfacemodule.py integration snippet

```python
import itemslotwindow
import uitooltip

class Interface(object):

    def __init__(self):
        # The shared tooltip is owned by interfacemodule, NOT by individual windows.
        # All windows that show item-tooltips share the same instance.
        self.tooltipItem = uitooltip.ItemToolTip()
        self.tooltipItem.Hide()

        self.wndItemSlots = None

    def MakeInterface(self):
        self.wndItemSlots = itemslotwindow.ItemSlotWindow()
        # Pass the shared tooltip — window stores ref, does NOT own.
        self.wndItemSlots.SetItemToolTip(self.tooltipItem)
        # Pass interface back-ref — for callbacks to interfacemodule methods.
        self.wndItemSlots.BindInterfaceClass(self)

    def ToggleItemSlotWindow(self):
        if not self.wndItemSlots:
            return
        if self.wndItemSlots.IsShow():
            self.wndItemSlots.Close()
        else:
            self.wndItemSlots.Open()

    def HideAllWindows(self):
        if self.wndItemSlots:
            self.wndItemSlots.Close()  # also hides the tooltip via Close()

    def __del__(self):
        if self.wndItemSlots:
            self.wndItemSlots.Destroy()
            self.wndItemSlots = None
        # tooltipItem owned here — destroy here too.
        if self.tooltipItem:
            self.tooltipItem.Destroy()
            self.tooltipItem = None
```

## Common variations

1. **Skill tooltips instead of item** — store `self.tooltipSkill`, call `SetSkillToolTip(self.tooltipSkill)` on the window, and in `OverInItem` call `self.tooltipSkill.SetSkill(skillIndex)` + `Show()` instead of `AddItemData`.
2. **Custom tooltip content** — write your own `ui.ScriptWindow` tooltip class, share it via a custom `SetXxxToolTip` setter on the window. The pattern is identical: window stores ref, hover handler feeds it, `Close()` hides it.
3. **Delayed tooltip (hover for 0.5s before showing)** — track `self.overInTime = app.GetTime()` in `OverInItem` (without immediate `Show`), then in `OnUpdate` check elapsed time and call `Show` once threshold passes. Reset `overInTime = 0` in `OverOutItem`.
4. **Multi-target tooltip (item + skill in same window)** — wire BOTH `SetItemToolTip` and `SetSkillToolTip`, store both refs, branch in the hover handler based on slot type.
5. **Pinned tooltip (sticks until clicked away)** — replace `OverOutItem` with a no-op for tooltip; add a global click handler that calls `HideToolTip` when click lands outside the slot. Risky pattern — most users expect hover-only tooltips.

## Don't copy these obsolete bits

- Source `Destroy()` is NOT decorated with `@ui.WindowDestroy` — ADDED. Without the decorator, child windows leak.
- Source `Close()` does NOT call `self.tooltipItem.HideToolTip()` — ADDED. Without it the tooltip stays visible after window close (cosmetic bug, persistent across sessions).
- Source `Destroy()` resets ~20 individual `self.X = 0` and `self.X = None` lines — REPLACED with a single `self.Initialize()` call. Resets stay consolidated; new instance vars don't drift between `__init__` and `Destroy`.
- Source uses `0` for "no value" (`self.wndItem = 0`) AND `None` (`self.tooltipItem = None`) inconsistently — STANDARDIZED to `None`. `if not self.tooltipItem:` works for both, but `None` is the unambiguous Python idiom.
- Source `__init__` does NOT call `Initialize()` first — ADDED. Without it, instance vars exist only after `LoadWindow()`, so any pre-load access raises `AttributeError`.
- Source `__LoadWindow` uses `self.isLoaded == 1` flag — OK in inventory's case (it's reloaded across reconnect) but unnecessary for most slot windows; this anchor omits it.
