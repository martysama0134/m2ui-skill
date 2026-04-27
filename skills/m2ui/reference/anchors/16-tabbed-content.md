# Anchor 16: Tabbed Content (Augmentor)

## What this is + when to use it

Multi-pane content swap driven by a radio-button group: clicking a tab raises the matching content window and hides all sibling content windows. Each tab is a `radio_button` widget bound to a per-tab callback that calls `Show()` / `Hide()` on the relevant content.

This is an AUGMENTOR — it layers multi-pane radio-button-driven tab switching onto any archetype with multiple logical sub-views (typically 08/09). Body content lives in section 7.

Use this augmentor when: a single window needs to display N alternative views (inventory pages, options categories, equipment loadouts). Do NOT use for single-page windows. Do NOT use for cascading sub-windows where the parent stays visible (those are dialogs-on-top, not tab swaps).

## Source

Pattern extracted from `pack/pack/root/uioption.py` (Game/Audio/Display tabs), `pack/pack/root/uiinventory.py` (inventory page tabs), and `pack/pack/root/uishop.py` (shop tab radios for 2-3 tab variants) from a real Metin2 fork. The canonical pattern uses `radio_button` widgets in uiscript, an array `self.tabButtons[]` in the class, and a `__SetTabIndex(idx)` method that toggles `Down()`/`SetUp()` and shows/hides matching content.

Two implementation styles exist:

1. **`SAFE_SetEvent` (Pattern E)** — fork-augmented helper. `button.SAFE_SetEvent(self.OnTabChange, idx)` wraps the bound method idempotently. Real source uses this for inventory tabs.
2. **`ui.RadioButtonGroup.Create` factory** — engine-provided helper. Takes a list of `[button, callback, ext]` triples and wires Up/Down semantics automatically. Real source uses this for shop tabs.

Anchor documents both — pick based on fork's `ui.py` capabilities.

Normalized to current m2ui rules:

- All tab callbacks via `SAFE_SetEvent` OR Pattern C proxy lambda. Pattern A (no extra args) doesn't work — the tab index is needed.
- Pattern B verification: `RadioButton.SetEvent` is `(self, event, *args)` per `pack/pack/root/ui.py` — see Critical Rule 19. Most forks ship `*args`-capable; if 1-arg only, augment per `framework-augmentations.md` OR fall back to Pattern C.
- Tab content stored as `self.tabContents = {0: window0, 1: window1, ...}` dict — switched on event by hiding all and showing one.
- ASCII-only

## Uiscript dict

Same as augmented archetype, plus the `radio_button` widgets for the tab strip (typically positioned along the top or bottom of the content area). Standard radio_button uiscript shape:

```python
{
    "name" : "Tab_01",
    "type" : "radio_button",

    "x" : 10, "y" : 33,

    "default_image" : "d:/ymir work/ui/game/windows/tab_button_large_01.sub",
    "over_image"    : "d:/ymir work/ui/game/windows/tab_button_large_02.sub",
    "down_image"    : "d:/ymir work/ui/game/windows/tab_button_large_03.sub",

    "tooltip_text" : uiScriptLocale.TAB_PAGE_1,

    "children" :
    (
        { "name" : "Tab_01_Print", "type" : "text", "x" : 0, "y" : 0, "all_align" : "center", "text" : uiScriptLocale.TAB_PAGE_1_LABEL },
    ),
}
```

Repeat per tab with `Tab_02`, `Tab_03`, etc. Canonical Metin2 inventory tabs typically render Roman numerals "I" / "II" / "III" — even those go through `uiScriptLocale.TAB_PAGE_N_LABEL` per Critical Rule 9 (no hardcoded user-visible strings). For category labels (Game / Audio / Display), the locale key is the category name itself. The Roman-numeral case is a glyph used as a label, not a UI ornament — locale wrapping costs little and keeps localization tooling consistent.

## Root class

Augmentor-only decoration: the augmented archetype keeps `self.tabButtons` (list of radio_button refs) and `self.tabContents` (dict of `{idx: contentWindow}`), plus an `OnTabChange(idx)` method that toggles `Down()`/`SetUp()` and `Show()`/`Hide()`. Full canonical pattern + N-tab loop variant + 3 other variations live in section 7 below. Section 7 is the canonical body for this augmentor; consuming windows pick the variation that matches their tab count and lazy-load needs.

## Locale entries

Augmentor-specific tab labels. Both the visible tab text AND the tooltip go through `uiScriptLocale` per Critical Rule 9:

```
TAB_PAGE_1	Page 1
TAB_PAGE_2	Page 2
TAB_PAGE_1_LABEL	I
TAB_PAGE_2_LABEL	II
TAB_GAME	Game
TAB_AUDIO	Audio
TAB_DISPLAY	Display
TAB_CONTROLS	Controls
```

Override per consuming archetype. The `_LABEL` variants exist so the visible glyph can be localized (e.g., a fork might prefer "1"/"2" over "I"/"II").

## interfacemodule.py integration snippet

Tabbed content is a class-internal concern; `interfacemodule` does NOT need additional wiring beyond what the archetype already requires. Tab content windows are children of the augmented window — they live and die with it.

If tab content windows themselves are independent windows (rare), bind them as separate `interfacemodule` properties:

```python
class Interface(object):

    def __init__(self):
        self.wndOptionsAudio = None
        self.wndOptionsDisplay = None
        self.wndOptionsControls = None

    def MakeInterface(self):
        self.wndOptionsAudio = uiOptionsAudio.AudioOptionsTab()
        self.wndOptionsDisplay = uiOptionsDisplay.DisplayOptionsTab()
        self.wndOptionsControls = uiOptionsControls.ControlsOptionsTab()
        # Pass to parent options dialog so its OnTabChange can swap them.
        self.dlgOptions.SetTabContents([
            self.wndOptionsAudio,
            self.wndOptionsDisplay,
            self.wndOptionsControls,
        ])
```

Most cases keep tab contents as inner widgets of the parent — no `interfacemodule` change needed.

## Common variations

This is where the augmentor's body content lives — the canonical pattern + five variations that adapt it per consuming window.

### Canonical pattern (Show/Hide content swap)

The default shape: tabs swap entire content windows via Show/Hide. Pick this when each tab has a dedicated content window already constructed.

```python
# In the augmented archetype's __LoadWindow:
self.tabButtons = []
for i in xrange(TAB_COUNT):
    btn = self.GetChild("Tab_%02d" % (i + 1))
    btn.SAFE_SetEvent(self.OnTabChange, i)
    self.tabButtons.append(btn)
self.tabButtons[0].Down()

# Tab content windows -- created at MakeInterface or in __LoadWindow:
self.tabContents = {
    0: self.wndPage1,
    1: self.wndPage2,
    2: self.wndPage3,
}
self.OnTabChange(0)

def OnTabChange(self, idx):
    for i, btn in enumerate(self.tabButtons):
        if i == idx:
            btn.Down()
        else:
            btn.SetUp()
    for i, content in self.tabContents.items():
        if i == idx:
            content.Show()
        else:
            content.Hide()
```

### Variation 1: Two tabs (inventory pages)

The simplest case. Two radio-buttons, each toggles between two slot-page indices. Used in equipment inventory (page I/II).

```python
self.equipmentTab = []
self.equipmentTab.append(self.GetChild("Equipment_Tab_01"))
self.equipmentTab.append(self.GetChild("Equipment_Tab_02"))
self.equipmentTab[0].SAFE_SetEvent(self.SetEquipmentPage, 0)
self.equipmentTab[1].SAFE_SetEvent(self.SetEquipmentPage, 1)
self.equipmentTab[0].Down()

def SetEquipmentPage(self, page):
    self.equipmentPageIndex = page
    self.equipmentTab[1 - page].SetUp()
    # Content swap: re-render slot grid for the new page.
    self.RefreshEquipSlotWindow()
```

### Variation 2: N tabs (loop-bound)

Multi-page inventory, where `player.INVENTORY_PAGE_COUNT` (engine binding) decides count.

```python
self.inventoryTab = []
for i in xrange(player.INVENTORY_PAGE_COUNT):
    self.inventoryTab.append(self.GetChild("Inventory_Tab_%02d" % (i + 1)))

for i in xrange(player.INVENTORY_PAGE_COUNT):
    self.inventoryTab[i].SAFE_SetEvent(self.SetInventoryPage, i)
self.inventoryTab[0].Down()

def SetInventoryPage(self, page):
    self.inventoryPageIndex = page
    for i in xrange(player.INVENTORY_PAGE_COUNT):
        if i != page:
            self.inventoryTab[i].SetUp()
    self.RefreshBagSlotWindow()
```

### Variation 3: Tabs with badge / notification dot

Tabs that show a notification dot when their content changed since last viewed.

```python
def SetTabNotification(self, idx, hasNew):
    # Each tab has a child "Tab_NN_Dot" expanded_image (red circle).
    dot = self.tabButtons[idx].GetChild("Tab_%02d_Dot" % (idx + 1))
    if hasNew and idx != self.activeTabIdx:
        dot.Show()
    else:
        dot.Hide()

def OnTabChange(self, idx):
    self.activeTabIdx = idx
    self.SetTabNotification(idx, False)  # Clear the dot when viewing.
    # ... rest of OnTabChange ...
```

Useful for inbox / quest list / chat tabs where unread state matters.

### Variation 4: Lazy-load tab content (construct on first view)

Defers tab-content construction until the user first clicks the tab. Saves startup memory at the cost of first-click latency.

```python
self.tabContents = {0: self.wndPage1}  # Only page 1 pre-built
self.tabFactories = {
    1: lambda r=proxy(self): r.__BuildPage2(),
    2: lambda r=proxy(self): r.__BuildPage3(),
}

def OnTabChange(self, idx):
    if idx not in self.tabContents:
        # Lazy construction.
        if idx in self.tabFactories:
            self.tabContents[idx] = self.tabFactories[idx]()

    for i, btn in enumerate(self.tabButtons):
        if i == idx:
            btn.Down()
        else:
            btn.SetUp()

    for i, content in self.tabContents.items():
        if i == idx:
            content.Show()
        else:
            content.Hide()
```

Use case: heavy tabs (full inventory grids, settings categories with many widgets). NOT for tabs with cheap content (a single text field) — the lazy-construct overhead exceeds the eager-construct cost.

### Variation 5: Programmatic tab buttons (created in code, not uiscript)

When tab count varies at runtime (e.g., safebox 1-3 pages based on server), tabs are created programmatically with `ui.RadioButton()`.

```python
def __MakePageButtons(self, pageCount):
    self.curPageIndex = 0
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
        # Pattern B: SetEvent with index arg. Verify *args support.
        button.SetEvent(ui.__mem_func__(self.SelectPage), i)
        button.Show()
        self.pageButtonList.append(button)

        pos += 52
        text += "I"

    if self.pageButtonList:
        self.pageButtonList[0].Down()
```

See `12-storage-warehouse.md` for the full programmatic-tab use case (safebox with server-determined page count).

## Don't copy these obsolete bits

- Real source uses `if i!=page: self.inventoryTab[i].SetUp()` (skip-the-active-tab pattern). Anchor preserves this — it's faster than unconditionally calling `SetUp()` on all then `Down()` on one (saves one widget-state mutation per tab change). For very small tab counts (2-3), the optimization is negligible.
- Some forks call `self.tabButtons[idx].Down()` from within the tab callback — but `Down()` is what fired the callback in the first place, so it's redundant. Anchor's `OnTabChange` doesn't re-call `Down()` on the active tab; the radio_button widget tracks state internally.
- Real source `inventoryTab` indexing uses `for i in xrange(player.INVENTORY_PAGE_COUNT)` — anchor preserves this. Hardcoding `range(2)` works for the canonical 2-page inventory but breaks if a fork extends to 3+ pages. Use the engine binding constant.
- Some forks use `RadioButtonGroup.Create([[btn1, cb1, ext1], [btn2, cb2, ext2]])` with `cb` being `lambda argSelf=proxy(self): argSelf.OnTabChange(0)`. Anchor's `SAFE_SetEvent` form is cleaner if available; `RadioButtonGroup.Create` is necessary when the engine's auto-Up/Down handling is needed (it cycles SetUp on all buttons except the clicked one automatically).
- Don't bind tab callbacks via `lambda: self.OnTabChange(N)` (self-capturing). This leaks `self` past `Destroy` — see event-binding.md Pattern C entry. Always use `lambda r=proxy(self): r.OnTabChange(N)` OR `SAFE_SetEvent`.
- Don't call `OnTabChange(0)` from within `__LoadWindow` BEFORE the tab content windows are created. The Show/Hide loop will operate on `None` refs. Order matters: create content → bind tabs → call `OnTabChange(0)` to set initial state.
