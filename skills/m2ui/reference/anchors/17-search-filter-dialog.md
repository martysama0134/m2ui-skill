# Anchor 17: Search / Filter Dialog with Results List

## What this is + when to use it

A primary archetype for **server-driven search dialogs**: the user provides FILTERING input (combos, text fields, level ranges) and receives PAGINATED RESULTS pushed back from the server. Use this anchor for any window where the player applies a filter, hits Search, and waits for the server to return a list.

Real-fork examples of this archetype include offline-shop search ("find item X across other players' shops"), party-finder LFG lists, item-shop search, and friend-finder. The chrome is consistently: title bar + filter row (combos / EditLines) + Search button + paginated results listbox + per-result tooltip.

This is distinct from `02-board-with-list` (which is a passive-display dynamic list) by virtue of the FILTER+SEARCH semantic and the server-roundtrip lifecycle. It is also distinct from `10-paginated-slot-grid` (offline-shop builder, where the player STORES items into their own grid) — anchor 17 is the searcher side, not the builder side.

Layer `15-network-coupled-flow` for the request-response variant 2 contract (Send → external Recv handler → setter on this window). Layer `16-tabbed-content` if the filter has multiple tab categories (e.g., "items" / "shops" / "players").

## Source

Patterns synthesized from 5 peer implementations of search-filter dialogs found in real Metin2 forks. Common chrome shape across all five: board + filter row + Search button + paginated results listbox + per-result tooltip on hover. Common anti-pattern surfaced: synchronous list-refresh after Send (the `Search()` body wipes the prior list and populates from the external `privateShop` C++ singleton, leaving the user staring at the cleared list until the Recv handler arrives). The anchor below uses an `isSearchPending` guard plus a "Searching..." overlay so the gap between Send and Recv is communicated to the user.

## Uiscript dict

`pack/pack/uiscript/uiscript/searchdialog.py`:

```python
window = {
    "name" : "SearchDialog",
    "x" : 0,
    "y" : 0,
    "style" : ("movable", "float",),

    "width" : 460,
    "height" : 480,

    "children" :
    (
        {
            "name" : "board",
            "type" : "board_with_titlebar",
            "x" : 0,
            "y" : 0,
            "width" : 460,
            "height" : 480,
            "title" : uiScriptLocale.SEARCH_TITLE,

            "children" :
            (
                # ----- Filter row -----
                {
                    "name" : "filter_name_label",
                    "type" : "text",
                    "x" : 18,
                    "y" : 38,
                    "text" : uiScriptLocale.SEARCH_NAME_LABEL,
                    "not_pick" : 1,
                },
                {
                    "name" : "filter_name_edit",
                    "type" : "editline",
                    "x" : 90,
                    "y" : 36,
                    "width" : 160,
                    "height" : 18,
                    "input_limit" : 24,
                    "with_codepage" : 1,
                },
                {
                    "name" : "filter_category_label",
                    "type" : "text",
                    "x" : 18,
                    "y" : 64,
                    "text" : uiScriptLocale.SEARCH_CATEGORY_LABEL,
                    "not_pick" : 1,
                },
                # filter_category_combo and filter_level_combo are built
                # programmatically from the root class; placeholder anchors here
                # only.
                {
                    "name" : "filter_level_label",
                    "type" : "text",
                    "x" : 18,
                    "y" : 90,
                    "text" : uiScriptLocale.SEARCH_LEVEL_LABEL,
                    "not_pick" : 1,
                },

                # ----- Search / Reset buttons -----
                {
                    "name" : "search_button",
                    "type" : "button",
                    "x" : 270,
                    "y" : 60,
                    "text" : uiScriptLocale.SEARCH_BUTTON,
                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },
                {
                    "name" : "reset_button",
                    "type" : "button",
                    "x" : 360,
                    "y" : 60,
                    "text" : uiScriptLocale.SEARCH_RESET_BUTTON,
                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },

                # ----- Status overlay -----
                {
                    "name" : "status_text",
                    "type" : "text",
                    "x" : 18,
                    "y" : 120,
                    "text" : "",
                    "not_pick" : 1,
                },

                # ----- Results region (slots inserted programmatically) -----
                {
                    "name" : "results_thinboard",
                    "type" : "thinboard",
                    "x" : 14,
                    "y" : 142,
                    "width" : 432,
                    "height" : 280,
                },

                # ----- Pagination -----
                {
                    "name" : "page_prev_button",
                    "type" : "button",
                    "x" : 14,
                    "y" : 432,
                    "text" : "<",
                    "default_image" : "d:/ymir work/ui/public/small_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/small_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/small_button_03.sub",
                },
                {
                    "name" : "page_next_button",
                    "type" : "button",
                    "x" : 416,
                    "y" : 432,
                    "text" : ">",
                    "default_image" : "d:/ymir work/ui/public/small_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/small_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/small_button_03.sub",
                },
                {
                    "name" : "page_label",
                    "type" : "text",
                    "x" : 200,
                    "y" : 436,
                    "text" : "",
                    "horizontal_align" : "center",
                    "not_pick" : 1,
                },
            ),
        },
    ),
}
```

## Root class

`pack/pack/root/uisearchdialog.py`:

```python
import ui
import net
import app
import chat
import localeInfo
import uiScriptLocale
import constInfo

RESULTS_PER_PAGE = 8
SEARCH_COOLDOWN_SECONDS = 1


class SearchDialog(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.__Initialize()
        self.__LoadWindow()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def __Initialize(self):
        # Filter inputs
        self.nameEdit = None
        self.categoryCombo = None
        self.levelCombo = None
        self.searchButton = None
        self.resetButton = None

        # Results region
        self.resultsBoard = None
        self.resultRows = []     # row widgets (built once at LoadWindow)
        self.statusText = None

        # Pagination
        self.pagePrevButton = None
        self.pageNextButton = None
        self.pageLabel = None

        # State
        self.filterDict = {}
        self.resultList = []     # list of result records pushed by server
        self.currentPage = 0
        self.totalPages = 0
        self.totalCount = 0
        self.selectedIndex = -1
        self.isSearchPending = False
        self.lastSearchTime = 0
        self.toolTipItem = None

    def __LoadWindow(self):
        try:
            self.LoadScriptFile("uiscript/searchdialog.py")
        except:
            import exception
            exception.Abort("SearchDialog.__LoadWindow.LoadScriptFile")

        try:
            self.nameEdit = self.GetChild("filter_name_edit")
            self.searchButton = self.GetChild("search_button")
            self.resetButton = self.GetChild("reset_button")
            self.resultsBoard = self.GetChild("results_thinboard")
            self.statusText = self.GetChild("status_text")
            self.pagePrevButton = self.GetChild("page_prev_button")
            self.pageNextButton = self.GetChild("page_next_button")
            self.pageLabel = self.GetChild("page_label")
        except:
            import exception
            exception.Abort("SearchDialog.__LoadWindow.BindObject")

        # EditLine return-event: Pattern B requires Critical Rule 19 verification.
        # SetReturnEvent on EditLine is commonly 1-arg-only in stock ui.py, so
        # this anchor uses Pattern C (proxy lambda). If the fork augmented
        # EditLine.SetReturnEvent to accept *args, switch to Pattern B.
        from _weakref import proxy
        self.nameEdit.SetReturnEvent(lambda r=proxy(self): r.OnSearch())
        self.nameEdit.SetEscapeEvent(lambda r=proxy(self): r.Close())

        self.searchButton.SetEvent(ui.__mem_func__(self.OnSearch))
        self.resetButton.SetEvent(ui.__mem_func__(self.OnReset))
        self.pagePrevButton.SetEvent(ui.__mem_func__(self.OnPrevPage))
        self.pageNextButton.SetEvent(ui.__mem_func__(self.OnNextPage))

        # Pre-allocate result row widgets once. RefreshResults walks them and
        # calls SetText/Show -- never destroy + recreate (failure-atlas 26).
        self.__BuildResultRows()
        self.__BuildFilterCombos()

    def __BuildResultRows(self):
        for index in range(RESULTS_PER_PAGE):
            row = ui.Button()
            row.SetParent(self.resultsBoard)
            row.SetPosition(8, 8 + index * 32)
            row.SetSize(416, 28)
            row.SetUpVisual("d:/ymir work/ui/public/parameter_slot_03.sub")
            row.SetOverVisual("d:/ymir work/ui/public/parameter_slot_03.sub")
            row.SetDownVisual("d:/ymir work/ui/public/parameter_slot_03.sub")
            from _weakref import proxy
            row.SetEvent(lambda r=proxy(self), idx=index: r.OnSelectResult(idx))
            row.SetText("")
            row.Hide()
            self.resultRows.append(row)

    def __BuildFilterCombos(self):
        # Combos built programmatically. The exact widget class depends on
        # whether the fork ships ui.ComboBox or a custom DropDownList; verify
        # against widgets.md before swapping.
        # TODO: verify ui.ComboBox availability in your fork (see widgets.md).
        pass

    # ---- Lifecycle ----

    def Open(self):
        self.__ResetFilters()
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
        if self.searchButton:
            self.searchButton.SetEvent(0)
        if self.resetButton:
            self.resetButton.SetEvent(0)
        if self.pagePrevButton:
            self.pagePrevButton.SetEvent(0)
        if self.pageNextButton:
            self.pageNextButton.SetEvent(0)
        for row in self.resultRows:
            row.SetEvent(0)
        self.ClearDictionary()
        self.__Initialize()

    # ---- Search flow ----

    def OnSearch(self):
        # Cooldown guard: prevent spam-click flooding the server.
        now = app.GetGlobalTimeStamp()
        if (now - self.lastSearchTime) < SEARCH_COOLDOWN_SECONDS:
            return
        self.lastSearchTime = now

        # Pending guard: only one search in flight at a time.
        if self.isSearchPending:
            return

        self.filterDict = self.__BuildFilterDict()
        if not self.filterDict:
            chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.SEARCH_FILTER_REQUIRED)
            return

        # Clear UI before sending. Result rows hide; status text shows
        # "Searching..." until the Recv handler resolves the pending flag.
        self.resultList = []
        self.currentPage = 0
        self.totalPages = 0
        self.totalCount = 0
        self.selectedIndex = -1
        for row in self.resultRows:
            row.Hide()
        self.statusText.SetText(localeInfo.SEARCH_PENDING)
        self.isSearchPending = True

        # TODO: verify net.SendSearchPacket exists in your fork (bindings.md).
        # The exact send name in real forks varies (e.g., for offline-shop
        # search the canonical name is net.SendPrivateShopSearchPacket).
        net.SendSearchPacket(self.filterDict)

    def OnReset(self):
        self.__ResetFilters()

    def __ResetFilters(self):
        if self.nameEdit:
            self.nameEdit.SetText("")
        self.filterDict = {}
        self.resultList = []
        self.currentPage = 0
        self.totalPages = 0
        self.totalCount = 0
        self.selectedIndex = -1
        for row in self.resultRows:
            row.Hide()
        self.statusText.SetText("")
        self.isSearchPending = False

    def __BuildFilterDict(self):
        # Aggregate filter inputs into a dict the server can consume. Empty
        # inputs are omitted so the server can interpret missing keys as
        # "no constraint".
        filters = {}
        if self.nameEdit:
            text = self.nameEdit.GetText()
            if text and len(text) > 0:
                filters["name"] = text
        # category and level extraction depend on combo widget; left as TODO
        # so the consuming fork can wire its specific combo class.
        return filters

    # ---- Recv side ----

    def OnRecvSearchResults(self, rows, totalCount):
        # Called externally by the network module's Recv handler (see
        # 15-network-coupled-flow). Populates the result list and refreshes
        # the current page.
        self.resultList = list(rows) if rows else []
        self.totalCount = int(totalCount)
        if RESULTS_PER_PAGE > 0:
            self.totalPages = (self.totalCount + RESULTS_PER_PAGE - 1) // RESULTS_PER_PAGE
        else:
            self.totalPages = 0
        self.currentPage = 0
        self.isSearchPending = False
        if self.totalCount == 0:
            self.statusText.SetText(localeInfo.SEARCH_NO_RESULTS)
        else:
            self.statusText.SetText("")
        self.RefreshResults()

    def RefreshResults(self):
        start = self.currentPage * RESULTS_PER_PAGE
        end = start + RESULTS_PER_PAGE
        visible = self.resultList[start:end]

        for index, row in enumerate(self.resultRows):
            if index < len(visible):
                record = visible[index]
                # The record shape is fork-specific; the canonical shape used
                # by the existing offline-shop sources is
                # (item_vnum, seller_name, count, gold, cheque). Swap field
                # extraction to match your server's payload.
                label = self.__FormatResultLabel(record)
                row.SetText(label)
                row.Show()
            else:
                row.Hide()

        if self.totalPages > 0:
            self.pageLabel.SetText(localeInfo.SEARCH_PAGE_FORMAT % (self.currentPage + 1, self.totalPages))
        else:
            self.pageLabel.SetText("")

    def __FormatResultLabel(self, record):
        # Extracts a user-visible row label from a server-pushed record. Keep
        # this method pure (no widget side-effects) so test harnesses can
        # round-trip it.
        try:
            seller = record[1]
            return str(seller)
        except (IndexError, TypeError):
            return ""

    # ---- Pagination ----

    def OnPrevPage(self):
        if self.currentPage > 0:
            self.currentPage -= 1
            self.RefreshResults()

    def OnNextPage(self):
        if (self.currentPage + 1) < self.totalPages:
            self.currentPage += 1
            self.RefreshResults()

    # ---- Selection ----

    def OnSelectResult(self, rowIndex):
        absoluteIndex = self.currentPage * RESULTS_PER_PAGE + rowIndex
        if absoluteIndex < 0 or absoluteIndex >= len(self.resultList):
            return
        self.selectedIndex = absoluteIndex
        # Optional: dispatch a per-row event handler to the consuming
        # interface module (e.g., open a confirmation dialog for buy).
```

## Locale entries

Append to your fork's locale interface table (uppercase keys per `locale.md` Naming Convention):

```
SEARCH_TITLE                Search
SEARCH_NAME_LABEL           Name
SEARCH_CATEGORY_LABEL       Category
SEARCH_LEVEL_LABEL          Level
SEARCH_BUTTON               Search
SEARCH_RESET_BUTTON         Reset
SEARCH_NO_RESULTS           No results found.
SEARCH_PENDING              Searching...
SEARCH_PAGE_FORMAT          Page %d / %d
SEARCH_FILTER_REQUIRED      Apply at least one filter before searching.
```

`SEARCH_PAGE_FORMAT` uses two `%d` placeholders -- keep the substitution shape stable across translations.

## interfacemodule.py integration snippet

```python
# In MakeInterface() or equivalent setup
import uisearchdialog

self.dlgSearch = None  # lazy-built on first toggle

def ToggleSearchDialog(self):
    if self.dlgSearch is None:
        self.dlgSearch = uisearchdialog.SearchDialog()
        self.dlgSearch.BindInterface(self)
    if self.dlgSearch.IsShow():
        self.dlgSearch.Close()
    else:
        self.dlgSearch.Open()

# In the network module's Recv handler dispatch
def OnRecvSearchResults(rows, totalCount):
    if interface.dlgSearch is not None:
        interface.dlgSearch.OnRecvSearchResults(rows, totalCount)
```

Lazy-build is appropriate for search dialogs because they are typically opened from a menu button, not always-on. Eagerly building on `MakeInterface` is also acceptable if the window is high-frequency in your fork.

## Common variations

### Variation 1: Text-only search (no combos)

Drop the `categoryCombo` / `levelCombo` widgets and the `__BuildFilterCombos` method. `__BuildFilterDict` returns just `{"name": text}`. Useful for character-name search, friend-finder, message-recipient picker.

### Variation 2: Multi-tab search (categories across tabs)

Wrap the filter row in a tab strip and switch the visible filter row per tab. See `16-tabbed-content.md` for the radio-group pattern. Each tab has its own filter shape; `OnSearch` reads `self.activeTab` and dispatches to the per-tab `__BuildFilterDict_<tab>` method.

### Variation 3: Save-recent-searches (LRU history)

Maintain `self.recentSearches = []` capped at N. On `OnSearch`, prepend the current `filterDict` (deduped). Render under the filter row as a "Recent" dropdown that re-applies the filter on click.

### Variation 4: Inline filter without server roundtrip

For small lists already loaded client-side, skip `net.SendSearchPacket` and run the filter against `self.fullList` locally:

```python
def OnSearch(self):
    self.filterDict = self.__BuildFilterDict()
    self.resultList = [r for r in self.fullList if self.__MatchesFilter(r)]
    self.totalCount = len(self.resultList)
    self.currentPage = 0
    self.RefreshResults()
```

The pending guard and "Searching..." overlay are unnecessary in this variation -- the result is computed synchronously.

### Variation 5: Cooldown-driven Search button

Disable the Search button during cooldown and re-enable in `OnUpdate`. Mirrors the rate-limit pattern used by real-fork shop-search dialogs:

```python
SEARCH_COOLDOWN_SECONDS = 1

def OnUpdate(self):
    if self.lastSearchTime > 0:
        elapsed = app.GetGlobalTimeStamp() - self.lastSearchTime
        if elapsed >= SEARCH_COOLDOWN_SECONDS:
            if not self.searchButton.IsEnabled():
                self.searchButton.Enable()
                self.searchButton.SetUp()
```

Cross-link: `timer-patterns.md` section 4 (check-interval).

## Don't copy these obsolete bits

- **Synchronous list refresh after `Send`** -- old offline-shop sources call `RefreshList()` immediately after `net.SendPrivateShopSearchPacket(...)` reading from a C++ singleton populated by an earlier search. The user sees the previous filter's results until the new Recv arrives. Use the `isSearchPending` + status-overlay pattern instead.
- **Hardcoded result-row count** -- some sources spell out 8 result widgets by literal `Result1` / `Result2` / ... names in the uiscript dict. The anchor uses `__BuildResultRows()` programmatically with a `RESULTS_PER_PAGE` constant so the page size is one number to change.
- **Missing escape-key handler** -- one survey source omitted `OnPressEscapeKey`, so pressing Escape closed the GAME's main menu instead of the dialog. Always emit `OnPressEscapeKey` returning `True`.
- **Reading filter inputs at Recv time instead of Send time** -- if `OnRecvSearchResults` re-reads `self.nameEdit.GetText()`, a fast user can change the filter between Send and Recv and see results that don't match the current filter UI. Snapshot the filter into `self.filterDict` at Send time; render Recv results against that snapshot.
- **Mixing search and buy in the same dialog without a confirmation step** -- the Search dialog is for browsing; commit actions (buy / contact / accept) belong in a separate `uiCommon.QuestionDialog` so accidental clicks don't spend gold.
- **Bare bound methods on row buttons** -- `row.SetEvent(self.OnSelectResult)` without `ui.__mem_func__` (or a proxy lambda for index capture) leaks `self` into every row widget. Use `lambda r=proxy(self), idx=index: r.OnSelectResult(idx)` so the row holds only a weak proxy.
