# Metin2 UI Code Patterns & Templates

## 1. Style 1 -- Script-Backed Window (uiscript + root class)

A uiscript dict file defines layout; the root class loads it via `LoadScriptFile()` and
binds children by name with `GetChild()`.

### 1.1 Root class template (root/uiMyWindow.py)

```python
import app
import dbg
import ui
import exception
import localeInfo

class MyWindow(ui.ScriptWindow):
    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.__Initialize()
        self.__LoadWindow()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def __Initialize(self):
        self.board = None
        self.titleBar = None
        self.acceptButton = None
        self.cancelButton = None

    @ui.WindowDestroy
    def Destroy(self):
        self.__Initialize()
        self.ClearDictionary()
        self.Hide()

    def __LoadWindow(self):
        if getattr(self, "IsLoaded", False):
            return
        self.IsLoaded = True

        try:
            pyScrLoader = ui.PythonScriptLoader()
            pyScrLoader.LoadScriptFile(self, "UIScript/MyWindowDialog.py")
        except:
            exception.Abort("MyWindow.__LoadWindow.LoadScript")

        try:
            self.board = self.GetChild("Board")
            self.titleBar = self.GetChild("TitleBar")
            self.acceptButton = self.GetChild("AcceptButton")
            self.cancelButton = self.GetChild("CancelButton")
        except:
            exception.Abort("MyWindow.__LoadWindow.BindObject")

        self.titleBar.SetCloseEvent(ui.__mem_func__(self.Close))
        self.acceptButton.SetEvent(ui.__mem_func__(self.OnAccept))
        self.cancelButton.SetEvent(ui.__mem_func__(self.Close))

    def Open(self):
        self.SetCenterPosition()
        self.Show()

    def Close(self):
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True

    def OnAccept(self):
        # handle accept
        self.Close()
```

### 1.2 Uiscript dict file template (uiscript/mywindowdialog.py)

```python
import localeInfo

window = {
    "name" : "MyWindowDialog",
    "style" : ("movable", "float",),

    "x" : 0,
    "y" : 0,

    "width" : 200,
    "height" : 150,

    "children" :
    (
        {
            "name" : "Board",
            "type" : "board",
            "style" : ("attach",),

            "x" : 0,
            "y" : 0,

            "width" : 200,
            "height" : 150,

            "children" :
            (
                ## Title Bar
                {
                    "name" : "TitleBar",
                    "type" : "titlebar",
                    "style" : ("attach",),

                    "x" : 6,
                    "y" : 7,
                    "width" : 187,

                    "children" :
                    (
                        {
                            "name" : "TitleName",
                            "type" : "text",
                            "x" : 0,
                            "y" : 0,
                            "text" : "Window Title",
                            "all_align" : "center",
                        },
                    ),
                },

                ## Accept Button
                {
                    "name" : "AcceptButton",
                    "type" : "button",

                    "x" : 15,
                    "y" : 30,

                    "vertical_align" : "bottom",

                    "text" : localeInfo.OK,

                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },

                ## Cancel Button
                {
                    "name" : "CancelButton",
                    "type" : "button",

                    "x" : 115,
                    "y" : 30,

                    "vertical_align" : "bottom",

                    "text" : localeInfo.CANCEL,

                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },
            ),
        },
    ),
}
```

### 1.3 Uiscript element types

| type | Python class | Notes |
|------|-------------|-------|
| `"board"` | `ui.Board` | Background with border |
| `"board_with_titlebar"` | `ui.BoardWithTitleBar` | Board + built-in title bar |
| `"titlebar"` | `ui.TitleBar` | Draggable title bar with close button |
| `"thinboard"` | `ui.ThinBoard` | Thin-bordered panel |
| `"thinboard_circle"` | `ui.ThinBoardCircle` | Rounded thin panel |
| `"bar"` | `ui.Bar` | Solid color rectangle |
| `"button"` | `ui.Button` | Standard button (3 images) |
| `"radio_button"` | `ui.RadioButton` | Mutually exclusive button |
| `"toggle_button"` | `ui.ToggleButton` | On/off button |
| `"text"` | `ui.TextLine` | Single line of text |
| `"editline"` | `ui.EditLine` | Text input field |
| `"image"` | `ui.ImageBox` | Static image |
| `"expanded_image"` | `ui.ExpandedImageBox` | Image with scale/rotation |
| `"ani_image"` | `ui.AniImageBox` | Animated image sequence |
| `"slot"` | `ui.SlotWindow` | Grid of slots |
| `"grid_table"` | `ui.GridSlotWindow` | Grid slot with item support |
| `"scrollbar"` | `ui.ScrollBar` | Vertical scroll bar |
| `"listbox"` | `ui.ListBox` | Scrollable list |

### 1.4 Uiscript alignment keys

```python
"horizontal_align" : "center"    # centers child horizontally in parent
"vertical_align" : "center"      # centers child vertically in parent
"vertical_align" : "bottom"      # anchors child to bottom of parent
"all_align" : "center"           # centers both axes (text shorthand)
```

---

## 2. Style 2 -- Code-Only Window (no uiscript)

Everything is built programmatically in `__LoadDialog()`. Widgets are attached
via `SetParent()` + `self.InsertChild()`.

### 2.1 Root class template (root/uiMyFeature.py)

```python
import app
import ui
import localeInfo

class MyFeatureWindow(ui.ScriptWindow):
    WINDOW_WIDTH = 300
    WINDOW_HEIGHT = 250

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.Initialize()
        self.__LoadDialog()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def Initialize(self):
        self.tooltipItem = None
        self.board = None
        self.selectedSlot = -1

    @ui.WindowDestroy
    def Destroy(self):
        self.Initialize()

    def __LoadDialog(self):
        self.SetSize(self.WINDOW_WIDTH, self.WINDOW_HEIGHT)
        self.AddFlag("movable")

        # -- Board with title bar --
        board = ui.BoardWithTitleBar()
        board.SetParent(self)
        board.AddFlag("attach")
        board.SetTitleName("My Feature")
        board.SetSize(self.GetWidth(), self.GetHeight())
        board.SetCloseEvent(ui.__mem_func__(self.Close))
        board.SetPosition(0, 0)
        board.Show()
        self.InsertChild("board", board)
        self.board = board

        # -- Text label --
        textLine = ui.TextLine()
        textLine.SetParent(board)
        textLine.SetPosition(0, 40)
        textLine.SetWindowHorizontalAlignCenter()
        textLine.SetHorizontalAlignCenter()
        textLine.SetText("Description text")
        textLine.Show()
        self.InsertChild("description", textLine)

        # -- Slot grid --
        slotGrid = ui.GridSlotWindow()
        slotGrid.SetParent(board)
        slotGrid.ArrangeSlot(0, 4, 1, 32, 32, 0, 0)
        slotGrid.SetSlotBaseImage(
            "d:/ymir work/ui/public/slot_base.sub",
            1.0, 1.0, 1.0, 1.0,
        )
        slotWidth = 4 * 32
        slotX = (board.GetWidth() - slotWidth) / 2
        slotGrid.SetPosition(int(slotX), 70)
        slotGrid.Show()
        self.InsertChild("itemSlot", slotGrid)
        slotGrid.SetOverInItemEvent(ui.__mem_func__(self.OnOverIn))
        slotGrid.SetOverOutItemEvent(ui.__mem_func__(self.OnOverOut))
        slotGrid.SetSelectItemSlotEvent(ui.__mem_func__(self.OnSelectSlot))

        # -- Action button --
        btn = ui.Button()
        btn.SetParent(board)
        btn.SetUpVisual("d:/ymir work/ui/public/large_button_01.sub")
        btn.SetOverVisual("d:/ymir work/ui/public/large_button_02.sub")
        btn.SetDownVisual("d:/ymir work/ui/public/large_button_03.sub")
        btnX = (board.GetWidth() - btn.GetWidth()) / 2
        btn.SetPosition(int(btnX), 190)
        btn.SetText(localeInfo.OK)
        btn.SetEvent(ui.__mem_func__(self.OnAction))
        btn.Show()
        self.InsertChild("actionButton", btn)

    # -- Tooltip binding (called from interfacemodule.py) --
    def SetItemToolTip(self, tooltip):
        self.tooltipItem = tooltip

    # -- Open / Close --
    def Open(self):
        if self.IsShow():
            return
        self.SetCenterPosition()
        self.SetTop()
        self.Show()

    def Close(self):
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True

    # -- Slot events --
    def OnOverIn(self, slotIndex):
        if self.tooltipItem:
            self.tooltipItem.ClearToolTip()
            # self.tooltipItem.AddItemData(...)
            # self.tooltipItem.ShowToolTip()

    def OnOverOut(self):
        if self.tooltipItem:
            self.tooltipItem.HideToolTip()

    def OnSelectSlot(self, slotIndex):
        pass

    def OnAction(self):
        pass
```

### 2.2 Code-only widget creation pattern

Every programmatic widget follows this exact sequence:

```python
obj = ui.WidgetClass()
obj.SetParent(parentWidget)       # attach to parent
# configure: SetPosition, SetSize, SetText, etc.
obj.Show()
self.InsertChild("uniqueName", obj)   # register for GetChild() access
```

`InsertChild(name, widget)` registers the widget so it can be retrieved later via
`self.GetChild("uniqueName")` and so the `@ui.WindowDestroy` decorator can clean
it up automatically.

### 2.3 Horizontal bar separator pattern

```python
bar = ui.HorizontalBar()
bar.SetParent(board)
bar.Create(board.GetWidth() - 20)
bar.SetPosition(10, yPos)
bar.Show()
self.InsertChild("separator", bar)

label = ui.TextLine()
label.SetParent(bar)
label.SetPosition(0, 0)
label.SetWindowHorizontalAlignCenter()
label.SetHorizontalAlignCenter()
label.SetText("Section Title")
label.Show()
self.InsertChild("sectionLabel", label)
```

### 2.4 Radio button group pattern

```python
GROUP_NAMES = ("Tab A", "Tab B", "Tab C")
BUTTON_WIDTH = 52
PADDING = 5

container = ui.Window()
container.SetParent(board)
totalWidth = (BUTTON_WIDTH * len(GROUP_NAMES)) + (PADDING * (len(GROUP_NAMES) - 1))
container.SetSize(totalWidth, BUTTON_WIDTH)
containerX = (board.GetWidth() - totalWidth) / 2
container.SetPosition(int(containerX), 40)
container.Show()
self.InsertChild("tabContainer", container)

for idx, name in enumerate(GROUP_NAMES):
    btn = ui.RadioButton()
    btn.SetParent(container)
    btn.SetUpVisual("d:/ymir work/ui/game/windows/tab_button_middle_01.sub")
    btn.SetOverVisual("d:/ymir work/ui/game/windows/tab_button_middle_02.sub")
    btn.SetDownVisual("d:/ymir work/ui/game/windows/tab_button_middle_03.sub")
    btn.SetPosition((BUTTON_WIDTH + PADDING) * idx, 0)
    btn.SetText(name)
    btn.SetEvent(ui.__mem_func__(self.OnSelectTab), idx)
    btn.Show()
    self.InsertChild("tab{}".format(idx), btn)
```

---

## 3. Circular Reference Rules

The `ui.__mem_func__` class wraps a bound method using `weakref.proxy()` on both
the instance (`im_self`) and the function (`im_func`), breaking the reference
cycle that would otherwise prevent garbage collection.

**RULE: Any callback that references `self` MUST go through `ui.__mem_func__()`.**

### Correct

```python
button.SetEvent(ui.__mem_func__(self.OnClick))
titleBar.SetCloseEvent(ui.__mem_func__(self.Close))
slotGrid.SetSelectItemSlotEvent(ui.__mem_func__(self.OnSelectSlot))
```

### Correct -- passing extra args to event setter

Some event setters accept additional positional arguments that get forwarded to
the callback. Use this instead of lambdas when you need extra args:

```python
radioBtn.SetEvent(ui.__mem_func__(self.OnSelectTab), idx)
slotGrid.SetOverInItemEvent(ui.__mem_func__(self.OnOverIn), 0, row)
```

### Wrong -- direct bound method (memory leak)

```python
button.SetEvent(self.OnClick)
```

The button holds a strong reference to the bound method, which holds a strong
reference to `self`. Neither can be garbage collected.

### Wrong -- lambda captures self (same leak)

```python
slot.SetOverInItemEvent(lambda trash=0, row=row: self.__OnSlot(trash, row))
```

The lambda object captures `self` via its closure. The parent widget holds the
lambda, creating the same reference cycle.

### Wrong -- ui.__mem_func__ inside lambda (useless)

```python
slot.SetEvent(lambda: ui.__mem_func__(self.OnClick)())
```

`ui.__mem_func__` is constructed inside the lambda, but the lambda itself still
captures `self`. The weak reference wrapper is pointless because the strong
reference through the lambda keeps `self` alive.

### Safe -- lambda with no self reference

```python
button.SetEvent(lambda arg=i: standaloneFunc(arg))
```

If the lambda does not reference `self` (or any other UI object), there is no
reference cycle. Module-level functions and captured primitives are fine.

### Safe -- weakref proxy in lambda (advanced, rare)

```python
from _weakref import proxy
button.SetEvent(lambda n, i=proxy(self): i.OnWhisper(n))
```

This is used in interfacemodule.py for cases where `ui.__mem_func__` cannot be
used (e.g., the callback needs a non-method callable with specific argument
reshaping). The `proxy()` prevents the strong reference.

---

## 4. interfacemodule.py Integration Template

When adding a new window to the game interface, follow these steps in
`interfacemodule.py`:

### 4.1 Import (top of file, guarded by feature flag)

```python
if app.ENABLE_MY_FEATURE:
    import uiMyFeature
```

### 4.2 Initialize member to None (in __init__ or MakeInterface)

```python
if app.ENABLE_MY_FEATURE:
    self.wndMyFeature = None
```

### 4.3 Create instance (in MakeInterface, after tooltip creation)

```python
if app.ENABLE_MY_FEATURE:
    self.wndMyFeature = uiMyFeature.MyFeatureWindow()
```

### 4.4 Bind tooltips (in MakeInterface, tooltip binding section)

```python
if app.ENABLE_MY_FEATURE:
    self.wndMyFeature.SetItemToolTip(self.tooltipItem)
    # self.wndMyFeature.SetSkillToolTip(self.tooltipSkill)  # if needed
```

### 4.5 BindInterface (if the window needs to call back into interfacemodule)

```python
if app.ENABLE_MY_FEATURE:
    self.wndMyFeature.BindInterface(self)
```

In the window class:
```python
def BindInterface(self, interface):
    from _weakref import proxy
    self.interface = proxy(interface)
```

### 4.6 Toggle method

```python
if app.ENABLE_MY_FEATURE:
    def ToggleMyFeatureWindow(self):
        if not self.wndMyFeature.IsShow():
            self.wndMyFeature.Open()
        else:
            self.wndMyFeature.Hide()
```

### 4.7 Destroy in Close() cleanup

```python
if app.ENABLE_MY_FEATURE and self.wndMyFeature:
    self.wndMyFeature.Destroy()
    self.wndMyFeature = None
```

### 4.8 Hide in HideAllWindows / OnCloseQuestionDialog

```python
if app.ENABLE_MY_FEATURE and self.wndMyFeature:
    self.wndMyFeature.Hide()
```

### 4.9 Add to hideWindows list (in __HideWindows)

```python
if app.ENABLE_MY_FEATURE and self.wndMyFeature:
    hideWindows += self.wndMyFeature,
```

---

## 5. UI Behavior Rules

### 5.1 Layers (back to front)

```
GAME  ->  UI_BOTTOM  ->  UI (default)  ->  TOP_MOST  ->  CURTAIN
```

- All `ui.ScriptWindow` and `ui.Window` default to `"UI"`.
- Create on a different layer: `ui.Bar("TOP_MOST")`, `ui.Window("UI_BOTTOM")`.
- Modal overlays use `"CURTAIN"` (darkened backdrop).

### 5.2 Z-order

Within the same layer, z-order is determined by the order of `SetParent()` calls
and `SetTop()`. Later `SetParent()` calls place the child on top of earlier
siblings. Call `SetTop()` to bring a window to the front of its layer.

### 5.3 Window flags

| Flag | Effect |
|------|--------|
| `"movable"` | User can drag the window by its title bar area |
| `"float"` | Window floats above non-float windows in same layer |
| `"attach"` | Child sticks to parent position (moves with parent) |
| `"not_pick"` | Window is transparent to mouse picking (click-through) |

Add flags with `self.AddFlag("movable")` or in uiscript `"style" : ("movable", "float",)`.

### 5.4 Picking and bounds clipping

A child widget is only pickable (clickable) within the bounds of its parent.
If a child extends beyond its parent's rectangle, the overflowing portion cannot
receive mouse events. Size parents large enough to contain all children.

### 5.5 Event return values

`OnPressEscapeKey()` and `OnMouseWheel()` (and similar input handlers) must
return `True` if the event was consumed, `False` to let it propagate. Forgetting
the return value causes the event to propagate unexpectedly.

```python
def OnPressEscapeKey(self):
    self.Close()
    return True

def OnMouseWheel(self, delta):
    # handle scroll
    return True
```

### 5.6 Performance -- OnUpdate and OnRender

`OnUpdate()` is called every frame. Never do heavy work (network calls, large
iterations, file I/O) directly in OnUpdate. Use a time-gated pattern:

```python
def OnUpdate(self):
    if self.nextUpdateTime > app.GetTime():
        return
    self.nextUpdateTime = app.GetTime() + 0.5  # run every 500ms
    self._DoExpensiveWork()
```

`OnRender()` should only contain draw calls. No allocations, no logic.

### 5.7 Number formatting

Use `constInfo.intWithCommas()` to format large numbers with separators:

```python
import constInfo
formatted = constInfo.intWithCommas(1234567)  # "1.234.567"
```

The separator defaults to `"."` (period). Pass a second argument to change it:
```python
constInfo.intWithCommas(1234567, ",")  # "1,234,567"
```

### 5.8 Common button image sets

```python
# Small button (61x21)
"d:/ymir work/ui/public/middle_button_01.sub"  # up
"d:/ymir work/ui/public/middle_button_02.sub"  # over
"d:/ymir work/ui/public/middle_button_03.sub"  # down

# Large button
"d:/ymir work/ui/public/large_button_01.sub"   # up
"d:/ymir work/ui/public/large_button_02.sub"   # over
"d:/ymir work/ui/public/large_button_03.sub"   # down

# Tab button
"d:/ymir work/ui/game/windows/tab_button_middle_01.sub"  # up
"d:/ymir work/ui/game/windows/tab_button_middle_02.sub"  # over
"d:/ymir work/ui/game/windows/tab_button_middle_03.sub"  # down

# Slot base
"d:/ymir work/ui/public/slot_base.sub"

# Radio/select button
"d:/ymir work/ui/game/myshop_deco/select_btn_01.sub"  # up
"d:/ymir work/ui/game/myshop_deco/select_btn_02.sub"  # over
"d:/ymir work/ui/game/myshop_deco/select_btn_03.sub"  # down
```

### 5.9 Window lifecycle summary

```
__init__()
  -> ScriptWindow.__init__(self)
  -> Initialize()        # all instance vars = None / defaults
  -> __LoadWindow()      # or __LoadDialog()

Open()
  -> SetCenterPosition() # optional
  -> SetTop()            # optional, brings to front
  -> Show()

Close()
  -> Hide()

Destroy()               # decorated with @ui.WindowDestroy
  -> Initialize()       # reset all vars
  -> ClearDictionary()  # only for script-backed (Style 1)
  -> Hide()

__del__()
  -> ScriptWindow.__del__(self)
```

---

## 6. Clip Mask (Scrollable Content Clipping)

Gated behind `app.__BL_CLIP_MASK__`. Clips child widget rendering to parent
bounds — essential for scrollable lists where items should disappear when
scrolling out of view instead of overflowing visually.

### 6.1 Basic usage — clip children to a container

```python
if app.__BL_CLIP_MASK__:
    childWidget.SetClippingMaskWindow(parentContainer)
```

Every child that can scroll out of the parent's visible area needs this call.
Apply it right after creating the child and setting its parent.

### 6.2 Explicit rect clipping

```python
if app.__BL_CLIP_MASK__:
    widget.SetClippingMaskRect(left, top, right, bottom)
```

Use when clipping to a specific rectangle rather than a parent window's bounds.

### 6.3 Scrollable list pattern (ListBoxEx with clip mask)

With clip mask enabled, `ListBoxEx` uses pixel-based smooth scrolling instead
of item-index-based jumping:

```python
# In AppendItem — attach clip mask to each new item
if app.__BL_CLIP_MASK__:
    newItem.SetClippingMaskWindow(self)

# In SetBasePos — pixel-based scroll positioning
if app.__BL_CLIP_MASK__:
    self.basePos = basePos
    fromPos = self.basePos
    toPos = self.basePos + self.GetHeight()
    curPos = 0
    for item in self.itemList:
        if curPos + self.itemStep < fromPos or curPos > toPos:
            item.Hide()
        else:
            item.Show()
        item.SetPosition(0, curPos - fromPos)
        curPos += self.itemStep
```

### 6.4 Custom scrollable container pattern (uilootingsystem style)

For custom scrollable areas outside of ListBoxEx, apply clip mask to each
child that belongs to a scrollable parent:

```python
if app.__BL_CLIP_MASK__:
    self.title_img.SetClippingMaskWindow(self.parent)
    self.state_btn.SetClippingMaskWindow(self.parent)
    self.desc_title.SetClippingMaskWindow(parent)
    self.range_img.SetClippingMaskWindow(parent)
```

### 6.5 Rules

- Always guard with `if app.__BL_CLIP_MASK__:` — not all builds have it
- Apply to EVERY child widget that can scroll out of view
- Call `SetClippingMaskWindow` after `SetParent` and before `Show`
- The clipping window must be the scrollable container, not the root window
- Without clip mask, fall back to Hide/Show based on item index (old behavior)

---

## 7. Composite Patterns

Reusable UI compositions built from existing widgets. No C++ changes or
new widget types required.

### 7.1 Collapsible section

A header button that expands/collapses a child container. Useful for
settings panels, categorized lists, and accordion-style UIs.

```python
ARROW_DOWN = "▼ "
ARROW_RIGHT = "► "

def __CreateCollapsibleSection(self, parent, title, yPos, contentHeight):
    container = ui.Window()
    container.SetParent(parent)
    container.SetPosition(10, yPos)
    container.SetSize(parent.GetWidth() - 20, 25 + contentHeight)
    container.Show()
    self.InsertChild("section_" + title, container)

    header = ui.Button()
    header.SetParent(container)
    header.SetUpVisual("d:/ymir work/ui/public/large_button_01.sub")
    header.SetOverVisual("d:/ymir work/ui/public/large_button_02.sub")
    header.SetDownVisual("d:/ymir work/ui/public/large_button_03.sub")
    header.SetText(ARROW_DOWN + title)
    header.SetPosition(0, 0)
    header.Show()
    self.InsertChild("header_" + title, header)

    content = ui.Window()
    content.SetParent(container)
    content.SetPosition(0, 25)
    content.SetSize(container.GetWidth(), contentHeight)
    content.Show()
    self.InsertChild("content_" + title, content)

    header.SetEvent(ui.__mem_func__(self.__ToggleSection), title)
    return content

def __ToggleSection(self, title):
    content = self.GetChild("content_" + title)
    header = self.GetChild("header_" + title)

    if content.IsShow():
        content.Hide()
        header.SetText(ARROW_RIGHT + title)
    else:
        content.Show()
        header.SetText(ARROW_DOWN + title)
```

**Pitfalls:**
- `SetEvent` passes `title` as an extra arg — no lambda needed
- Children inside a hidden container are automatically hidden too, but
  `SetParent` call order still determines z-order when re-shown
- If the section has many children, hide/show is fast — no need to
  recreate widgets
- Track collapsed state with a dict if you need to resize the parent
  window dynamically — initialize it in `Initialize()`:
  ```python
  self.sectionStates = {}  # {"Performance": True, "Interface": False}
  ```

### 7.2 Two-panel layout (navigation + content)

Left navigation list with clickable items, right content panel that
swaps content based on selection. Used for settings, shop categories,
help systems.

```python
NAV_WIDTH = 120
CONTENT_X = NAV_WIDTH + 5

def __LoadDialog(self):
    # ... board setup omitted ...

    # Left navigation panel
    navPanel = ui.Window()
    navPanel.SetParent(self.board)
    navPanel.SetPosition(10, 35)
    navPanel.SetSize(NAV_WIDTH, self.board.GetHeight() - 45)
    navPanel.Show()
    self.InsertChild("navPanel", navPanel)

    # Right content panel
    contentPanel = ui.Window()
    contentPanel.SetParent(self.board)
    contentPanel.SetPosition(CONTENT_X + 10, 35)
    contentPanel.SetSize(
        self.board.GetWidth() - CONTENT_X - 20,
        self.board.GetHeight() - 45,
    )
    contentPanel.Show()
    self.InsertChild("contentPanel", contentPanel)

    # Navigation items (radio buttons for mutual exclusion)
    self.navButtons = []
    self.navKeys = []
    self.contentPages = {}
    self.radioGroup = None

def AddNavItem(self, key, label):
    idx = len(self.navButtons)
    navPanel = self.GetChild("navPanel")

    btn = ui.RadioButton()
    btn.SetParent(navPanel)
    btn.SetUpVisual("d:/ymir work/ui/public/large_button_01.sub")
    btn.SetOverVisual("d:/ymir work/ui/public/large_button_02.sub")
    btn.SetDownVisual("d:/ymir work/ui/public/large_button_03.sub")
    btn.SetText(label)
    btn.SetPosition(0, idx * 28)
    btn.Show()
    self.InsertChild("nav_" + key, btn)
    self.navButtons.append(btn)
    self.navKeys.append(key)

    contentPanel = self.GetChild("contentPanel")
    page = ui.Window()
    page.SetParent(contentPanel)
    page.SetPosition(0, 0)
    page.SetSize(contentPanel.GetWidth(), contentPanel.GetHeight())
    page.Hide()
    self.InsertChild("page_" + key, page)
    self.contentPages[key] = page

    return page

def BuildNavigation(self):
    from _weakref import proxy
    ref = proxy(self)

    groupData = []
    for idx, key in enumerate(self.navKeys):
        groupData.append((
            self.navButtons[idx],
            lambda k=key, r=ref: r.__SelectPage(k),
            lambda k=key: None,
        ))
    self.radioGroup = ui.RadioButtonGroup.Create(groupData)

def __SelectPage(self, key):
    for k, page in self.contentPages.items():
        if k == key:
            page.Show()
        else:
            page.Hide()
```

**Pitfalls:**
- The select lambda uses `proxy(self)` to avoid a circular reference leak.
  Without the proxy, the lambda captures `self` strongly, the radio group
  holds the lambda, and the dialog holds the radio group — a leak cycle.
  The unselect lambda (`lambda k=key: None`) is safe since it has no `self`.
- `self.navKeys` maintains insertion order — Python 2 dicts don't guarantee
  key order, so iterating `self.contentPages.keys()` could scramble the
  button-to-page mapping
- `RadioButtonGroup.Create` auto-selects the first button internally —
  no manual `Down()` or `__SelectPage()` call needed after `Create`
- Content pages must be sized to match `contentPanel` — children outside
  parent bounds won't receive mouse events (picking rule)
- Call `BuildNavigation()` after all `AddNavItem()` calls, not during
- Each page is a `ui.Window` container — add widgets to it as children
- Initialize `self.navButtons` as `[]`, `self.navKeys` as `[]`,
  `self.contentPages` as `{}`, and `self.radioGroup` as `None` in
  `Initialize()` for proper cleanup

### 7.3 Checkbox group

A labeled group of toggle buttons that act as independent checkboxes.
Each button has on/off state. Read state programmatically.

```python
def __CreateCheckboxGroup(self, parent, groupName, labels, yPos):
    ROW_HEIGHT = 25
    COL_WIDTH = 100

    groupWnd = ui.Window()
    groupWnd.SetParent(parent)
    groupWnd.SetPosition(0, yPos)
    rows = (len(labels) + 3) // 4  # 4 per row
    groupWnd.SetSize(parent.GetWidth(), ROW_HEIGHT * rows)
    groupWnd.Show()
    self.InsertChild("group_" + groupName, groupWnd)

    if not hasattr(self, "checkboxes"):
        self.checkboxes = {}
    self.checkboxes[groupName] = []

    for idx, label in enumerate(labels):
        col = idx % 4
        row = idx // 4

        btn = ui.ToggleButton()
        btn.SetParent(groupWnd)
        btn.SetUpVisual("d:/ymir work/ui/game/myshop_deco/select_btn_01.sub")
        btn.SetOverVisual("d:/ymir work/ui/game/myshop_deco/select_btn_02.sub")
        btn.SetDownVisual("d:/ymir work/ui/game/myshop_deco/select_btn_03.sub")
        btn.SetText(label)
        btn.SetPosition(col * COL_WIDTH, row * ROW_HEIGHT)
        btn.SetToggleUpEvent(ui.__mem_func__(self.__OnCheckboxChanged), groupName, idx)
        btn.SetToggleDownEvent(ui.__mem_func__(self.__OnCheckboxChanged), groupName, idx)
        btn.Show()
        self.InsertChild("chk_{}_{}".format(groupName, idx), btn)
        self.checkboxes[groupName].append(btn)

    return groupWnd

def __OnCheckboxChanged(self, groupName, idx):
    pass  # override or extend — state is in btn.IsDown()

def GetCheckboxStates(self, groupName):
    return [btn.IsDown() for btn in self.checkboxes.get(groupName, [])]
```

**Pitfalls:**
- `SetToggleUpEvent` and `SetToggleDownEvent` both accept extra args —
  no lambda needed, args go through `ui.__mem_func__` cleanly
- `IsDown()` returns the current toggle state — `True` = checked
- `Down()` forces checked state, `SetUp()` forces unchecked — use these
  to set initial state programmatically
- Initialize `self.checkboxes` in `Initialize()` as `{}` for proper cleanup

### 7.4 Search-filtered list

An edit line input above a `ListBoxEx` that filters items on every
keystroke. Uses the `OnIMEUpdate` monkey-patch pattern from the codebase.

```python
def __CreateFilteredList(self, parent, yPos):
    # Search input
    searchBar = ui.SlotBar()
    searchBar.SetParent(parent)
    searchBar.SetPosition(10, yPos)
    searchBar.SetSize(parent.GetWidth() - 20, 18)
    searchBar.Show()
    self.InsertChild("searchBar", searchBar)

    searchEdit = ui.EditLine()
    searchEdit.SetParent(searchBar)
    searchEdit.SetPosition(4, 2)
    searchEdit.SetSize(searchBar.GetWidth() - 8, 18)
    searchEdit.SetMax(20)
    searchEdit.Show()
    self.InsertChild("searchEdit", searchEdit)
    self.searchEdit = searchEdit

    # Hook text changes — MUST call original OnIMEUpdate inside handler
    searchEdit.OnIMEUpdate = ui.__mem_func__(self.__OnSearchUpdate)

    # Filtered list
    listBox = ui.ListBoxEx()
    listBox.SetParent(parent)
    listBox.SetPosition(10, yPos + 25)
    listBox.SetSize(parent.GetWidth() - 30, parent.GetHeight() - yPos - 35)
    listBox.SetItemStep(20)
    listBox.SetItemSize(parent.GetWidth() - 30, 20)
    listBox.SetViewItemCount(
        (parent.GetHeight() - yPos - 35) // 20
    )
    listBox.Show()
    self.InsertChild("filteredList", listBox)
    self.filteredList = listBox

    scrollBar = ui.ScrollBar()
    scrollBar.SetParent(parent)
    scrollBar.SetPosition(parent.GetWidth() - 18, yPos + 25)
    scrollBar.SetScrollBarSize(parent.GetHeight() - yPos - 35)
    scrollBar.Show()
    self.InsertChild("filterScroll", scrollBar)
    listBox.SetScrollBar(scrollBar)

    self.allItems = []  # [(key, displayText, itemWidget), ...]

def AddFilterItem(self, key, displayText):
    item = ui.ListBoxEx.Item()
    item.SetParent(self.filteredList)

    textLine = ui.TextLine()
    textLine.SetParent(item)
    textLine.SetPosition(5, 0)
    textLine.SetText(displayText)
    textLine.Show()

    item.Show()
    self.allItems.append((key, displayText, item))
    self.filteredList.AppendItem(item)

def __OnSearchUpdate(self):
    # CRITICAL: call original to update displayed text in the edit line
    ui.EditLine.OnIMEUpdate(self.searchEdit)

    query = self.searchEdit.GetText().lower()
    self.filteredList.RemoveAllItems()

    for key, displayText, item in self.allItems:
        if not query or query in displayText.lower():
            self.filteredList.AppendItem(item)

def ClearFilter(self):
    self.searchEdit.SetText("")
    self.filteredList.RemoveAllItems()
    for key, displayText, item in self.allItems:
        self.filteredList.AppendItem(item)
```

**Pitfalls:**
- **CRITICAL:** The `OnIMEUpdate` handler MUST call
  `ui.EditLine.OnIMEUpdate(self.searchEdit)` — without it, the edit line
  won't visually update as the user types. This is the #1 bug with this
  pattern.
- The monkey-patch `searchEdit.OnIMEUpdate = ui.__mem_func__(self.__handler)`
  uses `ui.__mem_func__` to prevent circular reference leaks. Do not use
  a direct assignment like `searchEdit.OnIMEUpdate = self.__handler`.
- `OnKillFocus` calls `SetText()` but does NOT trigger `OnIMEUpdate` — if
  you need to react to focus-loss text changes, also hook `OnKillFocus`.
- `RemoveAllItems()` hides all items but keeps them alive. The items in
  `self.allItems` are reused across filter operations — no recreation.
- Initialize `self.allItems` as `[]`, `self.searchEdit` as `None`, and
  `self.filteredList` as `None` in `Initialize()` for proper cleanup.
- **Scrollbar limitation:** After filtering, the scrollbar's visual size
  (middle bar proportion) is not auto-recalculated by `ListBoxEx`. The
  scroll position resets to 0 on `RemoveAllItems()`, which is correct,
  but the bar size may not match the filtered item count. For most UIs
  this is acceptable — the scrollbar still works, just the proportional
  indicator may be inaccurate until the user scrolls.
