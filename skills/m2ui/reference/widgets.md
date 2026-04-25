# Widget Type Catalog

Reference for all widget types available in the Metin2 UI system (`ui.py`).
Each entry documents the **type string** used in uiscript dicts, the Python class it maps to,
supported dict properties (from `PythonScriptLoader.__Load*` methods), and key runtime methods.

Source: `pack/pack/root/ui.py` -- PythonScriptLoader (lines 3365-4293).

---

## Common Properties (all widget types)

Every element dict processed by `PythonScriptLoader` supports these properties.
They are handled by `LoadDefaultData` and `LoadChildren`, not by the individual `LoadElement*` methods.

| Property | Type | Required | Description |
|---|---|---|---|
| `name` | `str` | yes | Unique name for `GetChild()` lookup |
| `type` | `str` | no | Widget type string (defaults to `"window"` if omitted) |
| `x` | `int` | yes | X position relative to parent |
| `y` | `int` | yes | Y position relative to parent |
| `horizontal_align` | `str` | no | `"center"` or `"right"` -- sets window horizontal alignment |
| `vertical_align` | `str` | no | `"center"` or `"bottom"` -- sets window vertical alignment |
| `all_align` | any | no | If present, sets both horizontal and vertical align to center |
| `style` | `tuple` | no | Tuple of flag strings applied via `AddFlag()` |
| `children` | `tuple` | no | Nested child widget dicts |

### Style Flags

Common values for the `style` tuple:

| Flag | Effect |
|---|---|
| `"movable"` | Window can be dragged by the user |
| `"float"` | Window floats above others |
| `"attach"` | Window attaches to parent (moves with it) |
| `"not_pick"` | Window is not pickable by mouse |
| `"ltr"` | Force left-to-right layout |
| `"rtl"` | Force right-to-left layout |

### Root-Level Window Dict

The top-level `window = { ... }` dict in a uiscript file uses `BODY_KEY_LIST`:

| Property | Type | Required |
|---|---|---|
| `name` | `str` | yes |
| `x` | `int` | yes |
| `y` | `int` | yes |
| `width` | `int` | yes |
| `height` | `int` | yes |
| `style` | `tuple` | no |
| `children` | `tuple` | no |

Available constants: `SCREEN_WIDTH`, `SCREEN_HEIGHT`.

---

## Container Types

### window

Basic invisible container. Used for grouping and layout.

- **Class:** `ScriptWindow` (extends `Window`)
- **Loader:** `LoadElementWindow`
- **Required key list:** `WINDOW_KEY_LIST` = `("width", "height")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width in pixels |
| `height` | `int` | yes | Height in pixels |

**Key methods:**
- `SetSize(width, height)`
- `Show()` / `Hide()`
- `SetPosition(x, y)`
- `GetChild(name)` -- retrieve named child from `ElementDictionary`

**Nesting:** Can contain any widget type as children.

---

### board

Decorative bordered panel with corner and line pattern images. Standard dialog background.

- **Class:** `Board` (extends `Window`)
- **Loader:** `LoadElementBoard`
- **Required key list:** `BOARD_KEY_LIST` = `("width", "height")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width (min 64px due to corner size) |
| `height` | `int` | yes | Height (min 64px due to corner size) |

**Key methods:**
- `SetSize(width, height)` -- auto-arranges corner/line images

**Notes:** Uses `d:/ymir work/ui/pattern/Board_Corner_*.tga` and `Board_Line_*.tga` pattern images internally. Minimum size is `CORNER_WIDTH*2` x `CORNER_HEIGHT*2` (64x64).

**Nesting:** Typically the outermost container for dialog windows. Can contain any widget type.

---

### board_with_titlebar

Board with a built-in title bar and close button.

- **Class:** `BoardWithTitleBar` (extends `Board`)
- **Loader:** `LoadElementBoardWithTitleBar`
- **Required key list:** `BOARD_WITH_TITLEBAR_KEY_LIST` = `("width", "height", "title")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width in pixels |
| `height` | `int` | yes | Height in pixels |
| `title` | `str` | yes | Title text displayed in the title bar |

**Key methods:**
- `SetSize(width, height)`
- `SetTitleName(name)` -- change title text at runtime
- `SetTitleColor(color)` -- change title text color (packed color)
- `SetCloseEvent(event)` -- set close button callback

**Notes:** Title bar is automatically positioned at (8, 7) inside the board. Close button is built in. Default close event is `self.Hide`.

**Nesting:** Can contain any widget type. The title bar occupies the top ~30px.

---

### thinboard

Lightweight bordered panel with a semi-transparent black background.

- **Class:** `ThinBoard` (extends `Window`)
- **Loader:** `LoadElementThinBoard`
- **Required key list:** `BOARD_KEY_LIST` = `("width", "height")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width (min 32px) |
| `height` | `int` | yes | Height (min 32px) |

**Key methods:**
- `SetSize(width, height)`
- `ShowInternal()` / `HideInternal()` -- show/hide decorative elements

**Notes:** Uses `ThinBoard_Corner_*.tga` and `ThinBoard_Line_*.tga` patterns. Background is a `Bar` with 51% opacity black (`0.0, 0.0, 0.0, 0.51`). Corner size is 16x16. Minimum size 32x32.

**Nesting:** Can contain any widget type. Good for sub-panels inside a board.

---

### thinboard_gold

Gold-themed variant of thinboard.

- **Class:** `ThinBoardGold` (extends `Window`)
- **Loader:** `LoadElementThinBoard` (same loader as thinboard)
- **Required key list:** `BOARD_KEY_LIST` = `("width", "height")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width (min 32px) |
| `height` | `int` | yes | Height (min 32px) |

**Notes:** Uses `thinboardgold/ThinBoard_Corner_*_Gold.tga` and `ThinBoard_Line_*_Gold.tga` patterns. Background uses `Board_Base.tga` with 80% alpha via `ExpandedImageBox`.

---

### thinboard_circle

Rounded-corner variant of thinboard with solid black background.

- **Class:** `ThinBoardCircle` (extends `Window`)
- **Loader:** `LoadElementThinBoard` (same loader as thinboard)
- **Required key list:** `BOARD_KEY_LIST` = `("width", "height")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width (min 8px) |
| `height` | `int` | yes | Height (min 8px) |

**Key methods:**
- `SetSize(width, height)`
- `SetText(text)` -- set centered text
- `GetText()` -- get text content

**Notes:** Uses `thinboardcircle/ThinBoard_Corner_*_Circle.tga` patterns. Corner size is 4x4. Background is fully opaque black (`0.0, 0.0, 0.0, 1.0`).

---

## Input Types

### button

Standard clickable button with image states.

- **Class:** `Button` (extends `Window`)
- **Loader:** `LoadElementButton`
- **Required key list:** none (no mandatory keys beyond DEFAULT_KEY_LIST)

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | no | Button width (usually auto-sized from images) |
| `height` | `int` | no | Button height |
| `default_image` | `str` | no | Normal state image path |
| `over_image` | `str` | no | Mouse-over state image path |
| `down_image` | `str` | no | Pressed state image path |
| `disable_image` | `str` | no | Disabled state image path |
| `text` | `str` | no | Button label text |
| `text_height` | `int` | no | Text vertical offset (passed as 2nd arg to `SetText`) |
| `text_color` | packed color | no | Color of button text |
| `tooltip_text` | `str` | no | Tooltip text shown on hover |
| `tooltip_x` | `int` | no | Tooltip X offset (used with `tooltip_y`) |
| `tooltip_y` | `int` | no | Tooltip Y offset (default -19) |

**Key methods:**
- `SetUpVisual(filename)` / `SetOverVisual(filename)` / `SetDownVisual(filename)` / `SetDisableVisual(filename)`
- `SetText(text, height=4)` -- set button label
- `SetTextColor(color)` -- set label color (packed)
- `SetToolTipText(text, x=0, y=-19)`
- `SetEvent(func, *args)` / `SAFE_SetEvent(func, *args)` -- set click callback
- `Enable()` / `Disable()`
- `Down()` / `SetUp()` -- force pressed/released state
- `Flash()` -- flash animation
- `IsDown()` -- check if pressed
- `SetOverEvent(func, *args)` / `SetOverOutEvent(func, *args)` -- hover callbacks

**Common image paths:**
```
d:/ymir work/ui/public/small_button_01.sub   (61x21 small)
d:/ymir work/ui/public/middle_button_01.sub  (61x21 middle)
d:/ymir work/ui/public/large_button_01.sub   (90x26 large)
d:/ymir work/ui/public/xlarge_button_01.sub  (120x33 xlarge)
```
Suffixes: `_01.sub` = default, `_02.sub` = over, `_03.sub` = down.

---

### radio_button

Radio button -- stays pressed until another in the group is selected.

- **Class:** `RadioButton` (extends `Button`)
- **Loader:** `LoadElementButton` (same loader as button)
- **Dict properties:** same as `button`

**Key methods:** Same as Button. Typically used with `RadioButtonGroup.Create()`:
```python
radioGroup = ui.RadioButtonGroup.Create([
    (btn1, selectEvent1, unselectEvent1),
    (btn2, selectEvent2, unselectEvent2),
])
```

---

### toggle_button

Button that toggles between up and down states on click.

- **Class:** `ToggleButton` (extends `Button`)
- **Loader:** `LoadElementButton` (same loader as button)
- **Dict properties:** same as `button`

**Key methods:**
- `SetToggleUpEvent(event, *args)` -- callback when toggled up
- `SetToggleDownEvent(event, *args)` -- callback when toggled down

---

### drag_button

Draggable button (movable within a restricted area). **Not available as a uiscript type string** -- only usable programmatically. Used internally by `ScrollBar` and `SliderBar`.

- **Class:** `DragButton` (extends `Button`)

**Key methods:**
- `SetMoveEvent(event)` -- callback on drag movement
- `SetRestrictMovementArea(x, y, width, height)` -- constrain drag area

---

### editline

Single-line text input field.

- **Class:** `EditLine` (extends `TextLine`)
- **Loader:** `LoadElementEditLine`
- **Required key list:** `EDIT_LINE_KEY_LIST` = `("width", "height", "input_limit")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Field width |
| `height` | `int` | yes | Field height |
| `input_limit` | `int` | yes | Maximum character count |
| `secret_flag` | `bool` | no | If true, shows dots instead of text (password mode) |
| `with_codepage` | `bool` | no | Enable codepage support |
| `only_number` | `bool` | no | Only allow numeric input |
| `enable_codepage` | `bool` | no | Set IME flag |
| `enable_ime` | `bool` | no | Set IME flag (alternative name) |
| `limit_width` | `int` | no | Limit rendering width in pixels |
| `multi_line` | `bool` | no | Enable multi-line mode |

Also supports all `text` dict properties (fontsize, fontname, text_horizontal_align, color, etc.) since `LoadElementEditLine` calls `LoadElementText` internally.

**Key methods:**
- `SetMax(max)` -- set character limit
- `SetText(text)` / `GetText()` -- get/set field content
- `SetReturnEvent(event)` / `SAFE_SetReturnEvent(event)` -- callback on Enter key
- `SetEscapeEvent(event)` -- callback on Escape key
- `SetTabEvent(event)` -- callback on Tab key
- `SetFocus()` / `KillFocus()` -- manage input focus
- `Enable()` / `Disable()` -- show/hide cursor
- `SetSecret(value)` -- toggle password mode
- `SetNumberMode()` -- restrict to numeric input
- `SetIMEFlag(flag)` -- enable/disable IME

---

### editline_centered

EditLine variant that auto-centers text horizontally within its width.

- **Class:** `EditLineCentered` (extends `EditLine`)
- **Loader:** `LoadElementEditLine` (same loader as editline)
- **Dict properties:** same as `editline`

**Notes:** Overrides `SetText`, `SetFocus`, and `OnIMEUpdate` to call `AdjustTextPosition()` which centers the text based on its rendered width.

---

### scrollbar

Standard scrollbar with up/down buttons and a draggable middle bar.

- **Class:** `ScrollBar` (extends `Window`)
- **Loader:** `LoadElementScrollBar`
- **Required key list:** `SCROLLBAR_KEY_LIST` = `("size",)`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `size` | `int` | yes | Total height of the scrollbar in pixels |

**Key methods:**
- `SetScrollBarSize(height)` -- set scrollbar height
- `SetScrollEvent(event)` -- callback when scroll position changes
- `SetPos(pos)` -- set position (0.0 to 1.0)
- `GetPos()` -- get current position (0.0 to 1.0)
- `SetMiddleBarSize(pageScale)` -- set thumb size as fraction of track
- `SetScrollStep(step)` -- set step size for up/down buttons (default 0.20)
- `LockScroll()` / `UnlockScroll()` -- prevent/allow scrolling

---

### thin_scrollbar

Thinner visual variant of scrollbar.

- **Class:** `ThinScrollBar` (extends `ScrollBar`)
- **Loader:** `LoadElementScrollBar` (same loader as scrollbar)
- **Dict properties:** same as `scrollbar`

**Notes:** Uses `scrollbar_thin_*` image assets. No bar slot background.

---

### small_thin_scrollbar

Even smaller variant of scrollbar.

- **Class:** `SmallThinScrollBar` (extends `ScrollBar`)
- **Loader:** `LoadElementScrollBar` (same loader as scrollbar)
- **Dict properties:** same as `scrollbar`

**Notes:** Uses `scrollbar_small_thin_*` image assets. No bar slot background.

---

### sliderbar

Horizontal slider control (e.g., volume slider).

- **Class:** `SliderBar` (extends `Window`)
- **Loader:** `LoadElementSliderBar`
- **Required key list:** none (only DEFAULT_KEY_LIST)

No additional dict properties. Size is determined by background image.

**Key methods:**
- `SetSliderPos(pos)` -- set position (0.0 to 1.0)
- `GetSliderPos()` -- get current position
- `SetEvent(event)` -- callback on slider change
- `Enable()` / `Disable()` -- show/hide cursor

**Notes:** Uses `d:/ymir work/ui/game/windows/sliderbar.sub` and `sliderbar_cursor.sub`.

---

## Display Types

### text

Single-line text display.

- **Class:** `TextLine` (extends `Window`)
- **Loader:** `LoadElementText`
- **Required key list:** none (no mandatory keys beyond DEFAULT_KEY_LIST)

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `text` | `str` | no | Text content to display |
| `fontsize` | `str` | no | `"LARGE"` for large font |
| `fontname` | `str` | no | Custom font name |
| `text_horizontal_align` | `str` | no | `"left"`, `"center"`, or `"right"` |
| `text_vertical_align` | `str` | no | `"top"`, `"center"`, or `"bottom"` |
| `all_align` | any | no | **GOTCHA — re-anchors widget at parent CENTER, not parent top-left.** Sets `SetWindowHorizontalAlignCenter()` + `SetWindowVerticalAlignCenter()` (per `LoadElementText` in `root/ui.py`). The widget's `(x, y)` then represents an OFFSET from parent center, not absolute coords from parent top-left. So `{"y": 30, "all_align": "center"}` on a board of height 700 renders the text at engine-y `350 + 30 = 380`, not 30. **Do NOT use `all_align` for headers / body content positioned by absolute y.** Use `horizontal_align` + `text_horizontal_align` only when you want centering without the y re-anchor. |
| `r`, `g`, `b` | `float` | no | Text color (0.0-1.0 each). Applied together |
| `color` | packed color | no | Packed font color (alternative to r/g/b) |
| `outline` | `bool` | no | If true, render text with outline |

**Key methods:**
- `SetText(text)` / `GetText()` -- set/get text content
- `SetFontName(fontName)` -- change font
- `SetFontColor(r, g, b)` -- set color (float 0.0-1.0)
- `SetPackedFontColor(color)` -- set packed color (e.g. `0xFFFFFFFF`)
- `SetHorizontalAlignLeft()` / `SetHorizontalAlignCenter()` / `SetHorizontalAlignRight()`
- `SetVerticalAlignTop()` / `SetVerticalAlignCenter()` / `SetVerticalAlignBottom()`
- `SetOutline(value=True)` -- enable outline rendering
- `GetTextSize()` -- returns `(width, height)` of rendered text
- `SetMax(max)` -- max characters
- `SetLimitWidth(width)` -- limit rendering width
- `SetMultiLine()` -- enable multi-line mode

**Notes:** Default color is `(0.8549, 0.8549, 0.8549)` (light gray). Default font is `localeInfo.UI_DEF_FONT`.

---

### numberline

Numeric display using image-based digits. **Not available as a uiscript type string** -- only usable programmatically.

- **Class:** `NumberLine` (extends `Window`)

**Key methods:**
- `SetPath(path)` -- set path to digit images
- `SetNumber(number)` -- set the number to display
- `SetHorizontalAlignCenter()` / `SetHorizontalAlignRight()`

---

### image

Static image display.

- **Class:** `ImageBox` (extends `Window`)
- **Loader:** `LoadElementImage`
- **Required key list:** `IMAGE_KEY_LIST` = `("image",)`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `image` | `str` | yes | Image file path |

**Key methods:**
- `LoadImage(imageName)` -- load/change image
- `SetScale(xScale, yScale)` -- scale image (stub in some builds)
- `SetRenderingRect(left, top, right, bottom)` -- rendering rect (stub in some builds)
- `SetAlpha(alpha)` -- set transparency (0.0-1.0)
- `GetWidth()` / `GetHeight()` -- image dimensions
- `SetEvent(func, *args)` -- event handler (supports `"mouse_click"`, `"mouse_over_in"`, `"mouse_over_out"`)
- `SAFE_SetStringEvent(event, func, *args)` / `SetStringEvent(event, func, *args)` -- named event handlers

**Notes:** Size is auto-determined from the loaded image.

---

### expanded_image

Image with transform support (scaling, rotation, rendering rect, rendering mode).

- **Class:** `ExpandedImageBox` (extends `ImageBox`)
- **Loader:** `LoadElementExpandedImage`
- **Required key list:** `EXPANDED_IMAGE_KEY_LIST` = `("image",)`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `image` | `str` | yes | Image file path |
| `x_origin` | `float` | no | X origin for rotation (used with `y_origin`) |
| `y_origin` | `float` | no | Y origin for rotation |
| `x_scale` | `float` | no | X scale factor (used with `y_scale`) |
| `y_scale` | `float` | no | Y scale factor |
| `rect` | `list[4]` | no | Rendering rect `[left, top, right, bottom]` |
| `mode` | `str` | no | `"MODULATE"` for modulate rendering mode |

**Key methods:**
- `LoadImage(imageName)` -- load image
- `SetScale(xScale, yScale)` -- set scale
- `SetOrigin(x, y)` -- set rotation origin
- `SetRotation(rotation)` -- set rotation angle
- `SetRenderingRect(left, top, right, bottom)` -- clip/tile rendering
- `SetRenderingMode(mode)` -- `wndMgr.RENDERING_MODE_MODULATE`
- `SetPercentage(curValue, maxValue)` -- convenience for horizontal fill bars

**Notes:** `SetRenderingRect` values represent expansion beyond the base image:
- `0.0` = show full image dimension
- `-1.0` = show nothing in that direction
- `1.0` = tile/extend by 100% in that direction

Used extensively for progress bars, gauge fills, and repeating patterns.

---

### ani_image

Animated image that cycles through a sequence of frames.

- **Class:** `AniImageBox` (extends `Window`)
- **Loader:** `LoadElementAniImage`
- **Required key list:** `ANI_IMAGE_KEY_LIST` = `("images",)`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `images` | `list[str]` | yes | List of image paths for animation frames |
| `delay` | `int` | no | Delay between frames (in ticks) |
| `width` | `int` | no | Override width (used with `height`) |
| `height` | `int` | no | Override height |

**Key methods:**
- `AppendImage(filename)` -- add a frame
- `SetDelay(delay)` -- set animation delay
- `SetPercentage(curValue, maxValue)` -- horizontal fill (via rendering rect)

**Notes:** Calls `OnEndFrame()` when animation completes a cycle (override in subclass).

---

### mark

Guild mark display.

- **Class:** `MarkBox` (extends `Window`)
- **Loader:** `LoadElementMark`
- **Required key list:** none

No additional dict properties.

**Key methods:**
- `Load()` -- initialize
- `SetIndex(guildID)` -- set guild mark by guild ID
- `SetScale(scale)` -- set scale
- `SetAlpha(alpha)` -- set transparency

---

## Slot Types

### slot

Manual slot layout. Each slot is individually positioned.

- **Class:** `SlotWindow` (extends `Window`)
- **Loader:** `LoadElementSlot`
- **Required key list:** `SLOT_KEY_LIST` = `("width", "height", "slot")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Window width |
| `height` | `int` | yes | Window height |
| `slot` | `list[dict]` | yes | List of slot definition dicts |
| `image` | `str` | no | Base image for all slots |
| `image_r` | `float` | no | Image tint red (0.0-1.0, default 1.0) |
| `image_g` | `float` | no | Image tint green |
| `image_b` | `float` | no | Image tint blue |
| `image_a` | `float` | no | Image tint alpha |

Each slot dict in the `slot` list:

| Property | Type | Required | Description |
|---|---|---|---|
| `index` | `int` | yes | Slot index |
| `x` | `int` | yes | X position within the slot window |
| `y` | `int` | yes | Y position within the slot window |
| `width` | `int` | yes | Slot width (in grid units, typically 32px) |
| `height` | `int` | yes | Slot height |

**Key methods:**
- `SetItemSlot(slotNumber, itemIndex, itemCount, diffuseColor)` -- set item in slot
- `SetSkillSlot(slotNumber, skillIndex, skillLevel)` -- set skill in slot
- `ClearSlot(slotNumber)` / `ClearAllSlot()`
- `SetSelectEmptySlotEvent(event)` -- left-click empty slot
- `SetSelectItemSlotEvent(event)` -- left-click occupied slot
- `SetUnselectEmptySlotEvent(event)` -- right-click empty slot
- `SetUnselectItemSlotEvent(event)` -- right-click occupied slot
- `SetUseSlotEvent(event)` -- double-click slot
- `SetOverInItemEvent(event)` / `SetOverOutItemEvent(event)` -- hover events
- `SetSlotCoolTime(slotIndex, coolTime, elapsedTime)` -- cooldown overlay
- `ActivateSlot(slotNumber, r, g, b, a)` / `DeactivateSlot(slotNumber)`
- `EnableSlot(slotIndex)` / `DisableSlot(slotIndex)`
- `RefreshSlot()` -- refresh rendering

**Notes:** Does NOT call `LoadDefaultData` -- position is set directly. Does not auto-show via the common path.

---

### grid_table

Auto-arranged grid of slots. Slots are laid out in rows and columns automatically.

- **Class:** `GridSlotWindow` (extends `SlotWindow`)
- **Loader:** `LoadElementGridTable`
- **Required key list:** `GRID_TABLE_KEY_LIST` = `("start_index", "x_count", "y_count", "x_step", "y_step")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `start_index` | `int` | yes | Starting slot index |
| `x_count` | `int` | yes | Number of columns |
| `y_count` | `int` | yes | Number of rows |
| `x_step` | `int` | yes | Horizontal spacing between slots (pixels) |
| `y_step` | `int` | yes | Vertical spacing between slots (pixels) |
| `x_blank` | `int` | no | Extra horizontal gap (default 0) |
| `y_blank` | `int` | no | Extra vertical gap (default 0) |
| `image` | `str` | no | Base slot image |
| `image_r` | `float` | no | Image tint red |
| `image_g` | `float` | no | Image tint green |
| `image_b` | `float` | no | Image tint blue |
| `image_a` | `float` | no | Image tint alpha |
| `style` | `str` | no | `"select"` for selection highlighting |

**Key methods:** All `SlotWindow` methods plus:
- `ArrangeSlot(startIndex, xCount, yCount, xSize, ySize, xBlank, yBlank)` -- rearrange grid
- `GetStartIndex()` -- get first slot index

**Notes:** Typical `x_step`/`y_step` is 32 for standard item slots.

---

## Decorative / Primitive Types

### box

Outlined rectangle (border only, no fill).

- **Class:** `Box` (extends `Window`)
- **Loader:** `LoadElementBox`
- **Required key list:** `BOX_KEY_LIST` = `("width", "height")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width |
| `height` | `int` | yes | Height |
| `color` | packed color | no | Outline color |

**Key methods:**
- `SetColor(color)` -- set outline color (packed ARGB, e.g. `grp.GenerateColor(r,g,b,a)`)

---

### bar

Filled rectangle.

- **Class:** `Bar` (extends `Window`)
- **Loader:** `LoadElementBar`
- **Required key list:** `BAR_KEY_LIST` = `("width", "height")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width |
| `height` | `int` | yes | Height |
| `color` | packed color | no | Fill color |

**Key methods:**
- `SetColor(color)` -- set fill color

---

### line

Single-pixel line.

- **Class:** `Line` (extends `Window`)
- **Loader:** `LoadElementLine`
- **Required key list:** `LINE_KEY_LIST` = `("width", "height")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width (use 0 for vertical, >0 for horizontal) |
| `height` | `int` | yes | Height (use 0 for horizontal, >0 for vertical) |
| `color` | packed color | no | Line color |

**Key methods:**
- `SetColor(color)` -- set line color

---

### slotbar

3D-styled input field background (sunken bar). Often used as background behind editlines.

- **Class:** `SlotBar` (extends `Window`)
- **Loader:** `LoadElementSlotBar`
- **Required key list:** `SLOTBAR_KEY_LIST` = `("width", "height")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width |
| `height` | `int` | yes | Height |

**Notes:** Internally registers as `Bar3D` via `wndMgr.RegisterBar3D`. Provides a sunken/inset visual effect.

---

## Gauge / Progress Types

### gauge

Horizontal progress bar with colored fill.

- **Class:** `Gauge` (extends `Window`)
- **Loader:** `LoadElementGauge`
- **Required key list:** `GAUGE_KEY_LIST` = `("width", "color")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width in pixels (min 48) |
| `color` | `str` | yes | Gauge color name: used to load `gauge_<color>.tga` |

Valid color values (based on pattern images): `"red"`, `"blue"`, `"green"`, `"yellow"`, etc.

**Key methods:**
- `MakeGauge(width, color)` -- create gauge with specified width and color
- `SetPercentage(curValue, maxValue)` -- set fill percentage

---

## Bar / Title Types

### titlebar

Horizontal title bar with close button. Usually placed at the top of a `board`.

- **Class:** `TitleBar` (extends `Window`)
- **Loader:** `LoadElementTitleBar`
- **Required key list:** `TITLE_BAR_KEY_LIST` = `("width",)`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width in pixels (min 64) |
| `color` | `str` | no | Color theme (default `"red"`) |

**Key methods:**
- `MakeTitleBar(width, color)` -- create title bar
- `SetWidth(width)` -- resize
- `SetCloseEvent(event)` -- set close button callback
- `CloseButtonHide()` -- hide the close button

**Notes:** Typically added as a child of `board` at position (6, 7) or similar. Width should be `board_width - 13` or similar.

---

### horizontalbar

Decorative horizontal separator bar.

- **Class:** `HorizontalBar` (extends `Window`)
- **Loader:** `LoadElementHorizontalBar`
- **Required key list:** `HORIZONTAL_BAR_KEY_LIST` = `("width",)`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width in pixels (min 96) |

**Key methods:**
- `Create(width)` -- initialize the bar
- `SetWidth(width)` -- resize

**Notes:** Height is fixed at 17px (`BLOCK_HEIGHT`). Uses `horizontalbar_left/center/right.tga` patterns.

---

## List Types

### listbox

Simple text list with selection highlight.

- **Class:** `ListBox` (extends `Window`)
- **Loader:** `LoadElementListBox`
- **Required key list:** `LIST_BOX_KEY_LIST` = `("width", "height")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width |
| `height` | `int` | yes | Height |
| `item_align` | `bool` | no | If provided, sets center alignment via `SetTextCenterAlign` |

**Key methods:**
- `InsertItem(number, text)` -- add item with key and display text
- `ClearItem()` -- remove all items
- `SelectItem(line)` -- select by line index
- `GetSelectedItem()` -- get selected item key
- `SetEvent(event)` -- selection callback, receives `(key, text)`
- `SetBasePos(pos)` -- set scroll offset
- `GetItemCount()` / `GetViewItemCount()`
- `ArrangeItem()` -- resize to fit all items
- `ChangeItem(number, text)` -- update existing item text

---

### listbox2

Multi-column variant of listbox. Items wrap into columns.

- **Class:** `ListBox2` (extends `ListBox`)
- **Loader:** `LoadElementListBox2`
- **Required key list:** `LIST_BOX_KEY_LIST` = `("width", "height")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width |
| `height` | `int` | yes | Height |
| `row_count` | `int` | no | Number of rows per column (default 10) |
| `item_align` | `bool` | no | Center alignment flag |

**Key methods:** Same as `listbox` plus:
- `SetRowCount(rowCount)` -- set rows per column

---

### listboxex

Extended listbox that holds arbitrary widget items (not just text).

- **Class:** `ListBoxEx` (extends `Window`)
- **Loader:** `LoadElementListBoxEx`
- **Required key list:** `LIST_BOX_KEY_LIST` = `("width", "height")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `width` | `int` | yes | Width |
| `height` | `int` | yes | Height |
| `itemsize_x` | `int` | no | Item width (used with `itemsize_y`) |
| `itemsize_y` | `int` | no | Item height |
| `itemstep` | `int` | no | Vertical step between items (default 20) |
| `viewcount` | `int` | no | Number of visible items (default 10) |

**Key methods:**
- `AppendItem(newItem)` -- add a `ListBoxEx.Item` subclass instance
- `RemoveItem(delItem)` / `RemoveAllItems()`
- `SetSelectEvent(event)` -- selection callback
- `SetScrollBar(scrollBar)` -- attach a scrollbar
- `SetItemStep(step)` -- set vertical spacing
- `SetItemSize(width, height)` -- set item dimensions
- `SetViewItemCount(count)` -- set visible item count
- `SelectIndex(index)` -- select by index
- `GetSelectedItem()` -- get selected item object

**Clip mask support:** When `app.__BL_CLIP_MASK__` is enabled, `ListBoxEx` uses pixel-based smooth scrolling and automatically calls `SetClippingMaskWindow(self)` on each appended item. See `skills/m2ui/reference/patterns.md` Section 6 for details.

**Notes:** Items must extend `ListBoxEx.Item` (which extends `Window`). Each item is a full widget that can contain its own children.

---

### candidate_list

Horizontal or vertical list for IME candidate selection.

- **Class:** `CandidateListBox` (extends `ListBoxEx`)
- **Loader:** `LoadElementCandidateList`
- **Required key list:** `CANDIDATE_LIST_KEY_LIST` = `("item_step", "item_xsize", "item_ysize")`

| Dict Property | Type | Required | Description |
|---|---|---|---|
| `item_step` | `int` | yes | Step between items |
| `item_xsize` | `int` | yes | Item width |
| `item_ysize` | `int` | yes | Item height |

**Notes:** Specialized for IME input. Supports `HORIZONTAL_MODE` and `VERTICAL_MODE`. Does not call `LoadDefaultData` -- position is set directly.

---

## Types Only Available Programmatically

These classes exist in `ui.py` but have no type string in the `PythonScriptLoader` dispatcher.
They must be created in Python code, not in uiscript dicts.

| Class | Parent | Description |
|---|---|---|
| `DragButton` | `Button` | Draggable button (used by scrollbars/sliders) |
| `NumberLine` | `Window` | Image-based number display |
| `ComboBox` | `Window` | Dropdown select box (see caveat below) |
| `Bar3D` | `Window` | 3D-style bar (same as SlotBar internally) |
| `RadioButtonGroup` | `NoWindow` | Helper for radio button grouping |

### ComboBox dropdown caveat (load-time consideration)

`ui.ComboBox.__ArrangeListBox()` (in `root/ui.py`) ALWAYS opens the list panel at relative `(0, height + 5)` of the combo, on the `TOP_MOST` layer — i.e., directly DOWNWARD from the combo. There is no engine flag to flip it upward. The dropdown will paint over whatever sits in the next ~`item_count * line_height` pixels.

Implications when designing a dense vertical form:

- For two adjacent `ComboBox` rows spaced 25 px apart, opening the upper one's dropdown covers the lower one entirely.
- Do not place a ComboBox immediately above clickable widgets the user expects to interact with while the list is open.

Mitigation patterns (pick one when generating a form with multiple `ComboBox`):

- **Reserve clearance.** Space rows so `next_row_y - this_combo_y >= max_item_count * 17 + 10`. For a list of 5 items this is ~95 px. Practical for forms with ≤ 3 ComboBoxes; impractical for dense settings panels.
- **Use a popup `ListBox` triggered by a button.** A normal `button` opens a transient `ui.ListBox`-based picker positioned wherever you want (e.g., to the right, anchored upward). Replaces ComboBox entirely.
- **Subclass `ui.ComboBox`.** Override `__ArrangeListBox` to flip the list upward when `combo.GetGlobalY() + height + listHeight > parent.GetHeight()`. Requires touching client code; one-time cost for many forms.
- **Replace with `radio_button` group** when there are ≤ 4 options. Trades vertical space for visibility.

For symptom-driven diagnosis of "dropdown covers next row", see `failure-atlas.md` entry 14.

---

## Image Path Conventions

All image paths use the `d:/ymir work/` prefix. Common directories:

| Path | Content |
|---|---|
| `d:/ymir work/ui/public/` | Shared UI elements (buttons, scrollbars, close buttons) |
| `d:/ymir work/ui/pattern/` | Repeating patterns (board corners, lines, gauges) |
| `d:/ymir work/ui/game/windows/` | Game window backgrounds and elements |
| `d:/ymir work/ui/game/` | Game-specific UI assets |

### Common button image sets

```
# Small button (61x21)
d:/ymir work/ui/public/small_button_01.sub
d:/ymir work/ui/public/small_button_02.sub
d:/ymir work/ui/public/small_button_03.sub

# Middle button (61x21)
d:/ymir work/ui/public/middle_button_01.sub
d:/ymir work/ui/public/middle_button_02.sub
d:/ymir work/ui/public/middle_button_03.sub

# Large button (90x26)
d:/ymir work/ui/public/large_button_01.sub
d:/ymir work/ui/public/large_button_02.sub
d:/ymir work/ui/public/large_button_03.sub

# XLarge button (120x33)
d:/ymir work/ui/public/xlarge_button_01.sub
d:/ymir work/ui/public/xlarge_button_02.sub
d:/ymir work/ui/public/xlarge_button_03.sub

# Close button
d:/ymir work/ui/public/close_button_01.sub
d:/ymir work/ui/public/close_button_02.sub
d:/ymir work/ui/public/close_button_03.sub

# Scrollbar
d:/ymir work/ui/public/scrollbar_up_button_01.sub
d:/ymir work/ui/public/scrollbar_down_button_01.sub
```

### Pattern images (used by Board, ThinBoard, etc.)

```
d:/ymir work/ui/pattern/Board_Corner_LeftTop.tga
d:/ymir work/ui/pattern/Board_Line_Left.tga
d:/ymir work/ui/pattern/Board_Base.tga
d:/ymir work/ui/pattern/ThinBoard_Corner_LeftTop.tga
d:/ymir work/ui/pattern/ThinBoard_Line_Left.tga
d:/ymir work/ui/pattern/titlebar_left.tga
d:/ymir work/ui/pattern/horizontalbar_left.tga
d:/ymir work/ui/pattern/gauge_slot_left.tga
d:/ymir work/ui/pattern/gauge_red.tga
d:/ymir work/ui/pattern/gauge_blue.tga
d:/ymir work/ui/pattern/gauge_green.tga
```

---

## Runtime factories (ui.Make*)

These helpers in `root/ui.py` construct fully-configured widgets in one call — alternative to declaring the widget in a uiscript dict. Use them when a window builds children programmatically (code-only style) or needs to add widgets at runtime in response to data. Both helpers call `Show()` internally — no initial `Show()` is needed. Calling `Hide()` / `Show()` later for state toggles is normal and expected.

**Lifecycle / reference-keeping.** The factory's `SetParent(parent)` only registers the child at the engine level (via `wndMgr.SetParent`); it does NOT add the widget to any Python-side container. Without keeping a reference, the widget may be garbage-collected. Either store the return value on `self` (e.g., `self.icon = ui.MakeImageBox(...)`) OR append it to a Python-managed list / `parent.Children` if the parent uses one. `parent.InsertChild(name, child)` is only necessary when later code needs to look the widget up by name via `parent.GetChild(name)`.

### ui.MakeImageBox(parent, name, x, y)

Constructs a fully-configured `ImageBox` and returns it.

- **`parent`** — owning window. Sets parent only; the helper does NOT call `parent.InsertChild(...)`. If name lookup via `parent.GetChild(name)` is needed later, register manually.
- **`name`** — image asset path (string). Use the lowercase forward-slash convention (`d:/ymir work/ui/...`); supported formats `.tga` / `.dds` / `.sub`.
- **`x`**, **`y`** — absolute position relative to parent.

**Returns:** `ImageBox` instance, already shown.

**Example:**

```python
self.checkImage = ui.MakeImageBox(self, "d:/ymir work/ui/public/check_image.sub", 8, 8)
```

Equivalent to declaring an `image` widget in a uiscript dict with `image` / `x` / `y` keys. Pick whichever style matches the surrounding window — code-only windows use the factory; script-backed windows declare in the dict.

**Source:** `root/ui.py` `def MakeImageBox(parent, name, x, y)`.

### ui.MakeButton(parent, x, y, tooltipText, path, up, over, down)

Constructs a fully-configured `Button` and returns it.

- **`parent`** — owning window. Sets parent only; no `InsertChild`.
- **`x`**, **`y`** — absolute position relative to parent.
- **`tooltipText`** — mandatory tooltip string (passed to `SetToolTipText`). Pass `""` to skip the tooltip visually.
- **`path`** — directory prefix. **MUST end with `/`** — the helper concatenates `path + up` etc. with no separator. Forgetting the trailing slash produces an asset path like `"...publicbtn_01.tga"` and an asset-not-found / red-X result (see `failure-atlas.md` entry 6).
- **`up`** / **`over`** / **`down`** — filenames for the three button-state textures. Concatenated to `path` internally to form the full asset paths.

**Returns:** `Button` instance, already shown.

**Important — no event argument.** This factory does NOT take an event. The caller MUST wire the click event separately, otherwise the button is decorative and silently does nothing on click (see `failure-atlas.md` entry 2 cause #3). Always follow the factory call with `SetEvent`:

**Example (correct):**

```python
self.acceptBtn = ui.MakeButton(
    self, 8, 8, localeInfo.UI_ACCEPT,
    "d:/ymir work/ui/public/", "middle_button_01.sub", "middle_button_02.sub", "middle_button_03.sub",
)
self.acceptBtn.SetEvent(ui.__mem_func__(self.OnAccept))
```

**Example (wrong — missing trailing slash):**

```python
ui.MakeButton(self, 0, 0, "", "d:/ymir work/ui/public", "btn_up.tga", ...)
# resolves to "d:/ymir work/ui/publicbtn_up.tga" — asset not found
```

**Limitations and post-creation configuration.** The factory does not accept arguments for disabled-state image, button text, or explicit size. The returned `Button` instance still supports them — call `btn.SetDisableVisual(path)`, `btn.SetText(text)`, or `btn.SetSize(w, h)` after the factory returns if needed. For all-at-once declaration, use a `button` widget in a uiscript dict instead.

**Source:** `root/ui.py` `def MakeButton(parent, x, y, tooltipText, path, up, over, down)`.

## Quick Reference: Type String to Class Mapping

| Type String | Python Class | Loader Method | Category |
|---|---|---|---|
| `window` | `ScriptWindow` | `LoadElementWindow` | container |
| `board` | `Board` | `LoadElementBoard` | container |
| `board_with_titlebar` | `BoardWithTitleBar` | `LoadElementBoardWithTitleBar` | container |
| `thinboard` | `ThinBoard` | `LoadElementThinBoard` | container |
| `thinboard_gold` | `ThinBoardGold` | `LoadElementThinBoard` | container |
| `thinboard_circle` | `ThinBoardCircle` | `LoadElementThinBoard` | container |
| `button` | `Button` | `LoadElementButton` | input |
| `radio_button` | `RadioButton` | `LoadElementButton` | input |
| `toggle_button` | `ToggleButton` | `LoadElementButton` | input |
| `editline` | `EditLine` | `LoadElementEditLine` | input |
| `editline_centered` | `EditLineCentered` | `LoadElementEditLine` | input |
| `scrollbar` | `ScrollBar` | `LoadElementScrollBar` | input |
| `thin_scrollbar` | `ThinScrollBar` | `LoadElementScrollBar` | input |
| `small_thin_scrollbar` | `SmallThinScrollBar` | `LoadElementScrollBar` | input |
| `sliderbar` | `SliderBar` | `LoadElementSliderBar` | input |
| `text` | `TextLine` | `LoadElementText` | display |
| `image` | `ImageBox` | `LoadElementImage` | display |
| `expanded_image` | `ExpandedImageBox` | `LoadElementExpandedImage` | display |
| `ani_image` | `AniImageBox` | `LoadElementAniImage` | display |
| `mark` | `MarkBox` | `LoadElementMark` | display |
| `slot` | `SlotWindow` | `LoadElementSlot` | slot |
| `grid_table` | `GridSlotWindow` | `LoadElementGridTable` | slot |
| `candidate_list` | `CandidateListBox` | `LoadElementCandidateList` | slot |
| `box` | `Box` | `LoadElementBox` | primitive |
| `bar` | `Bar` | `LoadElementBar` | primitive |
| `line` | `Line` | `LoadElementLine` | primitive |
| `slotbar` | `SlotBar` | `LoadElementSlotBar` | primitive |
| `gauge` | `Gauge` | `LoadElementGauge` | gauge |
| `titlebar` | `TitleBar` | `LoadElementTitleBar` | bar |
| `horizontalbar` | `HorizontalBar` | `LoadElementHorizontalBar` | bar |
| `listbox` | `ListBox` | `LoadElementListBox` | list |
| `listbox2` | `ListBox2` | `LoadElementListBox2` | list |
| `listboxex` | `ListBoxEx` | `LoadElementListBoxEx` | list |
