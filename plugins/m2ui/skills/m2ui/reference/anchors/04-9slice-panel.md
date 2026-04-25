# Anchor 04: 9-Slice Bordered Panel

## What this is + when to use it

A custom container with a 9-sliced bordered background — top-left corner, top edge (tiled), top-right corner, left edge (tiled), center fill (tiled), right edge (tiled), bottom-left corner, bottom edge (tiled), bottom-right corner. Use this when standard `board` chrome doesn't match your visual style and you need a custom panel skin (description panels inside a window, sub-frames, decorated content areas). NOT for plain rectangular backgrounds (use `expanded_image` once with a single image). NOT for windows where the default `board_with_titlebar` chrome is acceptable. NOT for content that would look fine in a `bar` widget.

## Source

Extracted from `pack/pack/uiscript/uiscript/worldbosswindow.py` — the `desc_window` child uses the canonical `border_A_*` 9-slice pattern from `d:/ymir work/ui/pattern/`. The full window has many other children (timers, buttons, info text). This anchor extracts ONLY the 9-slice container; the surrounding window is generic boilerplate.

The `border_A_*` asset family in `d:/ymir work/ui/pattern/` contains:
- 4 corners: `border_A_left_top.tga`, `border_A_right_top.tga`, `border_A_left_bottom.tga`, `border_A_right_bottom.tga` (each 16×16)
- 4 edges: `border_A_top.tga`, `border_A_left.tga`, `border_A_right.tga`, `border_A_bottom.tga` (each 16×16, tiled via `expanded_image` `rect`)
- 1 center: `border_A_center.tga` (16×16, tiled to fill the inner rect)

Normalized to current m2ui rules:

- `//` for int division, not `/`
- `"style": ("not_pick", "ltr")` on every 9-slice child (decorative — must NOT swallow clicks meant for content placed inside the panel)
- Asset paths lowercase forward-slash
- Source's untranslated Korean comments stripped

Root class is minimal — the 9-slice itself doesn't drive logic. If the panel hosts interactive children, root class still uses `LoadScriptFile` + lifecycle from the standard window template.

## Uiscript dict

```python
import uiScriptLocale

PATTERN_PATH = "d:/ymir work/ui/pattern/"

DESC_WINDOW_WIDTH  = 378
DESC_WINDOW_HEIGHT = 300
# Corner is 16x16. Center/edges tile across (W - 32) / 16 and (H - 32) / 16 units.
DESC_WINDOW_PATTERN_X_COUNT = (DESC_WINDOW_WIDTH - 32) // 16
DESC_WINDOW_PATTERN_Y_COUNT = (DESC_WINDOW_HEIGHT - 32) // 16

window = {
    "name" : "DescPanelWindow",
    "style" : ("movable", "float",),

    "x" : SCREEN_WIDTH // 2 - 200,
    "y" : SCREEN_HEIGHT // 2 - 187,

    "width"  : 400,
    "height" : 374,

    "children" :
    [
        {
            "name"   : "board",
            "type"   : "board_with_titlebar",
            "x"      : 0,
            "y"      : 0,
            "width"  : 400,
            "height" : 374,
            "title"  : uiScriptLocale.DESC_PANEL_TITLE,

            "children" :
            [
                {
                    "name"   : "desc_window",
                    "type"   : "window",
                    "style"  : ("ltr", "attach",),

                    "x"      : 10,
                    "y"      : 32,

                    "width"  : DESC_WINDOW_WIDTH,
                    "height" : DESC_WINDOW_HEIGHT,

                    "children" :
                    [
                        # ----- 9-slice frame: 4 corners + 4 edges + center -----

                        # Corner 1 of 4: top-left
                        {
                            "name"  : "DescWindowLeftTop",
                            "type"  : "image",
                            "style" : ("ltr", "not_pick",),

                            "x" : 0,
                            "y" : 0,
                            "image" : PATTERN_PATH + "border_A_left_top.tga",
                        },
                        # Corner 2 of 4: top-right
                        {
                            "name"  : "DescWindowRightTop",
                            "type"  : "image",
                            "style" : ("ltr", "not_pick",),

                            "x" : DESC_WINDOW_WIDTH - 16,
                            "y" : 0,
                            "image" : PATTERN_PATH + "border_A_right_top.tga",
                        },
                        # Corner 3 of 4: bottom-left
                        {
                            "name"  : "DescWindowLeftBottom",
                            "type"  : "image",
                            "style" : ("ltr", "not_pick",),

                            "x" : 0,
                            "y" : DESC_WINDOW_HEIGHT - 16,
                            "image" : PATTERN_PATH + "border_A_left_bottom.tga",
                        },
                        # Corner 4 of 4: bottom-right
                        {
                            "name"  : "DescWindowRightBottom",
                            "type"  : "image",
                            "style" : ("ltr", "not_pick",),

                            "x" : DESC_WINDOW_WIDTH - 16,
                            "y" : DESC_WINDOW_HEIGHT - 16,
                            "image" : PATTERN_PATH + "border_A_right_bottom.tga",
                        },

                        # Edge 1 of 4: top (tiled across X axis)
                        {
                            "name"  : "DescWindowTopCenterImg",
                            "type"  : "expanded_image",
                            "style" : ("ltr", "not_pick",),

                            "x" : 16,
                            "y" : 0,
                            "image" : PATTERN_PATH + "border_A_top.tga",
                            "rect"  : (0.0, 0.0, DESC_WINDOW_PATTERN_X_COUNT, 0),
                        },
                        # Edge 2 of 4: left (tiled across Y axis)
                        {
                            "name"  : "DescWindowLeftCenterImg",
                            "type"  : "expanded_image",
                            "style" : ("ltr", "not_pick",),

                            "x" : 0,
                            "y" : 16,
                            "image" : PATTERN_PATH + "border_A_left.tga",
                            "rect"  : (0.0, 0.0, 0, DESC_WINDOW_PATTERN_Y_COUNT),
                        },
                        # Edge 3 of 4: right (tiled across Y axis)
                        {
                            "name"  : "DescWindowRightCenterImg",
                            "type"  : "expanded_image",
                            "style" : ("ltr", "not_pick",),

                            "x" : DESC_WINDOW_WIDTH - 16,
                            "y" : 16,
                            "image" : PATTERN_PATH + "border_A_right.tga",
                            "rect"  : (0.0, 0.0, 0, DESC_WINDOW_PATTERN_Y_COUNT),
                        },
                        # Edge 4 of 4: bottom (tiled across X axis)
                        {
                            "name"  : "DescWindowBottomCenterImg",
                            "type"  : "expanded_image",
                            "style" : ("ltr", "not_pick",),

                            "x" : 16,
                            "y" : DESC_WINDOW_HEIGHT - 16,
                            "image" : PATTERN_PATH + "border_A_bottom.tga",
                            "rect"  : (0.0, 0.0, DESC_WINDOW_PATTERN_X_COUNT, 0),
                        },

                        # Center fill (tiled across both axes)
                        {
                            "name"  : "DescWindowCenterImg",
                            "type"  : "expanded_image",
                            "style" : ("ltr", "not_pick",),

                            "x" : 16,
                            "y" : 16,
                            "image" : PATTERN_PATH + "border_A_center.tga",
                            "rect"  : (0.0, 0.0, DESC_WINDOW_PATTERN_X_COUNT, DESC_WINDOW_PATTERN_Y_COUNT),
                        },

                        # ----- Content children go here, all positioned relative
                        # to the 9-slice's outer rect. Respect the 16px border padding:
                        # content_x in [16, DESC_WINDOW_WIDTH - 16], same for y.
                        # Example placeholder content widget:
                        # {
                        #     "name" : "content_text",
                        #     "type" : "text",
                        #     "x"    : 16, "y" : 16,
                        #     "text" : "Panel content here.",
                        # },
                    ],
                },
            ],
        },
    ],
}
```

## Root class

```python
import ui


class DescPanelWindow(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.Initialize()
        self.__LoadWindow()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def Initialize(self):
        self.descWindow = None
        # Add named refs for the 9-slice children only if the root class needs to
        # mutate them at runtime (e.g., resize). For a static panel, you don't
        # need to GetChild any of the 9 widgets — they live in the dict.

    def __LoadWindow(self):
        try:
            pyScrLoader = ui.PythonScriptLoader()
            pyScrLoader.LoadScriptFile(self, "uiscript/descpanelwindow.py")
        except:
            import exception
            exception.Abort("DescPanelWindow.__LoadWindow.LoadScript")

        try:
            self.descWindow = self.GetChild("desc_window")
            # board_with_titlebar exposes its inner titlebar via the window's
            # GetChild("TitleBar") directly — wire its X button to root Close,
            # otherwise clicking X hides only the inner board, leaving root visible.
            self.GetChild("TitleBar").SetCloseEvent(ui.__mem_func__(self.Close))
        except:
            import exception
            exception.Abort("DescPanelWindow.__LoadWindow.BindObject")

    @ui.WindowDestroy
    def Destroy(self):
        self.ClearDictionary()
        self.Initialize()

    def Open(self):
        self.SetCenterPosition()
        self.SetTop()
        self.Show()

    def Close(self):
        self.Hide()

    def OnPressEscapeKey(self):
        self.Close()
        return True
```

If you need the panel to resize at runtime (rare), add a method that recomputes the corner/edge positions and calls `SetSize` on each:

```python
    def SetPanelSize(self, width, height):
        # Edges tile via the rect tuple; reset rect after SetSize.
        x_units = (width - 32) // 16
        y_units = (height - 32) // 16

        self.descWindow.SetSize(width, height)
        self.GetChild("DescWindowRightTop").SetPosition(width - 16, 0)
        self.GetChild("DescWindowLeftBottom").SetPosition(0, height - 16)
        self.GetChild("DescWindowRightBottom").SetPosition(width - 16, height - 16)
        self.GetChild("DescWindowTopCenterImg").SetRenderingRect(0.0, 0.0, x_units, 0)
        self.GetChild("DescWindowBottomCenterImg").SetRenderingRect(0.0, 0.0, x_units, 0)
        self.GetChild("DescWindowLeftCenterImg").SetRenderingRect(0.0, 0.0, 0, y_units)
        self.GetChild("DescWindowRightCenterImg").SetRenderingRect(0.0, 0.0, 0, y_units)
        self.GetChild("DescWindowCenterImg").SetRenderingRect(0.0, 0.0, x_units, y_units)
```

## Locale entries

```python
# Only the title and any internal content. The 9-slice itself has no text.
DESC_PANEL_TITLE    Description
```

## interfacemodule.py integration snippet

```python
import descpanelwindow

# In MakeInterface or __init__:
self.wndDescPanel = descpanelwindow.DescPanelWindow()

def ToggleDescPanel(self):
    if self.wndDescPanel.IsShow():
        self.wndDescPanel.Close()
    else:
        self.wndDescPanel.Open()

# In HideAllWindows:
def HideAllWindows(self):
    if self.wndDescPanel:
        self.wndDescPanel.Close()

# In __del__:
def __del__(self):
    if self.wndDescPanel:
        self.wndDescPanel.Destroy()
        self.wndDescPanel = None
```

## Common variations

1. **Replace 9 widgets with one `expanded_image`** — if your art is a single texture (no separate corners/edges/center), use one widget with `"image"` set to the full panel art and `expanded_image` `rect` covering the full area. Simpler, less flexible.
2. **Add a title bar to the top edge** — overlay a `titlebar` child on top of `DescWindowTopCenterImg` (don't remove the top edge — they coexist). Adjust title bar `x`/`y` to land between the corners.
3. **Different art for hover state** — call `widget.LoadImage(hoverPath)` from `OnMouseOverIn`. Trigger hover via a transparent button overlay on top (the 9-slice children are `not_pick`, so add a sibling `button` for picking).
4. **Nested 9-slice (panel-in-panel)** — same pattern, just a child Window with its own 9 widgets, nested inside `desc_window`. Inner panel's `x`/`y` must be ≥ 16 to land inside the outer border.
5. **Different border art** — swap `PATTERN_PATH + "border_A_*"` for `border_B_*` etc. Same 9-slice math, different texture family.

## Don't copy these obsolete bits

- Source uses `(DESC_WINDOW_WIDTH - 32) / 16` (Python 2 division) — REPLACED with `// 16`. Under Python 3 the float result would break `SetRenderingRect`.
- Source 9-slice children only have `"style": ("ltr",)` — ADDED `"not_pick"` to every one. Decorative widgets MUST NOT swallow clicks meant for siblings/content; the engine respects `not_pick` in the hit-test pass.
- Source has no `Initialize()` / `Destroy()` on the consuming root class (different file consumes this uiscript) — ADDED here. Children of the 9-slice leak otherwise.
- Source has Korean comments interleaved (`# ��¥ �ֵ�` etc.) — STRIPPED. Encoding is unreliable cross-platform; comment-free or English-only comments are safer.
- Source has `RightBottom` named `"ListWindowRightBottom"` (typo / copy-paste from another window) — RENAMED to `"DescWindowRightBottom"` for naming consistency.
