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
import uiScriptLocale

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
                            "text" : uiScriptLocale.MY_WINDOW_TITLE,
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

                    "text" : uiScriptLocale.OK,

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

                    "text" : uiScriptLocale.CANCEL,

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
        # No ClearDictionary() needed — @ui.WindowDestroy handles
        # children registered via InsertChild() automatically.
        # Only script-backed windows (Style 1) need ClearDictionary().
        self.Initialize()

    def __LoadDialog(self):
        self.SetSize(self.WINDOW_WIDTH, self.WINDOW_HEIGHT)
        self.AddFlag("movable")

        # -- Board with title bar --
        board = ui.BoardWithTitleBar()
        board.SetParent(self)
        board.AddFlag("attach")
        board.SetTitleName(localeInfo.MY_FEATURE_TITLE)
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
        textLine.SetText(localeInfo.MY_FEATURE_DESCRIPTION)
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
        slotX = (board.GetWidth() - slotWidth) // 2
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
        btnX = (board.GetWidth() - btn.GetWidth()) // 2
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
containerX = (board.GetWidth() - totalWidth) // 2
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
  -> Hide tooltip (if tooltipItem)
  -> Kill editline focus (if has editlines)
  -> Clear wheel top window (if SetWheelTopWindow was used)
  -> Destroy owned dialogs (confirmDialog, etc.)
  -> Hide()

Destroy()               # decorated with @ui.WindowDestroy
  -> Initialize()       # reset all vars
  -> ClearDictionary()  # only for script-backed (Style 1)
  -> Hide()

__del__()
  -> ScriptWindow.__del__(self)
```

### 5.10 Close() cleanup checklist

```python
def Close(self):
    if self.tooltipItem:
        self.tooltipItem.HideToolTip()

    if self.confirmDialog:
        self.confirmDialog.Close()
        self.confirmDialog = None

    # Kill editline focus to stop IME capture
    # (otherwise typing goes to the hidden editline)
    if self.editLine and self.editLine.IsFocus():
        self.editLine.KillFocus()

    # Clear wheel top window if SetWheelTopWindow was used
    # (otherwise mouse wheel events still route to this hidden window)
    wndMgr.ClearWheelTopWindow()

    self.Hide()
```

Not every window needs all of these — only add the ones relevant to
your window's widgets. But forgetting them causes subtle bugs:
- Hidden tooltip stays visible after window closes
- IME input goes to a hidden editline
- Mouse wheel events route to wrong window
- Owned dialog's weak refs die but dialog stays visible

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

### 7.5 Paginated slot grid

Multiple `grid_table` widgets overlaid at the same position, switched
via radio button tabs. Each grid uses a different `start_index` to map
to different slot ranges. Common for shops, inventories, and skill pages.

**Uiscript approach** (recommended for static grids):

```python
import uiScriptLocale

SLOT_X_COUNT = 5
SLOT_Y_COUNT = 8
SLOTS_PER_PAGE = SLOT_X_COUNT * SLOT_Y_COUNT  # 40

window = {
    "name": "PagedShopWindow",
    "style": ("movable", "float",),
    "x": 0, "y": 0,
    "width": 200, "height": 300,
    "children": (
        {
            "name": "Board",
            "type": "board",
            "style": ("attach",),
            "x": 0, "y": 0,
            "width": 200, "height": 300,
            "children": (
                {
                    "name": "ItemSlot_0",
                    "type": "grid_table",
                    "x": 8, "y": 35,
                    "start_index": 0,
                    "x_count": SLOT_X_COUNT,
                    "y_count": SLOT_Y_COUNT,
                    "x_step": 32,
                    "y_step": 32,
                    "image": "d:/ymir work/ui/public/slot_base.sub",
                },
                {
                    "name": "ItemSlot_1",
                    "type": "grid_table",
                    "x": 8, "y": 35,
                    "start_index": SLOTS_PER_PAGE,
                    "x_count": SLOT_X_COUNT,
                    "y_count": SLOT_Y_COUNT,
                    "x_step": 32,
                    "y_step": 32,
                    "image": "d:/ymir work/ui/public/slot_base.sub",
                },
                {
                    "name": "Tab_0",
                    "type": "radio_button",
                    "x": 50, "y": 5,
                    "text": "I",
                    "default_image": "d:/ymir work/ui/public/small_button_01.sub",
                    "over_image": "d:/ymir work/ui/public/small_button_02.sub",
                    "down_image": "d:/ymir work/ui/public/small_button_03.sub",
                },
                {
                    "name": "Tab_1",
                    "type": "radio_button",
                    "x": 115, "y": 5,
                    "text": "II",
                    "default_image": "d:/ymir work/ui/public/small_button_01.sub",
                    "over_image": "d:/ymir work/ui/public/small_button_02.sub",
                    "down_image": "d:/ymir work/ui/public/small_button_03.sub",
                },
            ),
        },
    ),
}
```

**Root class wiring:**

```python
PAGE_COUNT = 2
SLOTS_PER_PAGE = 40

def __LoadWindow(self):
    # ... LoadScriptFile ...

    self.slotPages = []
    self.tabButtons = []
    for i in range(PAGE_COUNT):
        self.slotPages.append(self.GetChild("ItemSlot_%d" % i))
        self.tabButtons.append(self.GetChild("Tab_%d" % i))

    from _weakref import proxy
    ref = proxy(self)
    self.radioGroup = ui.RadioButtonGroup.Create([
        (self.tabButtons[i], lambda page=i, r=ref: r.__SetPage(page), lambda page=i: None)
        for i in range(PAGE_COUNT)
    ])

def __SetPage(self, pageIndex):
    for i, page in enumerate(self.slotPages):
        if i == pageIndex:
            page.Show()
        else:
            page.Hide()
```

**Pitfalls:**
- `start_index` offsets each grid's slot numbering — page 0 uses slots
  0-39, page 1 uses slots 40-79. Slot event callbacks receive the
  absolute index, not the page-relative one.
- The select lambda uses `proxy(self)` to avoid a circular reference
  leak — same pattern as Section 7.2. The unselect lambda is safe since
  it captures only `page` (an int), not `self`.
- All grids occupy the same position — only one is visible at a time.
  `RadioButtonGroup.Create` auto-selects the first button.
- Initialize `self.slotPages` as `[]`, `self.tabButtons` as `[]`, and
  `self.radioGroup` as `None` in `Initialize()`.

### 7.6 Confirmation dialog (QuestionDialog)

Modal yes/no dialog using the built-in `uiCommon.QuestionDialog`. Use
for destructive actions, purchases, or any choice requiring confirmation.

```python
import uiCommon

def __AskConfirmation(self, message):
    dialog = uiCommon.QuestionDialog()
    dialog.SetText(message)
    dialog.SetAcceptEvent(ui.__mem_func__(self.__OnConfirmAccept))
    dialog.SetCancelEvent(ui.__mem_func__(self.__OnConfirmCancel))
    dialog.Open()
    self.confirmDialog = dialog

def __OnConfirmAccept(self):
    if self.confirmDialog:
        self.confirmDialog.Close()
    self.confirmDialog = None
    # proceed with action

def __OnConfirmCancel(self):
    if self.confirmDialog:
        self.confirmDialog.Close()
    self.confirmDialog = None
```

**Variants available in uiCommon:**
- `QuestionDialog` — single message line, accept/cancel buttons
- `QuestionDialog2` — two message lines (uses `questiondialog2.py`)
- `QuestionDialogWithTimeLimit` — auto-closes after timeout
- `PopupDialog` — single message with one OK button (acknowledgment only)
- `MoneyInputDialog` — numeric input with accept/cancel (gold/won entry)
- `InputDialog` — text input with accept/cancel

**Pitfalls:**
- Store the dialog as `self.confirmDialog` — if it goes out of scope,
  the weak references in `ui.__mem_func__` will die and callbacks won't fire.
- Always set `self.confirmDialog = None` after closing — prevents stale
  references and ensures `@ui.WindowDestroy` can clean it up.
- `SetAcceptEvent` and `SetCancelEvent` directly set the button's event,
  so the callback MUST be wrapped in `ui.__mem_func__()`.
- For passing arguments to callbacks, use `SAFE_SetAcceptEvent` with
  `SAFE_SetEvent` (stores via `__mem_func__` internally), or use the
  closure pattern with `proxy(self)`.
- Initialize `self.confirmDialog` as `None` in `Initialize()`.

### 7.7 Numeric input with validation

SlotBar wrapper containing an EditLine for constrained numeric input.
Used for gold/won amounts, quantities, and level ranges.

```python
def __CreateNumericInput(self, parent, yPos, maxChars=12, label=""):
    if label:
        labelText = ui.TextLine()
        labelText.SetParent(parent)
        labelText.SetPosition(10, yPos + 2)
        labelText.SetText(label)
        labelText.Show()
        self.InsertChild("numLabel", labelText)

    slotBar = ui.SlotBar()
    slotBar.SetParent(parent)
    slotBar.SetPosition(100, yPos)
    slotBar.SetSize(120, 18)
    slotBar.Show()
    self.InsertChild("numSlot", slotBar)

    editLine = ui.EditLine()
    editLine.SetParent(slotBar)
    editLine.SetPosition(4, 2)
    editLine.SetSize(112, 18)
    editLine.SetMax(maxChars)
    editLine.SetNumberMode()
    editLine.Show()
    self.InsertChild("numInput", editLine)
    self.numInput = editLine

    editLine.OnIMEUpdate = ui.__mem_func__(self.__OnNumericUpdate)

def __OnNumericUpdate(self):
    ui.EditLine.OnIMEUpdate(self.numInput)

    text = self.numInput.GetText()
    if not text:
        return

    try:
        value = int(text)
    except ValueError:
        return

    MAX_VALUE = 2000000000
    if value > MAX_VALUE:
        value = MAX_VALUE
        self.numInput.SetText(str(value))

def GetNumericValue(self):
    text = self.numInput.GetText()
    if not text or not text.isdigit():
        return 0
    return min(int(text), 2000000000)
```

**Pitfalls:**
- `SetNumberMode()` restricts input to digits at the IME level — but
  still validate in Python because paste operations can bypass it.
- The `OnIMEUpdate` hook MUST call `ui.EditLine.OnIMEUpdate(self.numInput)`
  first — see Section 7.4 for why.
- Clamp to `2000000000` (signed 32-bit max for Metin2 gold). Exceeding
  this causes server-side overflow bugs.
- `int(text)` can raise `ValueError` if text is empty or non-numeric
  after paste — always wrap in try/except.
- For dual currency (Yang + Won), use `uiCommon.MoneyInputDialog()`
  instead — it handles both fields with proper validation and supports
  `app.ENABLE_CHEQUE_SYSTEM` conditionals.
- Initialize `self.numInput` as `None` in `Initialize()`.

### 7.8 Label-value parameter display

Text label paired with a visual slot containing a centered value.
Clean pattern for stats panels, guild info, shop earnings, and any
key-value data display.

```python
def __CreateLabelValue(self, parent, label, yPos, slotWidth=80):
    labelText = ui.TextLine()
    labelText.SetParent(parent)
    labelText.SetPosition(10, yPos + 2)
    labelText.SetText(label)
    labelText.Show()
    self.InsertChild("label_" + label, labelText)

    slotImg = ui.ImageBox()
    slotImg.SetParent(parent)
    slotImg.LoadImage("d:/ymir work/ui/public/parameter_slot_05.sub")
    slotImg.SetPosition(parent.GetWidth() - slotWidth - 10, yPos)
    slotImg.Show()
    self.InsertChild("slot_" + label, slotImg)

    valueText = ui.TextLine()
    valueText.SetParent(slotImg)
    valueText.SetPosition(0, 0)
    valueText.SetWindowHorizontalAlignCenter()
    valueText.SetHorizontalAlignCenter()
    valueText.SetVerticalAlignCenter()
    valueText.SetText("0")
    valueText.Show()
    self.InsertChild("value_" + label, valueText)

    return valueText

# Usage:
self.hpValue = self.__CreateLabelValue(statsPanel, localeInfo.HP, 10)
self.mpValue = self.__CreateLabelValue(statsPanel, localeInfo.SP, 35)
self.goldValue = self.__CreateLabelValue(statsPanel, localeInfo.GOLD, 60, slotWidth=120)

# Updating:
self.hpValue.SetText(str(player.GetStatus(player.HP)))
self.goldValue.SetText(constInfo.intWithCommas(player.GetElk()))
```

**Pitfalls:**
- The value TextLine is parented to the image slot, not to the panel —
  this ensures it stays centered within the slot regardless of position.
- Use `SetWindowHorizontalAlignCenter()` + `SetHorizontalAlignCenter()`
  together for proper centering within the parent image.
- For large numbers, always use `constInfo.intWithCommas()`.
- The image `parameter_slot_05.sub` is a standard Metin2 slot background.
  Other options: `parameter_slot_01.sub` through `_06.sub`.
- No Initialize() cleanup needed for display-only text lines — they are
  cleaned up by `@ui.WindowDestroy` via `InsertChild`.

### 7.9 Animated indicator (ani_image)

Frame-by-frame animation using `AniImageBox`. Used for loading spinners,
HP/SP gauge animations, progress indicators, and buff effect overlays.

**Programmatic approach:**

```python
def __CreateLoadingSpinner(self, parent, xPos, yPos):
    spinner = ui.AniImageBox()
    spinner.SetParent(parent)
    spinner.SetPosition(xPos, yPos)
    spinner.SetDelay(6)
    for i in range(8):
        spinner.AppendImage("d:/ymir work/ui/loading/%02d.sub" % i)
    spinner.Show()
    self.InsertChild("spinner", spinner)
    self.spinner = spinner
    return spinner
```

**Uiscript approach:**

```python
{
    "name": "LoadingAni",
    "type": "ani_image",
    "x": 0, "y": 0,
    "delay": 6,
    "images": (
        "d:/ymir work/ui/loading/00.sub",
        "d:/ymir work/ui/loading/01.sub",
        "d:/ymir work/ui/loading/02.sub",
        # ... more frames
    ),
},
```

**As a gauge (partial fill):**

```python
def __CreateGaugeBar(self, parent, yPos, color="red"):
    gauge = ui.AniImageBox()
    gauge.SetParent(parent)
    gauge.SetPosition(10, yPos)
    gauge.SetDelay(6)
    for i in range(7):
        gauge.AppendImage("d:/ymir work/ui/pattern/gauge_%s.tga" % color)
    gauge.Show()
    self.InsertChild("gauge", gauge)
    self.gauge = gauge

def SetGaugePercentage(self, current, maximum):
    if maximum > 0:
        self.gauge.SetPercentage(current, maximum)
```

**Pitfalls:**
- `SetDelay(n)` sets the number of frames between animation steps —
  lower = faster. A delay of 6 at 60 FPS means ~10 changes per second.
- `AppendImage` adds frames in order — the animation loops automatically.
- `SetPercentage(cur, max)` uses `SetRenderingRect` internally to clip
  the image horizontally, creating a fill-bar effect. Only makes sense
  when all frames are the same image (gauge pattern).
- `OnEndFrame()` is called when the animation completes one full cycle —
  override it if you need a one-shot animation that stops or triggers
  an event after playing once.
- Animation runs as long as the widget is visible. `Hide()` pauses it,
  `Show()` resumes.
- Available gauge colors: `gauge_red.tga`, `gauge_blue.tga`,
  `gauge_green.tga` (standard Metin2 assets).
- Initialize `self.spinner` / `self.gauge` as `None` in `Initialize()`.

### 7.10 Scrollable mixed-widget container

A scrollable area containing arbitrary widgets (images, text, buttons,
slots — not just ListBoxEx items). Uses a Window as a virtual canvas
that repositions children on scroll, with clip mask to hide overflow.

This differs from Section 7.4 (search-filtered list) which uses
`ListBoxEx`. Use this pattern when each row is a complex widget
composition that doesn't fit the `ListBoxEx.Item` model.

```python
ITEM_HEIGHT = 60
VISIBLE_HEIGHT = 300

def __CreateScrollableContainer(self, parent, xPos, yPos, width):
    # Visible viewport — clips children to its bounds
    viewport = ui.Window()
    viewport.SetParent(parent)
    viewport.SetPosition(xPos, yPos)
    viewport.SetSize(width, VISIBLE_HEIGHT)
    viewport.Show()
    self.InsertChild("viewport", viewport)
    self.viewport = viewport

    # Virtual canvas — taller than viewport, holds all children
    canvas = ui.Window()
    canvas.SetParent(viewport)
    canvas.SetPosition(0, 0)
    canvas.SetSize(width, VISIBLE_HEIGHT)
    canvas.Show()
    self.InsertChild("canvas", canvas)
    self.canvas = canvas

    # Scrollbar
    scrollBar = ui.ScrollBar()
    scrollBar.SetParent(parent)
    scrollBar.SetPosition(xPos + width + 2, yPos)
    scrollBar.SetScrollBarSize(VISIBLE_HEIGHT)
    scrollBar.SetScrollEvent(ui.__mem_func__(self.__OnContainerScroll))
    scrollBar.Show()
    self.InsertChild("containerScroll", scrollBar)
    self.containerScroll = scrollBar

    self.containerItems = []
    self.containerItemCount = 0

def AddContainerItem(self, widget):
    """Add a pre-built widget to the scrollable container."""
    yPos = self.containerItemCount * ITEM_HEIGHT
    widget.SetParent(self.canvas)
    widget.SetPosition(0, yPos)
    widget.Show()

    if app.__BL_CLIP_MASK__:
        widget.SetClippingMaskWindow(self.viewport)

    self.containerItems.append(widget)
    self.containerItemCount += 1

    # Resize canvas to fit all items
    totalHeight = self.containerItemCount * ITEM_HEIGHT
    self.canvas.SetSize(self.canvas.GetWidth(), max(totalHeight, VISIBLE_HEIGHT))

def __OnContainerScroll(self):
    if self.containerItemCount <= 0:
        return

    totalHeight = self.containerItemCount * ITEM_HEIGHT
    scrollableHeight = totalHeight - VISIBLE_HEIGHT

    if scrollableHeight <= 0:
        return

    scrollPos = self.containerScroll.GetPos()
    offset = int(scrollPos * scrollableHeight)
    self.canvas.SetPosition(0, -offset)
```

**Building a complex item widget for each row:**

```python
def __CreateDungeonCard(self, index, iconPath, name, status):
    """Example: dungeon list entry with icon + text + status."""
    card = ui.Window()
    card.SetSize(self.viewport.GetWidth(), ITEM_HEIGHT)

    bg = ui.Bar()
    bg.SetParent(card)
    bg.SetPosition(0, 0)
    bg.SetSize(card.GetWidth(), ITEM_HEIGHT - 2)
    bg.SetColor(grp.GenerateColor(0.0, 0.0, 0.0, 0.5))
    bg.AddFlag("not_pick")
    bg.Show()

    icon = ui.ImageBox()
    icon.SetParent(card)
    icon.LoadImage(iconPath)
    icon.SetPosition(5, 5)
    icon.AddFlag("not_pick")
    icon.Show()

    nameText = ui.TextLine()
    nameText.SetParent(card)
    nameText.SetPosition(55, 5)
    nameText.SetText(name)
    nameText.Show()

    statusText = ui.TextLine()
    statusText.SetParent(card)
    statusText.SetPosition(55, 25)
    statusText.SetText(status)
    statusText.Show()

    if app.__BL_CLIP_MASK__:
        bg.SetClippingMaskWindow(self.viewport)
        icon.SetClippingMaskWindow(self.viewport)
        nameText.SetClippingMaskWindow(self.viewport)
        statusText.SetClippingMaskWindow(self.viewport)

    card.Show()
    return card
```

**Pitfalls:**
- **Clip mask is essential** for visual correctness — without it, children
  render outside the viewport bounds. Always guard with
  `if app.__BL_CLIP_MASK__:`.
- Apply `SetClippingMaskWindow(viewport)` to EVERY visible child widget
  inside each item — the card window itself AND all its children (bg,
  icon, text). Missing one causes that widget to render outside bounds.
- The canvas moves via `SetPosition(0, -offset)` — negative Y shifts it
  upward. Children's positions within the canvas stay fixed.
- **Picking still works** within viewport bounds because the viewport
  clips mouse events (parent bounds clip child picking).
- Without clip mask support, fall back to hiding items that are fully
  outside the viewport (check Y position against visible range in
  `__OnContainerScroll`).
- `Bar` with alpha (`grp.GenerateColor(0.0, 0.0, 0.0, 0.5)`) creates a
  semi-transparent background. Add `"not_pick"` so clicks pass through
  to the card underneath.
- Initialize `self.viewport`, `self.canvas`, `self.containerScroll` as
  `None`, `self.containerItems` as `[]`, and `self.containerItemCount`
  as `0` in `Initialize()`.

### 7.11 Semi-transparent dynamic info panel

A `ThinBoard` panel that auto-sizes based on its content. Used for
mob info popups, item tooltips, and any info panel where the content
varies per invocation. Based on `MobDropInfoWindow` from `uiTarget.py`.

```python
class InfoPanel(ui.ThinBoard):
    DEFAULT_WIDTH = 250
    BASE_HEIGHT = 13

    def __init__(self):
        ui.ThinBoard.__init__(self)
        self.Initialize()
        self.__LoadGUI()

    def __del__(self):
        ui.ThinBoard.__del__(self)

    def Initialize(self):
        self.titleText = None
        self.infoTexts = {}
        self.itemSlot = None
        self.tooltipItem = None
        self.contentHeight = self.BASE_HEIGHT

    @ui.WindowDestroy
    def Destroy(self):
        self.Initialize()

    def __ResetHeight(self):
        self.contentHeight = self.BASE_HEIGHT

    def __AdvanceHeight(self, amount):
        """Track cumulative Y position. Returns the Y before advancing."""
        y = self.contentHeight
        self.contentHeight += amount
        return y

    def __LoadGUI(self):
        self.AddFlag("float")
        self.AddFlag("movable")

        title = ui.TextLine()
        title.SetParent(self)
        title.SetPosition(0, self.__AdvanceHeight(20))
        title.SetWindowHorizontalAlignCenter()
        title.SetHorizontalAlignCenter()
        title.Show()
        self.titleText = title

        closeBtn = ui.Button()
        closeBtn.SetParent(self)
        closeBtn.SetUpVisual("d:/ymir work/ui/public/close_button_01.sub")
        closeBtn.SetOverVisual("d:/ymir work/ui/public/close_button_02.sub")
        closeBtn.SetDownVisual("d:/ymir work/ui/public/close_button_03.sub")
        closeBtn.SetPosition(30, 13)
        closeBtn.SetWindowHorizontalAlignRight()
        closeBtn.SetEvent(ui.__mem_func__(self.Close))
        closeBtn.Show()

    def AddSeparator(self):
        sep = ui.ExpandedImageBox()
        sep.SetParent(self)
        sep.LoadImage("d:/ymir work/ui/game/quest/quest_line.sub")
        sep.SetPosition(15, self.__AdvanceHeight(15))
        sep.AddFlag("not_pick")
        sep.Show()

    def AddTextLine(self, key, text="", centered=False):
        textLine = ui.TextLine()
        textLine.SetParent(self)
        yPos = self.__AdvanceHeight(18)
        if centered:
            textLine.SetPosition(0, yPos)
            textLine.SetWindowHorizontalAlignCenter()
            textLine.SetHorizontalAlignCenter()
        else:
            textLine.SetPosition(15, yPos)
        textLine.SetText(text)
        textLine.Show()
        self.infoTexts[key] = textLine
        return textLine

    def AddItemGrid(self, itemList, columns=6):
        """Add a grid of items with semi-transparent slot backgrounds."""
        if not itemList:
            return

        rows = (len(itemList) + columns - 1) // columns
        yPos = self.__AdvanceHeight(rows * 32 + 10)

        itemSlot = ui.GridSlotWindow()
        itemSlot.SetParent(self)
        itemSlot.SetPosition(
            (self.DEFAULT_WIDTH - columns * 32) // 2,
            yPos,
        )
        itemSlot.ArrangeSlot(0, columns, rows, 32, 32, 0, 0)
        wndMgr.SetSlotBaseImage(
            itemSlot.hWnd,
            "d:/ymir work/ui/public/slot_base.sub",
            1.0, 1.0, 1.0, 0.5,
        )
        itemSlot.Show()
        self.itemSlot = itemSlot

        for idx, entry in enumerate(itemList):
            itemSlot.SetItemSlot(idx, entry["vnum"], entry.get("count", 0))

        itemSlot.RefreshSlot()
        itemSlot.SetOverInItemEvent(ui.__mem_func__(self.OnOverInItem))
        itemSlot.SetOverOutItemEvent(ui.__mem_func__(self.OnOverOutItem))

    def SetItemToolTip(self, tooltip):
        self.tooltipItem = tooltip

    def ApplySize(self):
        """Call after adding all content to resize the panel."""
        self.SetSize(self.DEFAULT_WIDTH, self.contentHeight)

    def Open(self, title=""):
        self.titleText.SetText(title)
        self.ApplySize()
        self.SetCenterPosition()
        self.SetTop()
        self.Show()

    def Close(self):
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True

    def OnOverInItem(self, slotIndex):
        if not self.tooltipItem:
            return
        if not self.itemSlot:
            return
        self.tooltipItem.ClearToolTip()
        # self.tooltipItem.AddItemData(vnum, metinSlot, attrSlot)
        self.tooltipItem.ShowToolTip()

    def OnOverOutItem(self):
        if self.tooltipItem:
            self.tooltipItem.HideToolTip()
```

**Usage example:**

```python
panel = InfoPanel()
panel.AddTextLine("name", nonplayer.GetMonsterName(vnum), centered=True)
panel.AddSeparator()
panel.AddTextLine("hp", "Max HP: %s" % constInfo.intWithCommas(maxHP))
panel.AddTextLine("dmg", "Damage: %d - %d" % (minDmg, maxDmg))
panel.AddSeparator()
panel.AddItemGrid(dropList, columns=6)
panel.Open(title=localeInfo.MOB_INFO_TITLE)
```

**Key techniques:**
- **`__AdvanceHeight(amount)`**: returns current Y and advances the
  internal counter. Ensures each element is placed below the previous
  one without manual Y calculation. Reset with `__ResetHeight()` if
  repopulating.
- **Semi-transparent slot alpha**: pass `a=0.5` to
  `wndMgr.SetSlotBaseImage()` — the slot background renders at 50%
  opacity, letting the ThinBoard texture show through.
- **ThinBoard base class**: inherits the semi-transparent bordered
  appearance automatically. No explicit alpha setting needed for the
  board itself.
- **Dynamic sizing**: call `ApplySize()` after all content is added.
  The panel height equals `contentHeight` accumulated by
  `__AdvanceHeight` calls.

**Pitfalls:**
- `__AdvanceHeight` modifies `self.contentHeight` — calling it multiple
  times for the same element will over-count. Each element should call
  it exactly once.
- The `contentHeight` accumulates across `Open()` calls. If the panel
  is reopened with different content, call `__ResetHeight()` and rebuild
  the widgets, or track which widgets are dynamic vs static.
- `SetSlotBaseImage` alpha only affects the slot background image, not
  the item icons — items render at full opacity on the transparent base.
- Always check `self.itemSlot` is not `None` in event callbacks — the
  panel may be opened with no items (empty drop list).
- For very long content that exceeds screen height, consider combining
  with Section 7.10 (scrollable container) instead of growing the panel
  indefinitely.

### 7.12 Mouse attach / drag-to-slot

Items are dragged between windows using `mouseModule.mouseController`.
The controller holds one attached object at a time (item, money, or
skill) and renders it following the cursor. Dropping into a target
slot triggers the target window's `OnSelectEmptySlot` or
`OnSelectItemSlot` event.

**Receiving a dragged item (target window):**

```python
import mouseModule
import player

def OnSelectEmptySlot(self, selectedSlotPos):
    if not mouseModule.mouseController.isAttached():
        return

    attachedSlotType = mouseModule.mouseController.GetAttachedType()
    attachedSlotPos = mouseModule.mouseController.GetAttachedSlotNumber()
    attachedInvenType = player.SlotTypeToInvenType(attachedSlotType)
    mouseModule.mouseController.DeattachObject()

    if attachedSlotType != player.SLOT_TYPE_INVENTORY:
        return
    if attachedInvenType != player.INVENTORY:
        return

    # Validate item before accepting
    itemVnum = player.GetItemIndex(attachedSlotPos)
    item.SelectItem(itemVnum)
    if item.IsAntiFlag(item.ANTIFLAG_GIVE):
        return

    # Accept the item
    self.__AddItem(attachedInvenType, attachedSlotPos, selectedSlotPos)

def OnSelectItemSlot(self, selectedSlotPos):
    # Click on an occupied slot — remove item or swap
    mouseModule.mouseController.DeattachObject()
    self.__RemoveItem(selectedSlotPos)
```

**Initiating a drag (source window):**

```python
def SelectItemSlot(self, selectedSlotPos):
    if mouseModule.mouseController.isAttached():
        return

    selectedItemVNum = shop.GetItemID(selectedSlotPos)
    itemCount = shop.GetItemCount(selectedSlotPos)

    mouseModule.mouseController.AttachObject(
        self, player.SLOT_TYPE_SHOP,
        selectedSlotPos, selectedItemVNum, itemCount,
    )
    snd.PlaySound("sound/ui/pick.wav")
```

**Drag with callback (shop buy pattern):**

```python
def SelectItemSlot(self, selectedSlotPos):
    selectedItemID = shop.GetItemID(selectedSlotPos)
    itemCount = shop.GetItemCount(selectedSlotPos)

    mouseModule.mouseController.AttachObject(
        self, player.SLOT_TYPE_SHOP,
        selectedSlotPos, selectedItemID, itemCount,
    )
    mouseModule.mouseController.SetCallBack(
        "INVENTORY", ui.__mem_func__(self.DropToInventory),
    )
    snd.PlaySound("sound/ui/pick.wav")

def DropToInventory(self):
    attachedSlotPos = mouseModule.mouseController.GetAttachedSlotNumber()
    self.AskBuyItem(attachedSlotPos)
```

**Right-click on slot (UnselectItemSlot):**

```python
# Setup — right-click on occupied slot triggers UnselectItemSlot
self.itemSlot.SetUnselectItemSlotEvent(ui.__mem_func__(self.OnRightClickSlot))

# Or via SAFE_SetButtonEvent:
self.itemSlot.SAFE_SetButtonEvent("RIGHT", "EXIST", self.OnRightClickSlot)

def OnRightClickSlot(self, selectedSlotPos):
    # Direct action on right-click (no context menu in Metin2)
    net.SendShopBuyPacket(selectedSlotPos)
```

**Wiring slot events:**

```python
self.itemSlot.SetSelectEmptySlotEvent(ui.__mem_func__(self.OnSelectEmptySlot))
self.itemSlot.SetSelectItemSlotEvent(ui.__mem_func__(self.OnSelectItemSlot))
self.itemSlot.SetUnselectItemSlotEvent(ui.__mem_func__(self.OnRightClickSlot))
self.itemSlot.SetUseSlotEvent(ui.__mem_func__(self.OnUseSlot))
self.itemSlot.SetOverInItemEvent(ui.__mem_func__(self.OnOverInItem))
self.itemSlot.SetOverOutItemEvent(ui.__mem_func__(self.OnOverOutItem))
```

**Pitfalls:**
- Always call `DeattachObject()` as early as possible in the handler —
  before validation. Otherwise, if you return early, the item stays
  glued to the cursor.
- `GetAttachedType()` returns slot type constants like
  `player.SLOT_TYPE_INVENTORY`, `player.SLOT_TYPE_SHOP`,
  `player.SLOT_TYPE_DRAGON_SOUL_INVENTORY`. Check the type before
  accepting — don't let dragon soul items go into regular slots.
- `SetCallBack("INVENTORY", handler)` fires when the attached item is
  dropped into an inventory window. The handler receives no arguments —
  use `GetAttachedSlotNumber()` inside the callback to find which slot.
- There is no context menu widget in Metin2. "Right-click" on slots is
  handled by `SetUnselectItemSlotEvent` — it fires on right-click of
  an occupied slot. Wire it to a direct action (buy, use, remove).
- `isAttached()` must be checked before `GetAttachedType()` — calling
  getters without an attachment can return stale values.
- Validate `item.IsAntiFlag(item.ANTIFLAG_GIVE)` and
  `item.IsAntiFlag(item.ANTIFLAG_SELL)` before accepting items for
  trade/shop operations.

### 7.13 Tooltip on slot hover

Show item or skill tooltips when hovering over slots. The tooltip
widget is created externally (usually by interfacemodule.py) and
passed to the window via `SetItemToolTip()`.

```python
# --- Setup (called from interfacemodule.py) ---

def SetItemToolTip(self, tooltip):
    self.tooltipItem = tooltip

def SetSkillToolTip(self, tooltip):
    self.tooltipSkill = tooltip

# --- Wire events in __LoadWindow or __LoadDialog ---

self.itemSlot.SetOverInItemEvent(ui.__mem_func__(self.OnOverInItem))
self.itemSlot.SetOverOutItemEvent(ui.__mem_func__(self.OnOverOutItem))

# --- Event handlers ---

def OnOverInItem(self, slotIndex):
    if not self.tooltipItem:
        return

    self.tooltipItem.ClearToolTip()
    self.tooltipItem.SetInventoryItem(slotIndex)

def OnOverOutItem(self):
    if self.tooltipItem:
        self.tooltipItem.HideToolTip()
```

**Tooltip with custom data (not inventory-bound):**

```python
def OnOverInItem(self, slotIndex):
    if not self.tooltipItem:
        return

    itemVnum = self.__GetItemVnum(slotIndex)
    if not itemVnum:
        return

    self.tooltipItem.ClearToolTip()
    self.tooltipItem.AddItemData(itemVnum, [0, 0, 0], [(0, 0)] * 7)
    self.tooltipItem.ShowToolTip()
```

**Fixed-position tooltip (embedded in window):**

```python
# Create tooltip as child of this window, not floating
toolTip = uiToolTip.ItemToolTip()
toolTip.SetParent(self)
toolTip.SetPosition(15, 38)
toolTip.SetFollow(False)
toolTip.Show()
self.toolTip = toolTip
```

**Pitfalls:**
- Always check `if not self.tooltipItem: return` — the tooltip is set
  externally and may be `None` if interfacemodule didn't bind it.
- `ClearToolTip()` must be called before `SetInventoryItem()` or
  `AddItemData()` — otherwise tooltip content stacks.
- `HideToolTip()` not `Hide()` — the tooltip class has its own
  hide method that handles cleanup.
- `SetFollow(False)` makes the tooltip stay at a fixed position instead
  of following the mouse. Use for embedded previews (like uirefine.py).
- For slot windows that display items not in player inventory (shop,
  quest rewards), use `AddItemData(vnum, metinSlots, attrSlots)`
  instead of `SetInventoryItem(slotIndex)`.
- Initialize `self.tooltipItem` as `None` in `Initialize()`.

### 7.14 Slot overlay effects

Three mechanisms for visual feedback on grid slots: activation glow,
cover button overlay, and cooldown arc.

**Activation glow (colored border highlight):**

```python
# Green glow on active auto-potion slot
self.itemSlot.ActivateSlot(slotIndex, 36.0/255.0, 222.0/255.0, 3.0/255.0, 1.0)

# Default white glow
self.itemSlot.ActivateSlot(slotIndex)

# Remove glow
self.itemSlot.DeactivateSlot(slotIndex)

# Check state
if self.itemSlot.IsActivatedSlot(slotIndex):
    self.itemSlot.DeactivateSlot(slotIndex)
```

**Cover button (gray overlay / lock icon):**

```python
# Add cover button images to a slot (up/over/down/disable + visibility flags)
self.itemSlot.SetCoverButton(
    slotIndex,
    "d:/ymir work/ui/game/quest/slot_button_01.sub",  # up
    "d:/ymir work/ui/game/quest/slot_button_01.sub",  # over
    "d:/ymir work/ui/game/quest/slot_button_01.sub",  # down
    "d:/ymir work/ui/game/belt_inventory/slot_disabled.tga",  # disable
    False,  # visible initially
    False,  # always render
)

# Enable/disable based on state
if player.IsAvailableBeltInventoryCell(slotIndex):
    self.itemSlot.EnableCoverButton(slotIndex)
else:
    self.itemSlot.DisableCoverButton(slotIndex)
```

**Cooldown arc overlay:**

```python
# Set cooldown on a slot (total duration, elapsed time)
self.itemSlot.SetSlotCoolTime(slotIndex, coolTime, elapsedTime)

# Example: skill cooldown
if player.IsSkillCoolTime(slotIndex):
    (coolTime, elapsedTime) = player.GetSkillCoolTime(slotIndex)
    self.itemSlot.SetSlotCoolTime(slotIndex, coolTime, elapsedTime)
```

**Toggle slot (alternate highlight):**

```python
# Toggle highlight state (like checkbox on/off)
self.itemSlot.SetToggleSlot(slotIndex)
```

**Slot count overlay:**

```python
# Show stack count number on slot
self.itemSlot.SetSlotCount(slotIndex, count)

# With grade display
self.itemSlot.SetSlotCountNew(slotIndex, grade, count)
```

**Pitfalls:**
- `ActivateSlot` RGB values are 0.0-1.0 floats, not 0-255 ints.
  Divide by 255.0 when converting from color codes.
- `SetCoverButton` must be called before `EnableCoverButton` /
  `DisableCoverButton` — enabling without prior setup does nothing.
- `SetSlotCoolTime` renders a darkened arc overlay that animates from
  fully covered to fully revealed. The C++ engine handles the animation
  internally — no OnUpdate needed.
- Call `RefreshSlot()` after batch-updating slots to force visual refresh.
- `SetAlwaysRenderCoverButton(slotIndex, True)` forces the cover button
  to render even when the slot is empty.
- These are all wndMgr-level operations — they work on both `SlotWindow`
  and `GridSlotWindow`.

### 7.15 Auto-close on distance (OnUpdate polling)

Windows bound to an NPC or crafting station should auto-close when the
player walks too far away. Polls player position every frame in
`OnUpdate`.

```python
DISTANCE_LIMIT = 1000  # pixels — standard NPC interaction range

def Open(self):
    (self.startX, self.startY, _) = player.GetMainCharacterPosition()
    self.SetCenterPosition()
    self.SetTop()
    self.Show()

def Close(self):
    self.Hide()

def OnUpdate(self):
    (x, y, z) = player.GetMainCharacterPosition()
    if abs(x - self.startX) > DISTANCE_LIMIT or \
       abs(y - self.startY) > DISTANCE_LIMIT:
        self.Close()
```

**With network close packet:**

```python
def OnUpdate(self):
    (x, y, z) = player.GetMainCharacterPosition()
    if abs(x - self.startX) > DISTANCE_LIMIT or \
       abs(y - self.startY) > DISTANCE_LIMIT:
        self.__OnDistanceClose()

def __OnDistanceClose(self):
    self.Hide()
    net.SendCraftClosePacket()
```

**Pitfalls:**
- **CRITICAL: call `self.Hide()` BEFORE the network packet.** `OnUpdate`
  runs every frame. If the connection is laggy and the server hasn't
  responded yet, the window stays visible and `OnUpdate` keeps firing —
  flooding the server with close packets every frame. `self.Hide()` first
  ensures `OnUpdate` stops running (hidden windows don't receive updates).
- Store `self.startX` / `self.startY` in `Open()`, not `__init__()` —
  the player may have moved between window creation and opening.
- Use Manhattan distance (`abs(dx) + abs(dy)`) or axis-independent
  checks (`abs(dx) > LIMIT or abs(dy) > LIMIT`) — not Euclidean.
  The axis-independent check is what the codebase uses.
- `DISTANCE_LIMIT = 1000` is the standard NPC interaction range used
  by uicube.py, uishop.py, and uiacce.py.
- Initialize `self.startX` as `0` and `self.startY` as `0` in
  `Initialize()`.
- Don't add a guard flag (`self.alreadyClosed`) — `self.Hide()` already
  prevents further `OnUpdate` calls, so no double-fire risk.

### 7.16 Resource availability indicator

Color-coded text showing whether the player has enough of an item.
Used in crafting UIs, trade windows, and requirement displays.

```python
COLOR_ENOUGH = grp.GenerateColor(0.5411, 0.7254, 0.5568, 1.0)    # green
COLOR_NOT_ENOUGH = grp.GenerateColor(0.9, 0.4745, 0.4627, 1.0)   # red
COLOR_NEUTRAL = grp.GenerateColor(0.7843, 0.7843, 0.7843, 1.0)   # light gray

def __UpdateMaterialDisplay(self, slotIndex, requiredVnum, requiredCount):
    item.SelectItem(requiredVnum)
    itemName = item.GetItemName()
    haveCount = player.GetItemCountByVnum(requiredVnum)

    text = "%s (%d/%d)" % (itemName, haveCount, requiredCount)

    materialText = self.GetChild("material_%d" % slotIndex)
    materialText.SetText(text)

    if haveCount >= requiredCount:
        materialText.SetPackedFontColor(COLOR_ENOUGH)
    else:
        materialText.SetPackedFontColor(COLOR_NOT_ENOUGH)

def __GetMaxCraftCount(self, materials):
    """How many complete crafts can be made from current inventory."""
    maxCount = 999999
    for vnum, needed in materials:
        if needed <= 0:
            continue
        have = player.GetItemCountByVnum(vnum)
        maxCount = min(maxCount, have // needed)
    return max(0, maxCount)
```

**Pitfalls:**
- `grp.GenerateColor()` takes 0.0-1.0 RGBA floats. The green/red values
  above match the official cube renewal colors.
- `SetPackedFontColor(color)` sets text color from a packed int returned
  by `grp.GenerateColor()`. Alternative: `SetFontColor(r, g, b)` with
  separate float args (0.0-1.0).
- `player.GetItemCountByVnum(vnum)` counts across ALL inventory pages.
  No need to iterate slots manually.
- Use `//` for integer division in `__GetMaxCraftCount` — `/` returns
  float in Python 3.
- Call `__UpdateMaterialDisplay` on `Open()`, on quantity change, and
  after any inventory refresh event.

---

## 8. Python Version Compatibility

The Metin2 client uses **Python 2.7**. Some projects have migrated to
Python 3. Write Python 2.7 code but keep it Python 3-compatible where
possible, so the same UI code works on both versions.

### Rules

**Always use (works on both py2 and py3):**

```python
# Integer division — explicit //
rows = count // columns           # NOT count / columns

# Parenthesized print
print("debug: %d" % value)       # NOT print "debug: %d" % value

# Inequality operator
if a != b:                        # NOT if a <> b:

# Dictionary membership
if key in myDict:                 # NOT if myDict.has_key(key):

# Direct function call
func(*args)                       # NOT apply(func, args)

# Exception syntax
except ValueError as e:           # NOT except ValueError, e:

# String formatting (both work on py2.7+)
"name: %s" % name                 # classic
"name: {}".format(name)           # also fine
```

**Keep Python 2 style (NOT py3-compatible, but required):**

```python
# xrange — used everywhere in existing code, range() behaves
# differently in py2 (creates full list). Keep xrange.
for i in xrange(count):

# Old-style classes inherit from base — already done in all templates
class MyWindow(ui.ScriptWindow):
```

**Avoid (breaks on Python 3):**

```python
# map/filter for side effects — returns iterator in py3, never executes
map(ui.Window.Hide, self.children)        # WRONG in py3
for child in self.children: child.Hide()  # CORRECT

filter(lambda x: x.IsShow(), self.items)  # returns iterator in py3
[x for x in self.items if x.IsShow()]     # CORRECT (list comprehension)

# dict.keys/values/items returning lists — returns views in py3
keys = myDict.keys()     # list in py2, view in py3
keys = list(myDict.keys())  # safe on both (but usually unnecessary)

# Sorting with cmp parameter — removed in py3
myList.sort(cmp=myCompare)                    # WRONG in py3
myList.sort(key=functools.cmp_to_key(myCompare))  # py3 compatible
myList.sort(key=lambda x: x.sortValue)        # BEST — use key= directly

# Unicode string prefix — u"text" works on py2.7+ and py3.3+
# but avoid mixing str and unicode unnecessarily
```

**When in doubt:** Write it the Python 2.7 way. Compatibility is
nice-to-have, not mandatory. The client ships with a specific Python
version — the code must work on THAT version first.

---

## 9. Uiscript Dict Manipulation Helpers

`pack/pack/root/utils.py` provides helper functions for programmatic
modification of uiscript dicts at runtime. Use these when the `script`
mode needs to modify a loaded uiscript dict before or after
`LoadScriptFile`.

### Available helpers

```python
from utils import (
    GetElementDictByName,
    FindElementPos,
    FindElementRef,
    ElementAddBefore,
    ElementAddAfter,
    FindElement,
    ReplaceElement,
    AppendChildren,
)
```

| Function | Purpose |
|----------|---------|
| `GetElementDictByName(dct, name)` | Recursively search children tree for element by name. Returns the dict or `None`. |
| `FindElementPos(parent_children, name)` | Find index of element in a `children` list by name. Returns index or `-1`. |
| `FindElementRef(parent_children, name)` | Find element in a `children` list by name. Returns dict or `None`. |
| `ElementAddBefore(parent_children, name, obj)` | Insert `obj` before the element named `name` in a children list. |
| `ElementAddAfter(parent_children, name, obj)` | Insert `obj` after the element named `name` in a children list. |
| `FindElement(name, data)` | Recursively find element by name (simpler API than `GetElementDictByName`). |
| `ReplaceElement(name, nvalue, data)` | Replace all properties of the named element with `nvalue`. |
| `AppendChildren(name, children_tuple, data)` | Append child elements to the named element's children. |

### Usage example

```python
import utils

# Load and modify uiscript dict
pyScrLoader = ui.PythonScriptLoader()
scriptDict = {}
pyScrLoader.LoadScriptFile(self, "UIScript/MyWindow.py")

# Or modify before loading:
exec(open("UIScript/MyWindow.py").read(), scriptDict)
window = scriptDict["window"]

# Find and modify an element
board = utils.GetElementDictByName(window, "Board")
if board:
    board["width"] = 400

# Add a new button before the cancel button
newButton = {
    "name": "ExtraButton",
    "type": "button",
    "x": 0, "y": 30,
    "text": "Extra",
    "default_image": "d:/ymir work/ui/public/middle_button_01.sub",
    "over_image": "d:/ymir work/ui/public/middle_button_02.sub",
    "down_image": "d:/ymir work/ui/public/middle_button_03.sub",
}
boardChildren = list(board["children"])
utils.ElementAddBefore(boardChildren, "CancelButton", newButton)
board["children"] = tuple(boardChildren)

# Append children to an element
utils.AppendChildren("Board", (newButton,), window)
```

### Pitfalls

- `ElementAddBefore` / `ElementAddAfter` operate on **lists**, not
  tuples. Uiscript `children` are tuples — convert to list first,
  modify, then convert back to tuple.
- `GetElementDictByName` returns a reference to the dict inside the
  tree — modifying it modifies the original.
- `FindElementPos` and `FindElementRef` search only the direct
  children list, not recursively. Use `GetElementDictByName` or
  `FindElement` for recursive search.
- `ReplaceElement` deletes keys not in `nvalue` — it's a full
  replacement, not a merge. To merge, use `FindElement` + direct
  dict update instead.

---

## 10. Common Anti-Patterns

Mistakes found repeatedly in existing Metin2 UI code. The skill
should avoid these in generated code and flag them when modifying
existing files.

### Memory leaks

```python
# WRONG: direct bound method — circular reference leak
button.SetEvent(self.OnClick)

# WRONG: lambda captures self — same leak
slot.SetEvent(lambda i=idx: self.OnSlot(i))

# WRONG: __mem_func__ inside lambda — useless, lambda still holds self
slot.SetEvent(lambda: ui.__mem_func__(self.OnClick)())

# CORRECT:
button.SetEvent(ui.__mem_func__(self.OnClick))
slot.SetEvent(ui.__mem_func__(self.OnSlot), idx)

# CORRECT (RadioButtonGroup — use proxy):
from _weakref import proxy
ref = proxy(self)
lambda k=key, r=ref: r.OnSelect(k)
```

### Missing cleanup

```python
# WRONG: instance vars not reset in Initialize
def Initialize(self):
    self.board = None
    # forgot self.scrollBar, self.tooltipItem, etc.

# WRONG: no @ui.WindowDestroy
def Destroy(self):        # missing decorator — children not cleaned
    self.Initialize()

# WRONG: dialog stored in local var — goes out of scope, callbacks die
def AskConfirm(self):
    dlg = uiCommon.QuestionDialog()
    dlg.SetAcceptEvent(ui.__mem_func__(self.OnAccept))
    dlg.Open()
    # dlg goes out of scope — weak refs in __mem_func__ die

# CORRECT:
def AskConfirm(self):
    self.confirmDialog = uiCommon.QuestionDialog()  # store on self
    ...
```

### Network packet flooding

```python
# WRONG: OnUpdate sends packet every frame while visible
def OnUpdate(self):
    if self.__IsTooFar():
        net.SendClosePacket()  # fires 60x/sec until server responds

# CORRECT: Hide first, then send
def OnUpdate(self):
    if self.__IsTooFar():
        self.Hide()            # stops OnUpdate immediately
        net.SendClosePacket()
```

### Python 2/3 traps

```python
# WRONG: has_key (removed in py3)
if myDict.has_key("name"):
# CORRECT:
if "name" in myDict:

# WRONG: map for side effects (returns iterator in py3, never executes)
map(ui.Window.Hide, self.children)
# CORRECT:
for child in self.children:
    child.Hide()

# WRONG: / for integer division (returns float in py3)
page = slotIndex / SLOTS_PER_PAGE
# CORRECT:
page = slotIndex // SLOTS_PER_PAGE

# WRONG: sort with cmp (removed in py3)
items.sort(cmp=myCompare)
# CORRECT:
items.sort(key=lambda x: x.sortKey)
```

### Naming and style

```python
# WRONG: shadow builtins
list = filter(lambda x: x.IsShow(), self.items)
type = player.SLOT_TYPE_SHOP

# CORRECT: use descriptive names
visibleItems = [x for x in self.items if x.IsShow()]
slotType = player.SLOT_TYPE_SHOP

# WRONG: non-English variable names
self.Categoria = []
self.Porcentaje = 0
self.date_cube = {}

# CORRECT:
self.categories = []
self.successPercent = 0
self.recipeData = {}
```

### Missing validation

```python
# WRONG: no bounds check on slot hover
def OnOverInItem(self, slotIndex):
    item = self.itemList[slotIndex]  # IndexError if out of range

# CORRECT:
def OnOverInItem(self, slotIndex):
    if slotIndex < 0 or slotIndex >= len(self.itemList):
        return
    item = self.itemList[slotIndex]

# WRONG: int() without try/except on user input
value = int(editLine.GetText())  # ValueError on empty/non-numeric

# CORRECT:
text = editLine.GetText()
if not text or not text.isdigit():
    return
value = min(int(text), 2000000000)
```
