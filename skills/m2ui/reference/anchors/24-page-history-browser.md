# Anchor 24: Page History Browser

## What this is + when to use it

A primary archetype for **browser-style multi-page detail viewers**. The window owns a landing page (default-shown) plus a history of visited detail pages; navigation buttons (Prev / Next / Home) walk the history; opening a new detail page from anywhere truncates the forward history (calling `Destroy()` on each dropped page -- failure-atlas entry 29 mitigation).

Use this archetype for: in-game help / wiki, lore browser, achievement gallery, item encyclopedia, costume / collection viewer, multi-page guide reader. Distinct from `02-board-with-list` (passive scrolling list) by virtue of the navigation-stack lifecycle. Distinct from `11-quest-npc-dialog` (event-module driven, mostly one-shot) by virtue of client-side page-instance ownership and forward / back state.

## Source

Single peer implementation observed in a real Metin2 fork. Source-pattern: a hub window owns a list of detail-page widget instances plus a `currSelected` index; opening a new page from the middle of the history slices the forward list (`del history[idx+1:]`) but the source omits `Destroy()` on the dropped pages, which leaks them into the parent widget tree (the failure-atlas-29 anti-pattern this anchor explicitly mitigates). The anchor also separates the landing page from the history list (landing lives OUTSIDE `windowHistory`; `currSelected = -1` is the landing marker) -- the source mixes them, which conflates two different lifecycle contracts.

## Uiscript dict

`pack/pack/uiscript/uiscript/pagehistorybrowser.py`:

```python
window = {
    "name" : "PageHistoryBrowser",
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
            "title" : uiScriptLocale.PAGE_BROWSER_TITLE,

            "children" :
            (
                # ----- Navigation strip (top) -----
                {
                    "name" : "prev_button",
                    "type" : "button",
                    "x" : 18,
                    "y" : 36,
                    "text" : uiScriptLocale.PAGE_BROWSER_PREV,
                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },
                {
                    "name" : "next_button",
                    "type" : "button",
                    "x" : 100,
                    "y" : 36,
                    "text" : uiScriptLocale.PAGE_BROWSER_NEXT,
                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },
                {
                    "name" : "home_button",
                    "type" : "button",
                    "x" : 182,
                    "y" : 36,
                    "text" : uiScriptLocale.PAGE_BROWSER_HOME,
                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },
                {
                    "name" : "history_pos_label",
                    "type" : "text",
                    "x" : 480,
                    "y" : 40,
                    "text" : "",
                    "horizontal_align" : "center",
                    "not_pick" : 1,
                },

                # ----- Content region (landing + detail pages share this) -----
                {
                    "name" : "content_thinboard",
                    "type" : "thinboard",
                    "x" : 14,
                    "y" : 70,
                    "width" : 572,
                    "height" : 396,
                },
            ),
        },
    ),
}
```

## Root class

`pack/pack/root/uipagehistorybrowser.py`:

```python
import ui
import app
import localeInfo
import uiScriptLocale
import constInfo
from _weakref import proxy


class DetailPageBase(ui.Window):
    """Base class for a detail page hosted by PageHistoryBrowser.

    Subclasses MUST override OpenWindow() (called when navigation lands on
    the page) and MAY override _DestroyPage() to tear down page-owned
    children (tooltips, child dialogs, sub-windows).

    Subclasses MUST NOT override Destroy() directly: doing so replaces the
    decorated base method and strips @ui.WindowDestroy, which violates
    Critical Rule 1 (preserved Destroy body). Override the _DestroyPage()
    hook instead.
    """

    def __init__(self, browser):
        ui.Window.__init__(self)
        self.browser = proxy(browser)
        self.SetParent(browser.contentBoard)
        self.SetSize(572, 396)

    def __del__(self):
        ui.Window.__del__(self)

    def OpenWindow(self):
        # Subclasses override to refresh data on each navigation arrival.
        self.Show()

    @ui.WindowDestroy
    def Destroy(self):
        # Decorated tear-down. Calls the subclass hook; subclasses do NOT
        # override Destroy() (would strip the decorator).
        self._DestroyPage()

    def _DestroyPage(self):
        # Subclasses override to destroy page-owned children (tooltips,
        # child dialogs, sub-windows) before WOC tears the widget tree.
        # Default: nothing to tear down beyond what WOC handles.
        pass


class LandingPage(DetailPageBase):
    """Default-shown panel; shown when currSelected == -1."""

    def __init__(self, browser):
        DetailPageBase.__init__(self, browser)
        self.titleText = ui.TextLine()
        self.titleText.SetParent(self)
        self.titleText.SetPosition(20, 20)
        self.titleText.SetText(localeInfo.PAGE_BROWSER_LANDING_TITLE)
        self.titleText.Show()


class PageHistoryBrowser(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.__Initialize()
        self.__LoadWindow()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def __Initialize(self):
        self.contentBoard = None
        self.prevButton = None
        self.nextButton = None
        self.homeButton = None
        self.historyPosLabel = None

        self.windowHistory = []   # list of DetailPageBase instances
        self.currSelected = -1    # -1 = landing showing; >=0 = history[idx] active
        self.landingPage = None   # built lazily in Open()

    def __LoadWindow(self):
        try:
            self.LoadScriptFile("uiscript/pagehistorybrowser.py")
        except:
            import exception
            exception.Abort("PageHistoryBrowser.__LoadWindow.LoadScriptFile")

        try:
            self.contentBoard = self.GetChild("content_thinboard")
            self.prevButton = self.GetChild("prev_button")
            self.nextButton = self.GetChild("next_button")
            self.homeButton = self.GetChild("home_button")
            self.historyPosLabel = self.GetChild("history_pos_label")
        except:
            import exception
            exception.Abort("PageHistoryBrowser.__LoadWindow.BindObject")

        self.prevButton.SetEvent(ui.__mem_func__(self.OnPressPrevButton))
        self.nextButton.SetEvent(ui.__mem_func__(self.OnPressNextButton))
        self.homeButton.SetEvent(ui.__mem_func__(self.OnPressHomeButton))

    # ---- Lifecycle ----

    def Open(self):
        if self.landingPage is None:
            self.landingPage = LandingPage(self)
            self.landingPage.Hide()
        self.SetCenterPosition()
        self.SetTop()
        self.Show()
        self.__GoToLanding()

    def Close(self):
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True

    @ui.WindowDestroy
    def Destroy(self):
        if self.prevButton:
            self.prevButton.SetEvent(0)
        if self.nextButton:
            self.nextButton.SetEvent(0)
        if self.homeButton:
            self.homeButton.SetEvent(0)
        # Destroy every history page; they own children (tooltips, dialogs)
        # that WOC will not reach automatically because the page widgets
        # were created in Python with non-script parentage.
        for page in self.windowHistory:
            if page is not None:
                page.Destroy()
        self.windowHistory = []
        if self.landingPage is not None:
            self.landingPage.Destroy()
            self.landingPage = None
        self.ClearDictionary()
        self.__Initialize()

    # ---- Navigation ----

    def OpenDetailPage(self, pageFactory):
        """Open a new detail page. `pageFactory` is a callable that takes
        this browser instance and returns a DetailPageBase subclass.

        Truncates forward history with Destroy() on each dropped page
        (atlas 29 mitigation). Two cases:
        - currSelected == -1 (landing): destroy ALL existing history
          before appending. Stale entries can exist if the consumer
          manipulated state externally; this branch keeps the invariant
          "after OpenDetailPage from landing, history holds exactly one
          page" without trusting external callers.
        - currSelected >= 0: destroy only forward entries (idx > current).
        """
        if self.currSelected == -1:
            # Coming from landing -- destroy any stale history before adding.
            for dropped in self.windowHistory:
                if dropped is not None:
                    dropped.Destroy()
            del self.windowHistory[:]
        elif (self.currSelected + 1) < len(self.windowHistory):
            # Truncate forward history if navigating from middle.
            for dropped in self.windowHistory[self.currSelected + 1:]:
                if dropped is not None:
                    dropped.Destroy()
            del self.windowHistory[self.currSelected + 1:]

        # Hide whatever is currently shown.
        self.__HideCurrent()

        # Build new page and append to history.
        newPage = pageFactory(self)
        self.windowHistory.append(newPage)
        self.currSelected = len(self.windowHistory) - 1
        newPage.OpenWindow()

        self.__RefreshNavButtons()
        self.__RefreshHistoryLabel()

    def OnPressPrevButton(self):
        if self.currSelected <= 0:
            # Already at history[0] -- step back to landing (currSelected = -1).
            if self.currSelected == 0:
                self.__HideCurrent()
                self.currSelected = -1
                self.landingPage.OpenWindow()
                self.__RefreshNavButtons()
                self.__RefreshHistoryLabel()
            return
        self.__HideCurrent()
        self.currSelected -= 1
        self.windowHistory[self.currSelected].OpenWindow()
        self.__RefreshNavButtons()
        self.__RefreshHistoryLabel()

    def OnPressNextButton(self):
        if (self.currSelected + 1) >= len(self.windowHistory):
            return
        self.__HideCurrent()
        self.currSelected += 1
        self.windowHistory[self.currSelected].OpenWindow()
        self.__RefreshNavButtons()
        self.__RefreshHistoryLabel()

    def OnPressHomeButton(self):
        self.__GoToLanding()

    def __GoToLanding(self):
        # Destroy every history entry (atlas 29 mitigation) and reset to
        # landing. The landing page itself persists across Home presses.
        self.__HideCurrent()
        for page in self.windowHistory:
            if page is not None:
                page.Destroy()
        self.windowHistory = []
        self.currSelected = -1
        if self.landingPage is not None:
            self.landingPage.OpenWindow()
        self.__RefreshNavButtons()
        self.__RefreshHistoryLabel()

    def __HideCurrent(self):
        if self.currSelected == -1:
            if self.landingPage is not None:
                self.landingPage.Hide()
        else:
            if 0 <= self.currSelected < len(self.windowHistory):
                page = self.windowHistory[self.currSelected]
                if page is not None:
                    page.Hide()

    def __RefreshNavButtons(self):
        # Prev: enabled if there is somewhere back to go (history entry > 0
        # or landing is reachable from history[0]).
        if self.currSelected > 0 or (self.currSelected == 0 and self.landingPage is not None):
            self.prevButton.Enable()
        else:
            self.prevButton.Disable()
        # Next: enabled if there is forward history.
        if (self.currSelected + 1) < len(self.windowHistory):
            self.nextButton.Enable()
        else:
            self.nextButton.Disable()

    def __RefreshHistoryLabel(self):
        if self.currSelected == -1:
            self.historyPosLabel.SetText(localeInfo.PAGE_BROWSER_LANDING_LABEL)
        else:
            self.historyPosLabel.SetText("%d / %d" % (self.currSelected + 1, len(self.windowHistory)))
```

## Locale entries

```
PAGE_BROWSER_TITLE              Browser
PAGE_BROWSER_PREV               <
PAGE_BROWSER_NEXT               >
PAGE_BROWSER_HOME               Home
PAGE_BROWSER_LANDING_TITLE      Welcome
PAGE_BROWSER_LANDING_LABEL      Home
```

## interfacemodule.py integration snippet

```python
import uipagehistorybrowser

self.wndBrowser = None  # lazy-built

def ToggleBrowser(self):
    if self.wndBrowser is None:
        self.wndBrowser = uipagehistorybrowser.PageHistoryBrowser()
    if self.wndBrowser.IsShow():
        self.wndBrowser.Close()
    else:
        self.wndBrowser.Open()
```

Detail pages are opened by passing a factory to `OpenDetailPage`. Factories receive the browser instance so the page can call back into history navigation if needed:

```python
def OpenDetailForVnum(vnum):
    interface.wndBrowser.OpenDetailPage(
        lambda browser: MyDetailPage(browser, vnum)
    )
```

`MyDetailPage` subclasses `DetailPageBase` and overrides `OpenWindow()` to refresh data on each arrival. If the page owns tooltips / child dialogs, override `_DestroyPage()` (NOT `Destroy()`) to tear them down -- the base `Destroy()` is decorated and calls the hook.

## Common variations

1. **Filter-bar above content** -- wrap a `17-search-filter-dialog` style filter row above the navigation strip; clicking a search result calls `OpenDetailPage` with a factory bound to the result vnum.
2. **Deep-link Open(vnum)** -- accept an optional vnum in `Open()`; if supplied, skip landing and call `OpenDetailPage` with a factory bound to that vnum as the initial entry.
3. **Modal-page block** -- the active detail page can flip a `pageBlocked` flag on the browser to disable Prev / Next during a sub-flow (e.g., commit pending). Refresh nav buttons checks the flag.
4. **Swappable landing pages** -- multiple landing panels for different sections; Home button opens a sub-menu of landing options instead of a single fixed landing.
5. **History dropdown breadcrumb** -- visible breadcrumb showing every entry in `windowHistory`; click jumps to that index. Implementation hint: a small `ui.ListBox` populated from the history label list.

## Don't copy these obsolete bits

- **`del history[currSelected+1:]` without `Destroy()` on dropped pages** -- failure-atlas entry 29 root cause #1. Always destroy each truncated entry before slicing the list.
- **`Hide()` instead of `Destroy()` on dropped pages** -- failure-atlas entry 29 root cause #2. Hide only stops rendering; the page stays in the parent widget tree.
- **Page-owned tooltips / child dialogs not torn down** -- failure-atlas entry 29 root cause #3. Subclass `_DestroyPage()` (the hook called from the decorated base `Destroy()`) must explicitly tear down any non-WOC-reachable children. Do NOT override `Destroy()` itself: that would strip the `@ui.WindowDestroy` decorator and break Critical Rule 1.
- **Storing landing page as `windowHistory[0]`** -- conflates landing with detail pages. The anchor keeps landing OUTSIDE the history list and uses `currSelected = -1` as the landing marker.
- **Bare bound methods on Prev / Next / Home buttons** -- `btn.SetEvent(self.OnPressPrevButton)` leaks `self`. Use `ui.__mem_func__()` per Critical Rule 5.
- **Building landing page in `__init__` instead of lazily in `Open()`** -- delays first window open by N widget allocations and leaves the landing alive across Open / Close cycles. Lazy-build keeps Open() fast.
