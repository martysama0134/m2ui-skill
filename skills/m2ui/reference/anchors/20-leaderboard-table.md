# Anchor 20: Leaderboard / Rank Table

## What this is + when to use it

A primary archetype for **fixed-column rank tables**. Window shows a header row + N pre-allocated data rows + Prev/Next pagination + Refresh button + a "My rank" pinned row. Refresh strategy is ROW-POOL: row widgets are created once at LoadWindow time and reused on every refresh by walking the rows and calling `SetText` on existing widgets -- never destroy + recreate per refresh (failure-atlas entry 26 mitigation).

Use this archetype for: PvP rankings, guild leaderboards, achievement leaderboards, tournament brackets, race-completion tables. Distinct from `02-board-with-list` (dynamic list using `ListBoxEx`) by virtue of FIXED COLUMNS plus the row-pool refresh strategy.

Layer `15-network-coupled-flow` for the Send → Recv contract. Optionally pair with the broadcast-update variant if your server pushes ranking updates without a client request (e.g., guild-rank changes).

## Source

Patterns synthesized from 2 peer implementations of rank / bracket tables in real Metin2 forks. Common shape: pre-allocated row widgets indexed by `(line, slotIndex)` where slotIndex enumerates the columns (rank, name, level, guild, score, ...). Common anti-patterns surfaced and corrected in this anchor: `Destory()` typo for `Destroy()` in one source (the anchor uses the canonical name + `@ui.WindowDestroy`), state-clearing duplicated between `__del__` and `Destroy()` (the anchor consolidates into `__Initialize()`).

## Uiscript dict

`pack/pack/uiscript/uiscript/leaderboard.py`:

```python
window = {
    "name" : "LeaderboardWindow",
    "x" : 0,
    "y" : 0,
    "style" : ("movable", "float",),

    "width" : 480,
    "height" : 480,

    "children" :
    (
        {
            "name" : "board",
            "type" : "board_with_titlebar",
            "x" : 0,
            "y" : 0,
            "width" : 480,
            "height" : 480,
            "title" : uiScriptLocale.LEADERBOARD_TITLE,

            "children" :
            (
                # ----- Header row -----
                {
                    "name" : "header_thinboard",
                    "type" : "thinboard",
                    "x" : 14,
                    "y" : 36,
                    "width" : 452,
                    "height" : 22,
                },
                {
                    "name" : "header_rank_label",
                    "type" : "text",
                    "x" : 30,
                    "y" : 40,
                    "text" : uiScriptLocale.LEADERBOARD_HEADER_RANK,
                    "not_pick" : 1,
                },
                {
                    "name" : "header_name_label",
                    "type" : "text",
                    "x" : 90,
                    "y" : 40,
                    "text" : uiScriptLocale.LEADERBOARD_HEADER_NAME,
                    "not_pick" : 1,
                },
                {
                    "name" : "header_level_label",
                    "type" : "text",
                    "x" : 240,
                    "y" : 40,
                    "text" : uiScriptLocale.LEADERBOARD_HEADER_LEVEL,
                    "not_pick" : 1,
                },
                {
                    "name" : "header_score_label",
                    "type" : "text",
                    "x" : 320,
                    "y" : 40,
                    "text" : uiScriptLocale.LEADERBOARD_HEADER_SCORE,
                    "not_pick" : 1,
                },

                # ----- Rows region -----
                {
                    "name" : "rows_thinboard",
                    "type" : "thinboard",
                    "x" : 14,
                    "y" : 64,
                    "width" : 452,
                    "height" : 320,
                },

                # ----- My-rank pinned row -----
                {
                    "name" : "my_rank_thinboard",
                    "type" : "thinboard",
                    "x" : 14,
                    "y" : 392,
                    "width" : 452,
                    "height" : 26,
                },

                # ----- Pagination + Refresh -----
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
                    "x" : 64,
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
                {
                    "name" : "refresh_button",
                    "type" : "button",
                    "x" : 380,
                    "y" : 432,
                    "text" : uiScriptLocale.LEADERBOARD_REFRESH_BUTTON,
                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },
            ),
        },
    ),
}
```

## Root class

`pack/pack/root/uileaderboard.py`:

```python
import ui
import net
import app
import player
import localeInfo
import uiScriptLocale
import constInfo
from _weakref import proxy

ROWS_PER_PAGE = 12
ROW_HEIGHT = 26

# Column indices into the per-row text widget tuple.
COL_RANK = 0
COL_NAME = 1
COL_LEVEL = 2
COL_SCORE = 3
COL_COUNT = 4


class LeaderboardWindow(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.__Initialize()
        self.__LoadWindow()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def __Initialize(self):
        # Chrome
        self.headerBoard = None
        self.rowsBoard = None
        self.myRankBoard = None
        self.pagePrevButton = None
        self.pageNextButton = None
        self.pageLabel = None
        self.refreshButton = None

        # Row pool: list of (rowButton, [textCol0, textCol1, ...]) tuples.
        # Pre-allocated at LoadWindow; reused on refresh.
        self.rowWidgets = []
        # My-rank row: same column layout as a regular row.
        self.myRankWidgets = []

        # State
        self.rows = []                # list of records (rank, name, level, score, ...)
        self.totalCount = 0
        self.currentPage = 0
        self.totalPages = 0
        self.myRankRecord = None
        self.isLoadPending = False

    def __LoadWindow(self):
        try:
            self.LoadScriptFile("uiscript/leaderboard.py")
        except:
            import exception
            exception.Abort("LeaderboardWindow.__LoadWindow.LoadScriptFile")

        try:
            self.headerBoard = self.GetChild("header_thinboard")
            self.rowsBoard = self.GetChild("rows_thinboard")
            self.myRankBoard = self.GetChild("my_rank_thinboard")
            self.pagePrevButton = self.GetChild("page_prev_button")
            self.pageNextButton = self.GetChild("page_next_button")
            self.pageLabel = self.GetChild("page_label")
            self.refreshButton = self.GetChild("refresh_button")
        except:
            import exception
            exception.Abort("LeaderboardWindow.__LoadWindow.BindObject")

        self.pagePrevButton.SetEvent(ui.__mem_func__(self.OnPrevPage))
        self.pageNextButton.SetEvent(ui.__mem_func__(self.OnNextPage))
        self.refreshButton.SetEvent(ui.__mem_func__(self.OnRefresh))

        self.__BuildRowPool()
        self.__BuildMyRankRow()

    def __BuildRowPool(self):
        for index in range(ROWS_PER_PAGE):
            rowButton = ui.Button()
            rowButton.SetParent(self.rowsBoard)
            rowButton.SetPosition(4, 4 + index * ROW_HEIGHT)
            rowButton.SetSize(444, ROW_HEIGHT - 2)
            rowButton.SetUpVisual("d:/ymir work/ui/public/parameter_slot_03.sub")
            rowButton.SetOverVisual("d:/ymir work/ui/public/parameter_slot_03.sub")
            rowButton.SetDownVisual("d:/ymir work/ui/public/parameter_slot_03.sub")
            rowButton.SetEvent(lambda r=proxy(self), idx=index: r.OnSelectRow(idx))
            rowButton.Hide()

            cols = [None] * COL_COUNT
            cols[COL_RANK] = self.__MakeColumnText(rowButton, 16, 4)
            cols[COL_NAME] = self.__MakeColumnText(rowButton, 76, 4)
            cols[COL_LEVEL] = self.__MakeColumnText(rowButton, 226, 4)
            cols[COL_SCORE] = self.__MakeColumnText(rowButton, 306, 4)

            self.rowWidgets.append((rowButton, cols))

    def __BuildMyRankRow(self):
        cols = [None] * COL_COUNT
        cols[COL_RANK] = self.__MakeColumnText(self.myRankBoard, 16, 6)
        cols[COL_NAME] = self.__MakeColumnText(self.myRankBoard, 76, 6)
        cols[COL_LEVEL] = self.__MakeColumnText(self.myRankBoard, 226, 6)
        cols[COL_SCORE] = self.__MakeColumnText(self.myRankBoard, 306, 6)
        self.myRankWidgets = cols

    def __MakeColumnText(self, parent, x, y):
        text = ui.TextLine()
        text.SetParent(parent)
        text.SetPosition(x, y)
        text.SetText("")
        text.Show()
        return text

    # ---- Lifecycle ----

    def Open(self):
        self.SetCenterPosition()
        self.SetTop()
        self.Show()
        self.RequestRanking()

    def Close(self):
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True

    @ui.WindowDestroy
    def Destroy(self):
        if self.pagePrevButton:
            self.pagePrevButton.SetEvent(0)
        if self.pageNextButton:
            self.pageNextButton.SetEvent(0)
        if self.refreshButton:
            self.refreshButton.SetEvent(0)
        for rowButton, _ in self.rowWidgets:
            if rowButton:
                rowButton.SetEvent(0)
        self.rowWidgets = []
        self.myRankWidgets = []
        self.ClearDictionary()
        self.__Initialize()

    # ---- Server contract ----

    def RequestRanking(self):
        if self.isLoadPending:
            return
        self.isLoadPending = True
        # TODO: verify net.SendRankingRequest exists in your fork (bindings.md).
        net.SendRankingRequest(self.currentPage)

    def OnRecvRanking(self, rows, totalCount, myRankRecord):
        self.rows = list(rows) if rows else []
        self.totalCount = int(totalCount)
        if ROWS_PER_PAGE > 0:
            self.totalPages = (self.totalCount + ROWS_PER_PAGE - 1) // ROWS_PER_PAGE
        else:
            self.totalPages = 0
        self.myRankRecord = myRankRecord
        self.isLoadPending = False
        self.RefreshTable()
        self.RefreshMyRank()

    # ---- Refresh (row-pool) ----

    def RefreshTable(self):
        for index, (rowButton, cols) in enumerate(self.rowWidgets):
            if index < len(self.rows):
                record = self.rows[index]
                self.__FillRow(record, cols)
                rowButton.Show()
                # Highlight the row if it represents the current player.
                if self.__IsOwnRecord(record):
                    rowButton.Down()
                else:
                    rowButton.SetUp()
            else:
                self.__ClearRow(cols)
                rowButton.Hide()
        if self.totalPages > 0:
            self.pageLabel.SetText("%d / %d" % (self.currentPage + 1, self.totalPages))
        else:
            self.pageLabel.SetText("")

    def __FillRow(self, record, cols):
        cols[COL_RANK].SetText(str(record.get("rank", "")))
        cols[COL_NAME].SetText(str(record.get("name", "")))
        cols[COL_LEVEL].SetText(str(record.get("level", "")))
        score = record.get("score", 0)
        cols[COL_SCORE].SetText(constInfo.intWithCommas(score) if score else "")

    def __ClearRow(self, cols):
        for text in cols:
            if text is not None:
                text.SetText("")

    def __IsOwnRecord(self, record):
        return record.get("name") == player.GetName()

    def RefreshMyRank(self):
        if not self.myRankRecord:
            for text in self.myRankWidgets:
                text.SetText("-")
            return
        self.__FillRow(self.myRankRecord, self.myRankWidgets)

    # ---- Pagination ----

    def OnPrevPage(self):
        if self.currentPage > 0:
            self.currentPage -= 1
            self.RequestRanking()

    def OnNextPage(self):
        if (self.currentPage + 1) < self.totalPages:
            self.currentPage += 1
            self.RequestRanking()

    def OnRefresh(self):
        self.RequestRanking()

    # ---- Selection ----

    def OnSelectRow(self, rowIndex):
        if rowIndex < 0 or rowIndex >= len(self.rows):
            return
        record = self.rows[rowIndex]
        # Optional: open a per-row detail panel (extends to right pane like
        # 18-mailbox-two-pane). Implementation-specific.
```

## Locale entries

```
LEADERBOARD_TITLE              Leaderboard
LEADERBOARD_HEADER_RANK        #
LEADERBOARD_HEADER_NAME        Name
LEADERBOARD_HEADER_LEVEL       Lv.
LEADERBOARD_HEADER_SCORE       Score
LEADERBOARD_REFRESH_BUTTON     Refresh
LEADERBOARD_NO_DATA            No data.
```

## interfacemodule.py integration snippet

```python
import uileaderboard

self.wndLeaderboard = None  # lazy-built

def ToggleLeaderboard(self):
    if self.wndLeaderboard is None:
        self.wndLeaderboard = uileaderboard.LeaderboardWindow()
    if self.wndLeaderboard.IsShow():
        self.wndLeaderboard.Close()
    else:
        self.wndLeaderboard.Open()

def OnRecvRanking(rows, totalCount, myRankRecord):
    if interface.wndLeaderboard is not None:
        interface.wndLeaderboard.OnRecvRanking(rows, totalCount, myRankRecord)
```

Lazy-build is appropriate -- leaderboards are typically opened from a menu button, not always-on.

## Common variations

### Variation 1: 3-column compact table

Drop the score column. Set `COL_COUNT = 3`. Keep rank/name/level. Useful for simple level-rankings.

### Variation 2: 5-column table with avatar + class

Add `COL_AVATAR = 4` (32x32 avatar slot per row) and `COL_CLASS = 5` (text). Bump row height to 36px. Server payload extends to include `avatarVnum` + `classCode` fields per record.

### Variation 3: Sortable headers

Make header labels clickable. On click, send `net.SendRankingRequest(self.currentPage, sortKey)` where `sortKey` rotates through column indices. The server returns the rows in the requested order; client just paints. Avoid client-side sort -- the visible page is a window into a much larger list, so client-side sort sees only `ROWS_PER_PAGE` records.

### Variation 4: Detail-panel-on-click (right pane extension)

Extends the layout to a two-pane like `18-mailbox-two-pane`. Left pane = leaderboard rows; right pane = selected-row detail (full character info, achievements, equipment preview). `OnSelectRow` triggers the detail-pane refresh.

### Variation 5: Live-update via broadcast packet

Server pushes `RecvRankingUpdate(deltaRows)` whenever rankings change. Client merges the delta into `self.rows` and calls `RefreshTable()`. Avoids the polling-via-Refresh-button pattern. Cross-link: `15-network-coupled-flow` broadcast-update variant.

## Don't copy these obsolete bits

- **Full-list rebuild on every refresh (failure-atlas entry 26)** -- one observed pattern destroys all N row widgets via `child.Destroy()` then re-creates N new widgets per refresh. For N=100 this hangs the UI noticeably. Use the row-pool pattern: pre-allocate at LoadWindow, walk + SetText on refresh.
- **`Destory()` typo for `Destroy()`** -- one survey source named the cleanup method `Destory` (no decorator). The misspelled method is never auto-invoked by `@ui.WindowDestroy`'s machinery, so cleanup never runs. The anchor uses the canonical `Destroy()` + decorator.
- **State-clearing in `__del__`** -- duplicating `self.X = None` lines in both `__del__` and `Destroy()` is redundant: `__Initialize()` already sets defaults, and `Destroy()` calls `__Initialize()`. `__del__` should only call `ui.ScriptWindow.__del__(self)`.
- **Per-row tooltip widget rebuild** -- if every row owns its own tooltip, refreshing creates 100+ tooltip widgets. Tooltip is shared (interfacemodule-owned `tooltipItem`); on hover-enter, set its data via the standard tooltip-bound pattern (anchor 06).
- **Synchronous icon-load on refresh** -- per-row icon disk reads on N rows = noticeable hang. Pre-cache icon handles at LoadWindow; refresh swaps cached handles.
- **Bare bound methods on row buttons** -- `rowButton.SetEvent(self.OnSelectRow)` leaks self into every row widget. Use `lambda r=proxy(self), idx=index: r.OnSelectRow(idx)` so the row holds only a weak proxy + the captured index.
