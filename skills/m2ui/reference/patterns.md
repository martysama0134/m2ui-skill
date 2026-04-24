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
