# Metin2 UI Mental Model — Read This Before Generating

Most LLMs trained on web/React/Flutter will assume those mental models apply to Metin2 UI. They don't. This file deprograms those assumptions and replaces them with the ymir UI engine's actual concepts.

**Read this before generating any new window.** Three minutes here saves rework later.

## 1. Layout model

There is no flex, grid, stack, or any flow-based auto-layout. Every widget gets absolute `(x, y)` coordinates measured from its parent's origin (parent's top-left = `(0, 0)`). No browser-style box model — no margin, no padding, no border-collapse. If you want spacing, you add it manually as offset.

- ymir DOES have limited per-widget alignment flags: `"horizontal_align"` (`"left"`/`"center"`/`"right"`), `"vertical_align"` (`"top"`/`"center"`/`"bottom"`), `"all_align"` (combo), `"text_horizontal_align"` for text widgets. These align the widget within its PARENT's rect — they're not flex/grid layout.
- "Centering a child" = either `"horizontal_align": "center"` in uiscript, OR compute manually: `child_x = (parent_w - child_w) // 2`.
- "Right-aligned button" = either `"horizontal_align": "right"` in uiscript, OR `btn_x = parent_w - btn_w - margin_px`.
- Window does not auto-resize to fit children. You set `SetSize(w, h)` explicitly.
- No responsive design. Resolution adaptation = manually re-centering on `OnUpdateScreenSize` if needed.

**Rule of thumb:** parent does NOT lay out children in flex/grid. Children either (a) carry an `_align` flag for simple within-parent positioning, or (b) get explicit absolute coordinates. No flow.

## 2. Component model

There are no reusable components in the React sense. Each window is its own root class extending `ui.ScriptWindow` (or `ui.BoardWithTitleBar`, `ui.Board`, etc.).

- "Composition" = `child.SetParent(parent)` (preferred) or `parent.InsertChild(name, child)` for named registration. Z-order is determined by `SetParent` call order — later calls draw on top.
- "Props" = constructor args + setter methods (`window.SetItemList(items)`).
- There is no `render()`. UI is built once in `__LoadDialog` (code-only style) or via `LoadScriptFile("uiscript/yourwindow.py")` (script-backed style). Not on every state change.
- Two valid styles: **script-backed** (uiscript dict + root class) for static layouts, **code-only** (programmatic root class) for dynamic content. See `skills/m2ui/reference/patterns.md` for both.

**Rule of thumb:** if you want a "reusable card component," it's a class that constructs widgets in its `__init__`, not a JSX function.

## 3. State model

There is no reactive state. State lives on `self` as instance vars. Updates require explicit widget setter calls.

- `self.username` changing does NOT update the displayed text. You must call `self.usernameLabel.SetText(self.username)` after the change.
- "Re-rendering a list" = clear children + rebuild loop, OR pool widgets and reassign data via setters.
- No `useState`, no `useEffect`, no signals, no observers. The pattern is: change instance var → call setter → widget reflects new value.
- For per-frame work (rare!) override `OnUpdate(self)`. It runs every frame the window is shown. Cheap operations only — no network calls, no allocations.

**Rule of thumb:** any "reactive UI" idiom = manual setter call in your code.

## 4. Event model

There is no event bubbling, no event delegation, no synthetic events. Each interactive widget gets one callback per event type.

- `button.SetEvent(callback)` registers ONE callback. Calling it again replaces the previous one.
- Mouse picking is geometric: hit-test respects parent rect, child rect, `not_pick` flag, and z-order (later children win).
- Decorative elements (backgrounds, lines, separators) MUST set `"style": ("not_pick",)` in uiscript or the engine will swallow clicks meant for siblings.
- Callbacks that reference `self` MUST be wrapped per `skills/m2ui/reference/event-binding.md` matrix. Bare bound methods leak.

**Rule of thumb:** if a click "isn't reaching" your button, the cause is almost always (a) parent bounds don't contain the button, (b) a decorative sibling missing `not_pick`, or (c) wrong z-order.

## 5. Lifecycle model

There is no automatic mount/unmount. Lifecycle is manual:

- `__init__` → window object exists in memory but invisible
- `Open()` → typically calls `Show()` on the root window + sets up timers
- `Close()` → typically calls `Hide()` on the root window + tears down timers, hides tooltips, kills focus
- `Destroy()` → MUST be decorated with `@ui.WindowDestroy`; calls `Initialize()` to reset all instance vars; calls `ClearDictionary()` if script-backed
- `__del__` → calls `ui.ScriptWindow.__del__(self)` for proper Python cleanup

`OnUpdate` runs every frame the window is shown. It is NOT a lifecycle hook — it's a per-frame tick. Use sparingly.

**Rule of thumb:** Open/Close/Destroy are explicit; nothing happens automatically.

## 6. Asset model

No bundler, no module imports for assets, no asset hashing. Assets are referenced directly by disk path (forward slashes, lowercase).

- Image: `"image": "d:/ymir work/ui/game/cube/cube_button_01.tga"` in uiscript, or `widget.LoadImage("d:/...")` in code.
- Asset formats: `.tga` / `.dds` (textures), `.sub` (font sub), `.ttf` (font).
- 9-slice borders: use the `expanded_image` widget with 9 corner/edge tiles (top-left, top, top-right, left, center, right, bottom-left, bottom, bottom-right). See anchor `04-9slice-panel.md`.
- Asset paths must exist on disk under `D:\ymir work\ui\` before referencing. If a new asset is needed, emit `# TBD ASSET: <path> — needs creation` instead of inventing a path.

**Rule of thumb:** assets are file paths, not modules. Verify with Glob before referencing.

## 7. Translation table

When you would write... | use this instead
---|---
`<div className="card">` | `Window` w/ `expanded_image` background widget
`<button onClick={fn}>` | `btn = ui.Button(); btn.SetEvent(ui.__mem_func__(self.fn))`
`<img src="...">` | `image` widget w/ `image` key = disk path
`flex` row | manual x-offset accumulator
`useState(x)` | `self.x = x` + setter that updates the widget
`useEffect(() => fn(), [])` | call `fn()` once in `Open()` or `__LoadWindow`
`useEffect(() => fn(), [dep])` | call `fn()` from the setter that mutates `dep`
`onMount` | `Open()` (called when shown)
`onUnmount` | `Destroy()` (called when window torn down)
`display: none` | `widget.Hide()`
`display: block` | `widget.Show()`
`z-index: 99` | SetParent call order; or `SetTop()` w/ `"float"` flag
`opacity: 0.5` | `widget.SetAlpha(0.5)` (where supported)
controlled `<input>` | `EditLine` w/ `SetText` / `GetText` + `OnIMEUpdate` callback for live changes
`Modal` w/ overlay | `Board` window + `SetCenterPosition()` + `Show()` + manual escape handling

## What NOT to do

- Do not invent asset paths. Verify with Glob against `D:\ymir work\ui\`.
- Do not invent `net.X`, `player.X`, `item.X`, `chr.X`, `app.X`, `wndMgr.X`, `chat.X`, `quest.X` calls. Verify against `skills/m2ui/reference/bindings.md`.
- Do not use `lambda: self.X()` — leaks. See `skills/m2ui/reference/event-binding.md`.
- Do not assume widgets resize on parent resize. Compute child positions explicitly.
- Do not put network calls in `OnUpdate`. It runs every frame.
- Do not skip `@ui.WindowDestroy`. Children leak without it.

## Cross-references

- Callback wrapping → `skills/m2ui/reference/event-binding.md`
- Boilerplate templates → `skills/m2ui/reference/patterns.md`
- All 34 widget types + properties → `skills/m2ui/reference/widgets.md`
- Locale string format → `skills/m2ui/reference/locale.md`
- C++ Python API catalog → `skills/m2ui/reference/bindings.md`
- Canonical few-shot anchors → `skills/m2ui/reference/anchors/README.md`
