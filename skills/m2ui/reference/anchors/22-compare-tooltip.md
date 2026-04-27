# Anchor 22: Compare-Tooltip Side-by-Side (Augmentor)

## What this is + when to use it

An **augmentor** for tooltip-bound archetypes. Layers compare-tooltip behavior onto archetypes 06-tooltip-bound, 07-shop-exchange, 08-inventory-equipment, 12-storage-warehouse: when the user hovers an item slot AND holds the modifier key (canonical: Left Alt), a second `ItemToolTip` widget renders alongside the primary tooltip showing the player's currently EQUIPPED item of the same slot type. Lets the user compare stats before deciding whether to swap.

AUGMENTOR (single-source). Body content lives in section 6.

Use this when the consumer needs at-a-glance stat comparison: weapons in shop dialogs, armor in inventory hover, accessories on offer in trade. Combine with any tooltip-bound archetype.

## Source

Single-source synthesis -- only one peer implementation found in the survey set. Conventions verified against engine semantics (`event-binding.md` for callbacks, `widgets.md` for the `ItemToolTip` widget, `bindings.md` for the `item.GetCompareIndex` helper that resolves a hovered vnum to the player's equipped slot index) rather than peer agreement. Fork variations may differ; treat the anchor's specific shape as ONE canonical form, not THE form. The source uses `app.__COMPARE_TOOLTIP__` as a build-time flag; the anchor uses `app.ENABLE_COMPARE_TOOLTIP` to align with the m2ui feature-flag convention used by anchor 05-feature-gated.

## Uiscript dict

Same as augmented archetype. The compare-tooltip overlay is a runtime widget owned by `interfacemodule`, not a uiscript-declared element.

## Root class

Same as augmented archetype, with one tooltip-class extension and three integration hooks documented in section 6.

## Locale entries

Augmentor adds one key:

```
TOOLTIP_COMPARE_EQUIPPED_TAG    Equipped
```

The tag is appended to the second tooltip's body so the user can tell at a glance which side is the equipped item.

## interfacemodule.py integration snippet

The full body for this augmentor lives here. Three integration steps:

### Step 1: extend the `ItemToolTip` class with compare-state

In your fork's `pack/pack/root/uitooltip.py`, add a feature-gated init + destroy + compare-method to `ItemToolTip`:

```python
class ItemToolTip(ToolTip):

    def __init__(self, width=TOOL_TIP_WIDTH, isPickable=False):
        ToolTip.__init__(self, width, isPickable)
        self.ClearToolTip()
        if app.ENABLE_COMPARE_TOOLTIP:
            self.compareTooltip = None
            self.isCompareInstance = False

    def __del__(self):
        ToolTip.__del__(self)
        if app.ENABLE_COMPARE_TOOLTIP:
            if self.compareTooltip is not None:
                self.compareTooltip = None

    def HideToolTip(self):
        self.Hide()
        if app.ENABLE_COMPARE_TOOLTIP:
            if self.compareTooltip is not None:
                self.compareTooltip.Hide()

    def SetCompareItem(self, hoveredVnum):
        if not app.ENABLE_COMPARE_TOOLTIP:
            return
        if self.isCompareInstance:
            # Don't recurse: the compare tooltip itself never spawns another.
            return
        equippedSlotIndex = item.GetCompareIndex(hoveredVnum)
        if not equippedSlotIndex:
            return
        if self.compareTooltip is None:
            self.compareTooltip = ItemToolTip()
            self.compareTooltip.isCompareInstance = True
        self.compareTooltip.SetInventoryItem(equippedSlotIndex, player.INVENTORY, allowCompare=False)
        self.compareTooltip.AutoAppendTextLine(localeInfo.TOOLTIP_COMPARE_EQUIPPED_TAG)
        self.compareTooltip.ResizeToolTip()
        self.__PositionCompareNextToPrimary()

    def __PositionCompareNextToPrimary(self):
        if self.compareTooltip is None:
            return
        # Render the compare tooltip immediately to the right of the primary,
        # clamped within screen bounds so it never renders off-screen.
        primaryX, primaryY = self.GetGlobalPosition()
        primaryWidth = self.GetWidth()
        compareWidth = self.compareTooltip.GetWidth()
        compareHeight = self.compareTooltip.GetHeight()
        screenWidth = wndMgr.GetScreenWidth()
        screenHeight = wndMgr.GetScreenHeight()

        x = primaryX + primaryWidth
        y = primaryY
        if x + compareWidth > screenWidth:
            # Falls off right -- flip to the LEFT of the primary.
            x = primaryX - compareWidth
        # Final clamp so the tooltip never renders off either edge, even when
        # the compare tooltip is wider than the screen or the primary sits
        # near a corner.
        if x < 0:
            x = 0
        if x + compareWidth > screenWidth:
            x = max(0, screenWidth - compareWidth)
        if y + compareHeight > screenHeight:
            y = screenHeight - compareHeight
        if y < 0:
            y = 0
        self.compareTooltip.SetPosition(x, y)
        self.compareTooltip.Show()
```

### Step 2: gate the compare hook inside `SetInventoryItem`

The compare path opt-in goes through a recursion guard (`allowCompare=False` when called from inside `SetCompareItem`) plus an input-modifier check so compare only shows while the modifier is held:

```python
def SetInventoryItem(self, slotIndex, window_type=player.INVENTORY, allowCompare=True):
    # ... existing body that builds the primary tooltip data ...
    if not app.ENABLE_COMPARE_TOOLTIP:
        return
    if not allowCompare:
        return
    if not app.IsPressed(app.DIK_LALT):
        return
    if slotIndex >= player.EQUIPMENT_SLOT_START:
        # Hovering an equipped slot -- nothing to compare against.
        return
    itemVnum = player.GetItemIndex(slotIndex)
    if itemVnum > 0:
        self.SetCompareItem(itemVnum)
```

The same hook can be added to `SetShopItem`, `SetSafeBoxItem`, and other `SetXxxItem` variants -- each call `SetCompareItem(itemVnum)` after building the primary tooltip data, gated by `app.IsPressed(app.DIK_LALT)`.

### Step 3: destroy hook in `interfacemodule.__DestroyDialogs`

Failure-atlas entry 28 documents the leak: if `interfacemodule` destroys `tooltipItem` but never destroys the lazy-built `compareTooltip`, the secondary widget orphans on every Interface teardown. Add the cleanup:

```python
def __DestroyDialogs(self):
    # ... existing destroy calls for tooltipItem, tooltipSkill, etc. ...
    if app.ENABLE_COMPARE_TOOLTIP:
        if self.tooltipItem is not None and self.tooltipItem.compareTooltip is not None:
            # Hide first so any in-flight render finishes against a still-
            # valid widget, then null the reference so WOC can tear down the
            # widget tree on the next frame.
            self.tooltipItem.compareTooltip.Hide()
            self.tooltipItem.compareTooltip = None
```

The compare instance does not own additional resources beyond its widget tree, so simple null-out is enough -- WOC handles the widget tree teardown via the standard `ItemToolTip` destroy path.

## Common variations

### Variation 1: Compare to currently-equipped same-slot-type (default)

The canonical form documented above. `item.GetCompareIndex(itemVnum)` returns the equipped slot of the matching slot type (e.g., hovering a sword resolves to the equipped weapon slot). Most useful for armor / weapons.

### Variation 2: Compare to player's best-stat in inventory

Replace `item.GetCompareIndex` with a custom helper that scans `player.INVENTORY` for the highest-tier same-type item. Useful for "is this drop better than what I have?" comparisons. Implementation hint: the helper iterates `range(player.INVENTORY_PAGE_SIZE * pages)`, calls `player.GetItemIndex(slot)`, computes a composite score from the item's stats, returns the slot of the max.

### Variation 3: Compare against tooltip-history (last viewed)

Maintain `interfacemodule.lastHoveredVnum`. On every `SetInventoryItem`, snapshot the current vnum into `lastHoveredVnum`. On the NEXT hover, render the previous tooltip alongside the current. Useful for chained-hover comparisons (browse two items in sequence; second hover shows both).

## Don't copy these obsolete bits

- **Missing `compareTooltip` destroy on Interface teardown (failure-atlas entry 28)** -- if `__DestroyDialogs` only destroys `self.tooltipItem` but ignores `self.tooltipItem.compareTooltip`, the second widget leaks on every teardown. Add the explicit destroy hook.
- **Shared `ItemToolTip` instance** -- some implementations reuse the primary `tooltipItem` for both roles by toggling display state. The primary's data gets overwritten when compare renders; user sees inconsistent state. Use a separate `compareTooltip` instance.
- **Missing `OverOutItem` clear** -- when the user moves the mouse off the slot, primary tooltip hides via `tooltipItem.HideToolTip()` but `compareTooltip` lingers. The anchor's `HideToolTip` body hides both.
- **Compare tooltip created per-hover (not lazy-once)** -- creating a new `ItemToolTip()` on every hover orphans the prior instance; widget count grows monotonically. Lazy-build once on first compare; reuse the instance via `SetInventoryItem` calls.
- **No screen-edge clamping** -- the compare tooltip rendering off the right edge means the user can't see it. Clamp to screen bounds; flip to the left side of the primary if right side overflows.
- **Recursion bomb** -- if `SetCompareItem` calls `SetInventoryItem(allowCompare=True)` on the compare instance, the compare instance triggers another `SetCompareItem`, which triggers another instance, etc. Break with `isCompareInstance` flag plus `allowCompare=False` parameter.
- **Modifier-key gating omitted** -- always-on compare bloats the screen. Gate on `app.IsPressed(app.DIK_LALT)` (or fork-equivalent) so compare only renders when the user opts in.
