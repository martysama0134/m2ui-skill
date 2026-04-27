# Anchor 25: Expandable Grouped List (2-Level Tree)

## What this is + when to use it

A primary archetype for **expandable grouped lists**: vertical container of category headers, each header expandable to show a list of leaves. Click leaf -> dispatch to a parent-supplied callback. Stock `ui.ScrollBar` covers the scroll surface.

Use this archetype for: quest log (chapter -> quest), achievement / collection book (group -> collectible), settings tree (section -> option), event reward list (tier -> reward), item encyclopedia (class -> item leaf), guild / player info panel (category -> stat). Distinct from `02-board-with-list` (flat list) by virtue of expand / collapse + per-category position math. Distinct from `16-tabbed-content` (parallel tabs) by virtue of vertical-stack layout.

**This anchor is 2-level only.** See "Common variations" section 6 for an N-level extension note (with caveats).

## Source

Single peer implementation observed in a real Metin2 fork. Source-pattern: container window holds a `categories` list of `CategoryHeader` instances; each header tracks an `expanded` bool plus a list of leaf widgets. The source uses raw `self.parent.NotifySizeChange(...)` from the header to the container, which couples the header to whatever happens to be its parent at the time. The anchor parameterizes this as `self.layoutParent` (assigned at construction) so an N-level extension can propagate through a different parent chain without rebinding.

## Uiscript dict

`pack/pack/uiscript/uiscript/expandabletreelist.py`:

```python
window = {
    "name" : "ExpandableTreeList",
    "x" : 0,
    "y" : 0,
    "style" : ("movable", "float",),

    "width" : 600,
    "height" : 480,

    "children" :
    (
        {
            "name" : "board",
            "type" : "board_with_titlebar",
            "x" : 0,
            "y" : 0,
            "width" : 600,
            "height" : 480,
            "title" : uiScriptLocale.TREE_LIST_TITLE,

            "children" :
            (
                {
                    "name" : "content_thinboard",
                    "type" : "thinboard",
                    "x" : 14,
                    "y" : 36,
                    "width" : 558,
                    "height" : 430,
                },
                {
                    "name" : "scroll_bar_anchor",
                    "type" : "window",
                    "x" : 576,
                    "y" : 36,
                    "width" : 12,
                    "height" : 430,
                },
            ),
        },
    ),
}
```

## Root class

`pack/pack/root/uiexpandabletreelist.py`:

```python
import ui
import localeInfo
import uiScriptLocale
from _weakref import proxy


CATEGORY_PADDING = 5
HEADER_HEIGHT = 24
LEAF_HEIGHT = 20


class CategoryHeader(ui.Window):
    """One expandable category header with a list of leaves."""

    def __init__(self, layoutParent):
        ui.Window.__init__(self)
        self.layoutParent = layoutParent  # PROXY of the container, NOT raw self.parent
        self.expanded = False
        self.leaves = []
        self.SetSize(572, HEADER_HEIGHT)

        self.headerButton = ui.Button()
        self.headerButton.SetParent(self)
        self.headerButton.SetPosition(0, 0)
        self.headerButton.SetSize(572, HEADER_HEIGHT)
        self.headerButton.SetUpVisual("d:/ymir work/ui/public/parameter_slot_03.sub")
        self.headerButton.SetOverVisual("d:/ymir work/ui/public/parameter_slot_03.sub")
        self.headerButton.SetDownVisual("d:/ymir work/ui/public/parameter_slot_03.sub")
        self.headerButton.SetEvent(ui.__mem_func__(self.Toggle))
        self.headerButton.Show()

        self.titleText = ui.TextLine()
        self.titleText.SetParent(self.headerButton)
        self.titleText.SetPosition(8, 4)
        self.titleText.Show()

    def __del__(self):
        ui.Window.__del__(self)

    @ui.WindowDestroy
    def Destroy(self):
        if self.headerButton:
            self.headerButton.SetEvent(0)
        for leaf in self.leaves:
            if leaf is not None:
                leaf.Destroy()
        self.leaves = []
        self.layoutParent = None

    def SetTitle(self, text):
        self.titleText.SetText(text)

    def AddLeaf(self, text, clickCallback):
        leaf = ExpandableLeaf(self, len(self.leaves), text, clickCallback)
        leaf.SetPosition(16, HEADER_HEIGHT + len(self.leaves) * LEAF_HEIGHT)
        self.leaves.append(leaf)
        if not self.expanded:
            leaf.Hide()
        return leaf

    def Toggle(self):
        if self.expanded:
            self.Collapse()
        else:
            self.Expand()

    def Expand(self):
        if self.expanded:
            return
        self.expanded = True
        for leaf in self.leaves:
            leaf.Show()
        delta = len(self.leaves) * LEAF_HEIGHT
        self.SetSize(self.GetWidth(), HEADER_HEIGHT + delta)
        if self.layoutParent is not None:
            self.layoutParent.NotifySizeChange(self, delta, True)

    def Collapse(self):
        if not self.expanded:
            return
        self.expanded = False
        for leaf in self.leaves:
            leaf.Hide()
        delta = len(self.leaves) * LEAF_HEIGHT
        self.SetSize(self.GetWidth(), HEADER_HEIGHT)
        if self.layoutParent is not None:
            self.layoutParent.NotifySizeChange(self, -delta, False)


class ExpandableLeaf(ui.Window):
    """One leaf row inside a CategoryHeader."""

    def __init__(self, header, index, text, clickCallback):
        ui.Window.__init__(self)
        self.SetParent(header)
        self.index = index
        self.SetSize(556, LEAF_HEIGHT)

        self.button = ui.Button()
        self.button.SetParent(self)
        self.button.SetPosition(0, 0)
        self.button.SetSize(556, LEAF_HEIGHT)
        self.button.SetText(text)
        # Pattern C: bind to a proxy of the header + captured callback so
        # the leaf does not store a strong bound method back to header.
        self.button.SetEvent(
            lambda r=proxy(header), idx=index, cb=clickCallback: cb(idx) if cb is not None else None
        )
        self.button.Show()

    def __del__(self):
        ui.Window.__del__(self)

    @ui.WindowDestroy
    def Destroy(self):
        if self.button:
            self.button.SetEvent(0)


class ExpandableTreeList(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.__Initialize()
        self.__LoadWindow()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def __Initialize(self):
        self.contentBoard = None
        self.scrollBar = None
        self.categories = []
        self.totalContentHeight = 0

    def __LoadWindow(self):
        try:
            self.LoadScriptFile("uiscript/expandabletreelist.py")
        except:
            import exception
            exception.Abort("ExpandableTreeList.__LoadWindow.LoadScriptFile")

        try:
            self.contentBoard = self.GetChild("content_thinboard")
            scrollBarChild = self.GetChild("scroll_bar_anchor")
            self.scrollBar = ui.ScrollBar()
            self.scrollBar.SetParent(scrollBarChild)
            self.scrollBar.SetScrollEvent(ui.__mem_func__(self.OnScroll))
            self.scrollBar.Show()
        except:
            import exception
            exception.Abort("ExpandableTreeList.__LoadWindow.BindObject")

    # ---- Lifecycle ----

    def Open(self):
        self.SetCenterPosition()
        self.SetTop()
        self.Show()

    def Close(self):
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True

    @ui.WindowDestroy
    def Destroy(self):
        for cat in self.categories:
            if cat is not None:
                cat.Destroy()
        self.categories = []
        if self.scrollBar:
            self.scrollBar.SetScrollEvent(0)
        self.ClearDictionary()
        self.__Initialize()

    # ---- API ----

    def AddCategory(self, text):
        header = CategoryHeader(proxy(self))
        header.SetParent(self.contentBoard)
        header.SetTitle(text)
        # Position immediately below previous category.
        if len(self.categories) > 0:
            prev = self.categories[-1]
            (prevX, prevY) = prev.GetLocalPosition()
            yPos = prevY + prev.GetHeight() + CATEGORY_PADDING
        else:
            yPos = 0
        header.SetPosition(0, yPos)
        header.Show()
        self.categories.append(header)
        self.totalContentHeight = yPos + header.GetHeight()
        self.__RefreshScrollRange()
        return header

    def NotifySizeChange(self, srcHeader, delta, expanded):
        # Walk categories AFTER srcHeader's index; shift each by delta.
        try:
            srcIndex = self.categories.index(srcHeader)
        except ValueError:
            return
        for cat in self.categories[srcIndex + 1:]:
            (x, y) = cat.GetLocalPosition()
            cat.SetPosition(x, y + delta)
        self.totalContentHeight += delta
        self.__RefreshScrollRange()

    def __RefreshScrollRange(self):
        # Configure the scroll bar's middle-bar size based on the visible
        # height vs total content height. SetMiddleBarSize(1.0) means the
        # bar fills the track (no scroll needed).
        if self.scrollBar is None or self.contentBoard is None:
            return
        visible = self.contentBoard.GetHeight()
        if self.totalContentHeight > visible:
            self.scrollBar.SetMiddleBarSize(float(visible) / float(self.totalContentHeight))
        else:
            self.scrollBar.SetMiddleBarSize(1.0)

    def OnScroll(self):
        # Translate scrollBar.GetPos() (0..1) into a vertical offset for
        # the categories. Variation 5 (sticky-scroll on expand) replaces
        # this with a baseline tracker so expand does not visually jump.
        if self.scrollBar is None or self.contentBoard is None:
            return
        if self.totalContentHeight <= self.contentBoard.GetHeight():
            return
        pos = self.scrollBar.GetPos()
        scrollOffset = -int(pos * (self.totalContentHeight - self.contentBoard.GetHeight()))
        cumulativeY = scrollOffset
        for cat in self.categories:
            (x, _) = cat.GetLocalPosition()
            cat.SetPosition(x, cumulativeY)
            cumulativeY += cat.GetHeight() + CATEGORY_PADDING
```

## Locale entries

```
TREE_LIST_TITLE                 List
TREE_LIST_NO_DATA               No entries.
```

## interfacemodule.py integration snippet

```python
import uiexpandabletreelist

self.wndTreeList = None  # lazy-built

def ToggleTreeList(self):
    if self.wndTreeList is None:
        self.wndTreeList = uiexpandabletreelist.ExpandableTreeList()
        # Populate categories at build time OR via a Refresh() call after
        # server data arrives. Categories persist across Open/Close.
        catA = self.wndTreeList.AddCategory("Category A")
        catA.AddLeaf("Leaf A1", self.OnLeafClick)
        catA.AddLeaf("Leaf A2", self.OnLeafClick)
        catB = self.wndTreeList.AddCategory("Category B")
        catB.AddLeaf("Leaf B1", self.OnLeafClick)
    if self.wndTreeList.IsShow():
        self.wndTreeList.Close()
    else:
        self.wndTreeList.Open()

def OnLeafClick(self, leafIndex):
    # Dispatch on (category, leaf) -- in a real consumer the callback is
    # bound at AddLeaf time to capture the (catKey, leafKey) tuple.
    pass
```

## Common variations

1. **Icon per row** -- prefix header / leaf with a `ui.ImageBox`; reduce the button width by the icon width and offset the title text.
2. **Click leaf -> custom callback** -- canonical; covered by the anchor body via `AddLeaf(text, clickCallback)`. Each leaf captures its callback in the `lambda` closure.
3. **Pre-expanded categories** -- after `AddLeaf` for a category, call `header.Expand()` to start expanded. Useful when one category should be open by default.
4. **Gated leaves (greyed / disabled)** -- guard inside the leaf callback (early-return if disabled), or set `leaf.button.Disable()` after `AddLeaf` returns. Disabled leaves still render but no longer dispatch.
5. **Sticky-scroll on expand** -- replace `OnScroll` with a baseline-tracker: store the scroll position before `Expand` / `Collapse` and re-apply after `NotifySizeChange` so the user does not see the list jump.
6. **N-level extension note (escape hatch).** Replace each header's `leaves[]` with a list of `CategoryHeader` instances and propagate `NotifySizeChange` up the parent chain (each child header's `layoutParent` is its parent header, not the root container). Use this for expandable grouped lists with deeper structure -- NOT for arbitrary filesystem-style trees. Caveat: ymir UI has no reflow; one missed height invalidation causes overlapping rows or stale click rects. Only attempt N-level if your fork actually has deeper data; otherwise stay 2-level.

## Don't copy these obsolete bits

- **N-level recursion attempt without a manual layout pass** -- ymir UI has no reflow. Each level adds a propagation hop that must update every ancestor's `totalContentHeight` AND each subsequent sibling's position. A missed step yields overlapping rows or stale click rects. Stay 2-level unless your data demands deeper.
- **Storing `self.parent` directly instead of an explicit `layoutParent` reference** -- couples the header to whichever parent happens to be set at construction. If the container is wrapped (e.g., placed inside a thinboard child), `self.parent` no longer points to the container that owns `NotifySizeChange`. The anchor uses an explicit `layoutParent` proxy passed at construction.
- **Bare bound methods on header / leaf click handlers** -- `btn.SetEvent(self.Toggle)` leaks `self`. Use `ui.__mem_func__()` (header) or a `lambda r=proxy(header), ...` capturing pattern (leaf) per Critical Rule 5 + `event-binding.md`.
- **Stale layout / refs after Collapse if `NotifySizeChange` isn't propagated** -- categories below the collapsed one stay at the old (expanded) y-position; clicks fall on stale rects above. The container's `NotifySizeChange` MUST run on every Expand AND every Collapse.
- **Iterating `self.categories` and clearing the list without `Destroy()` on each** -- generic owned-widget-list cleanup leak (failure-atlas entry 29 family). Each category owns leaves + tooltips + child handlers; the container's `Destroy()` MUST loop and call `cat.Destroy()` before assigning `self.categories = []`.
