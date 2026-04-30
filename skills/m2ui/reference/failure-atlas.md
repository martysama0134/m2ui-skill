# Failure Atlas — Symptom-First Lookup

When a user reports "X looks broken" instead of "fix this code", start here. Each entry maps a visible symptom to ranked root causes (most frequent first) plus a fix snippet. Use this BEFORE loading anchors — diagnosis precedes generation.

## How to use this atlas

- Scan the symptom index below; pick the entry whose phrasing most closely matches the user's report.
- Walk the ranked root-cause checklist top-down — the first match is usually correct (the order reflects empirical frequency, not alphabetical).
- For each candidate cause, apply the **Quick check** before applying the **Fix**. Skipping the check leads to fixing the wrong layer and re-introducing the symptom elsewhere.

## Symptom index

1. [Window doesn't appear](#1-window-doesnt-appear)
2. [Click goes through / nothing happens](#2-click-goes-through--nothing-happens)
3. [Memory leak / crashes after closing N times](#3-memory-leak--crashes-after-closing-n-times)
4. [OnPressEscapeKey crashes during child iteration](#4-onpressescapekey-crashes-during-child-iteration)
5. [Text/locale shows as raw key string](#5-textlocale-shows-as-raw-key-string)
6. [Image shows as red X / pink box](#6-image-shows-as-red-x--pink-box)
7. [Scrollbar doesn't scroll / scrolls wrong range](#7-scrollbar-doesnt-scroll--scrolls-wrong-range)
8. [Layout breaks at certain resolution](#8-layout-breaks-at-certain-resolution)
9. [Tooltip stuck after window close](#9-tooltip-stuck-after-window-close)
10. [EditLine input goes nowhere after close](#10-editline-input-goes-nowhere-after-close)
11. [Feature flag check fails silently (gated window doesn't appear)](#11-feature-flag-check-fails-silently-gated-window-doesnt-appear)
12. [Window opens then immediately closes](#12-window-opens-then-immediately-closes)
13. [Header / text appears at wrong vertical position (offset from intended)](#13-header--text-appears-at-wrong-vertical-position-offset-from-intended)
14. [ComboBox dropdown overlaps the rows below it](#14-combobox-dropdown-overlaps-the-rows-below-it)
30. [Slot DisableSlot / state lost after setting items](#30-slot-disableslot--state-lost-after-setting-items)
31. [Server command handler receives only first token / TypeError on command](#31-server-command-handler-receives-only-first-token--typeerror-on-command)
32. [Window open causes infinite packet loop / client freezes on open](#32-window-open-causes-infinite-packet-loop--client-freezes-on-open)
33. [Tooltip handler exists but tooltip never shows on hover](#33-tooltip-handler-exists-but-tooltip-never-shows-on-hover)
34. [Replaced/redirected widgets don't update (show stale values)](#34-replacedredirected-widgets-dont-update-show-stale-values)
35. [Duplicate widgets visible after adding define gate](#35-duplicate-widgets-visible-after-adding-define-gate)

---

## 1. "Window doesn't appear"

**Likely root causes (ranked by frequency):**

1. **`Show()` never called** — Construction + `LoadScriptFile` does not display the window. Fix: call `self.Show()` from `Open()` (or wherever the window becomes visible).
2. **Parent / ancestor is hidden** — Calling `Show()` on a child whose parent is `Hide()`'d does nothing visible. Fix: inspect the uiscript hierarchy or the parent refs stored at `__LoadWindow` time (e.g., `self.board`, `self.descWindow`); call `IsShow()` on each ancestor directly via those stored refs.
3. **`x`/`y` off-screen** — `SetPosition(x, y)` with negative or > screen-size coords places the window outside the viewport. Fix: call `SetCenterPosition()` or clamp via `app.GetScreenWidth()` / `app.GetScreenHeight()`.
4. **Z-buried under another window** — A `"float"`-styled sibling drawn later covers it. Fix: ensure the window has `"style": ("float",)` (or includes `"float"` in its style tuple) in uiscript — `SetTop()` only re-orders within the float layer; non-float windows can't be raised above float ones.
5. **`LoadScriptFile` path wrong** — Mixed-case path on a Linux server fails silently; the window has no children. Fix: lowercase the path (`uiscript/foo.py`, not `UIScript/Foo.py`); verify file exists.

**Quick check:** Add `dbg.TraceError("opened: " + str(self.IsShow()))` after `Open()`. If False, root cause is in this list (likely #1 or parent-hidden). If True but no visible window, the issue is z-order/parent-hidden — recheck causes 2 and 4 above before walking #2 (which covers click-not-reaching, a different symptom).

**See also:** `skills/m2ui/reference/anchors/01-simple-dialog.md` for the canonical Open/Close/Show pattern; `skills/m2ui/reference/mental-model.md` Section 1 (layout) and Section 5 (lifecycle) for visibility/show ordering rules.

---

## 2. "Click goes through / nothing happens"

**Likely root causes (ranked by frequency):**

1. **Decorative parent missing `not_pick`** — A background `expanded_image` or `text` sibling drawn AFTER the button intercepts the click. Fix: add `"style": ("not_pick",)` to every decorative widget in the uiscript dict (backgrounds, separators, label text).
2. **Button outside parent bounds** — Hit-test respects parent rect. A button at `x=300` inside a `width=200` parent gets clipped from picking. Fix: verify `button.x + button.width <= parent.width` and same for y/height.
3. **`SetEvent` never called on a regular button** — Construction did not wire the callback. Fix: grep the root class for `<buttonName>.SetEvent(`; if missing, add `btn.SetEvent(ui.__mem_func__(self.OnX))`.
4. **`SetCloseEvent` never called (close-button-broken case)** — When using `board_with_titlebar`, the X close button does NOT auto-fire `Close()`. Root class must explicitly wire it. Two equivalent approaches both work in the engine: `self.board.SetCloseEvent(ui.__mem_func__(self.Close))` (board-level wiring — preferred per `skills/m2ui/reference/widgets.md` BoardWithTitleBar API and `skills/m2ui/modes/script.md`), OR `self.GetChild("TitleBar").SetCloseEvent(ui.__mem_func__(self.Close))` (direct titlebar access, used in anchors `04-9slice-panel.md` and `06-tooltip-bound.md`). Pick one. Symptom: clicking X does nothing.
5. **Window hidden but listening** — `Hide()` removes from picking entirely; clicks pass to whatever is below. Fix: confirm `IsShow()` returns True at click time.
6. **Z-order wrong (later-drawn sibling on top)** — A second decorative widget with no `not_pick` overlaps. Fix: add `not_pick` OR re-order children so interactive widgets are drawn last.

**Quick check:** Add `dbg.TraceError("entered OnClick")` inside the suspect button's callback. Click the button. If the trace never fires, the click never reached the button — walk causes 1-6. If the trace fires, the click reached but the handler logic is broken — different problem entirely.

**See also:** `skills/m2ui/reference/event-binding.md` for callback wiring; `skills/m2ui/reference/widgets.md` for `not_pick` style.

---

## 3. "Memory leak / crashes after closing N times"

**Likely root causes (ranked by frequency):**

1. **Missing `@ui.WindowDestroy` decorator** — `Destroy()` runs but children never get torn down; each open allocates fresh widgets that pile up. Fix: add `@ui.WindowDestroy` above every `def Destroy(self):`.
2. **Bare bound method on `SetEvent`** — `btn.SetEvent(self.OnClick)` creates a strong cycle: button → bound method → self → button. GC cannot collect. Fix: wrap via `ui.__mem_func__(self.OnClick)` per `skills/m2ui/reference/event-binding.md` matrix.
3. **`lambda: self.OnClick()` on `SetEvent`** — Same cycle, lambda closure captures `self`. Fix: same as #2 — `ui.__mem_func__` or extra-args feature.
4. **ChildWindow stored on `self` never released** — `self.dialog = SubDialog()` without matching `self.dialog = None` (or `self.dialog.Destroy()`) in `Destroy()`. Fix: in `Destroy()`, walk every `self.X` set in `__LoadWindow` / `__init__`, set to `None` (or call `self.Initialize()` to do it via the standard reset).

**Quick check:** Open + close the window 5 times in a row, then call `import gc; gc.collect(); print(gc.garbage)`. Non-empty list = leak.

**See also:** `skills/m2ui/reference/event-binding.md` is mandatory; `skills/m2ui/modes/diagnose.md` runs an automated audit for these.

---

## 4. "OnPressEscapeKey crashes during child iteration"

**Likely root causes (ranked by frequency):**

1. **Missing `return True`** — Default return is `None`, which the engine treats as "not handled" and re-dispatches Escape to the next window in the stack. If that next window also returns `None`, the escape hammer iterates until something raises. Fix: `def OnPressEscapeKey(self): self.Close(); return True` — `True` always.
2. **`Close()` mutates the window-stack mid-iteration** — Closing a window that's currently being iterated over by the engine's escape-dispatch loop invalidates the iterator. Fix: keep `Close()` minimal (Hide + cleanup); never spawn or destroy other windows from inside `OnPressEscapeKey`.
3. **Child window's own `OnPressEscapeKey` raises** — A modal child without the method (or with a broken implementation) propagates the exception up. Fix: every modal child needs `OnPressEscapeKey` returning True.
4. **Modal stack popped while iterating** — Same root problem as #2 but specifically with `interfacemodule.HideAllWindows()` called from inside the handler. Fix: defer the HideAll via `OnUpdate` or a one-shot timer instead of calling it inline.

**Quick check:** Wrap `OnPressEscapeKey` body in `try/except` + `dbg.TraceError(traceback.format_exc())`; press Escape. The traceback names the failing window class.

**See also:** Every anchor in `skills/m2ui/reference/anchors/` shows the correct `return True` pattern.

---

## 5. "Text/locale shows as raw key string"

**Likely root causes (ranked by frequency):**

1. **Locale entry literal missing from the locale file** — When a key isn't defined for the active language, the renderer falls back to printing the key itself. Fix: grep `pack/locale/<lang>/ui/` (or your project's locale path) for the key; if absent, append `KEY\tValue` (tab-separated, no quotes).
2. **Wrong module used (root vs uiscript)** — `localeInfo.X` belongs in root `ui*.py` files; `uiScriptLocale.X` belongs in `uiscript/*.py` dict files. Mixing them raises `NameError` (module not imported in this scope) or `AttributeError` (key absent from this module's namespace) — it does NOT silently render the raw key. Fix: in root code use `localeInfo.X`; in uiscript dicts use `uiScriptLocale.X`. See `skills/m2ui/reference/locale.md` for the universal split.
3. **Module imported but key not present in current language file** — The English file has the key, the German file doesn't. Fix: add the key to ALL locale variants you ship.
4. **Key has a typo against the locale file** — `localeInfo.WINDOW_TITTLE` vs `WINDOW_TITLE` in the file. Fix: copy-paste the exact key from the file.
5. **Wrong file encoding** — Locale file written as UTF-8 but client expects Windows-1252 / 1254 / 1256 etc. Renderer reads garbage and falls back to key string for some entries. Fix: see `skills/m2ui/reference/locale.md` encoding table.

**Quick check:** In the running client, with the locale loaded, evaluate `localeInfo.WINDOW_TITLE` (or `uiScriptLocale.X` in a uiscript context) — if it returns the literal key string `"WINDOW_TITLE"`, root cause is #1, #3, or #4. If it raises `AttributeError`, root cause is #2.

**See also:** `skills/m2ui/reference/locale.md` (definitive split + encoding).

---

## 6. "Image shows as red X / pink box"

**Likely root causes (ranked by frequency):**

1. **Asset path wrong / case-sensitive** — `D:/Ymir Work/UI/...` works on Windows but fails on case-sensitive packs / servers. Fix: lowercase entire path: `d:/ymir work/ui/...`.
2. **Wrong format** — `.png` / `.jpg` / `.bmp` are not engine formats. Fix: convert to `.tga` or `.dds` and reference the converted path.
3. **9-slice corner sizes don't match texture** — `expanded_image` rect math uses corner tile size; specifying a 16×16 corner against an 8×8 source texture renders blown-out garbage. Fix: measure the source `.tga` corner; match the rect cell count exactly. See `skills/m2ui/reference/anchors/04-9slice-panel.md` for the math.
4. **`LoadImage` called on a non-image widget** — Calling `widget.LoadImage(...)` on a `text` or `button` instance silently fails to bind. Fix: confirm the widget is `image` / `expanded_image` / `image_box`.
5. **Asset exists on disk but engine pack not regenerated** — Pack-based deployment caches the asset list; new files added to disk aren't visible until repack. Fix: regenerate the `.epk` / `.eix` pair (or your project's equivalent) after adding assets.

**Quick check:** Open the asset path in your file explorer (lowercase, with the exact extension). If it doesn't exist, root cause is #1 or #5. If it opens correctly, root cause is #2, #3, or #4.

**See also:** `skills/m2ui/reference/anchors/04-9slice-panel.md` for 9-slice math; `skills/m2ui/reference/widgets.md` for image widget types.

---

## 7. "Scrollbar doesn't scroll / scrolls wrong range"

**Likely root causes (ranked by frequency):**

1. **`SetScrollEvent` callback never updates content** — Scrollbar fires the event but the callback is empty / a stub. Fix: wire `scrollbar.SetScrollEvent(ui.__mem_func__(self.OnScroll))`; the callback takes NO `pos` argument — read the position via `pos = self.scrollbar.GetPos()` (returns float 0.0-1.0) and recompute the visible rows from that.
2. **`OnMouseWheel` missing `return True`** — Scrollbar hover area handles the wheel but returns None, so the engine bubbles the wheel to the parent (which scrolls something else, or nothing). Fix: `def OnMouseWheel(self, length): self.scrollbar.OnUp() if length > 0 else self.scrollbar.OnDown(); return True`.
3. **`SetMiddleBarSize` not set or set wrong** — `SetMiddleBarSize(pageScale)` controls the thumb size as a fraction of the track (e.g., `visible_lines / total_lines`). If unset, the thumb fills the track and there's nothing to drag. Fix: `scrollbar.SetMiddleBarSize(float(visible_lines) / max(1, total_lines))`.
4. **`SetScrollStep(0)` blocks all scroll** — Step of 0 means each click moves zero distance. Fix: `scrollbar.SetScrollStep(0.1)` or `0.2` (range 0.0-1.0; smaller = finer granularity).
5. **`firstSlotIndex` not clamped on overscroll** — User scrolls past the end and the index goes negative or beyond `total_lines`, causing an out-of-range render. Fix: `startIndex = max(0, min(scrollLines, computed_index))` where `scrollLines = max(0, total_lines - visible_lines)`.

**Quick check:** Inside the `OnScroll` callback, `dbg.TraceError("scroll pos: " + str(self.scrollbar.GetPos()))`. Drag the scrollbar. If the trace fires with values 0.0-1.0, wiring is correct; root cause is in the content-update logic (#1 or #5). If it doesn't fire at all, wiring is broken (#2 or #4).

**See also:** `skills/m2ui/reference/anchors/02-board-with-list.md` for the canonical scrollbar + list pattern.

---

## 8. "Layout breaks at certain resolution"

**Likely root causes (ranked by frequency):**

1. **Hardcoded coords** — `x = 1920 - 200` only works at 1920×1080. Fix: replace literals with `app.GetScreenWidth() - 200` (or call `SetCenterPosition()` for the whole window).
2. **Window not re-centered on resolution change** — `SetCenterPosition()` runs once at `Open()`; if the user changes resolution while the window is up, the position stays at the old center. Fix: call `SetCenterPosition()` from `Open()` AND from any place the window becomes visible after a setting change. For per-fork resize-hook discovery, grep `pack/pack/root/ui*.py` for `def OnUpdateScreenSize\|def OnResize\|def OnChangeMonitor` — name varies per fork; do NOT assume `OnUpdateScreenSize` exists in your project without verifying.
3. **`expanded_image` `rect` uses hardcoded tile counts captured at uiscript load** — A `(rect_x, rect_y)` set to `(15, 8)` based on an old window size doesn't auto-recalc when the window grows. Fix: re-call `image.SetRenderingRect(...)` from your resize hook with the new values.
4. **Manual child positioning recomputed off the OLD parent size** — Setter changes parent width but children were positioned during `__LoadWindow` against the old width. Fix: refactor child-positioning code into a `_ReflowChildren()` method called from both `__LoadWindow` AND from any setter that resizes the window.

**Quick check:** Resize the client to a non-default resolution (e.g., 1280×720). Open the window. If the chrome is fine but content widgets are clipped or overflow, root cause is #1 or #4. If the entire window is off-screen, root cause is #2.

**See also:** `skills/m2ui/reference/widgets.md` for `SetPosition` / `SetCenterPosition` / `SetRenderingRect` APIs.

---

## 9. "Tooltip stuck after window close"

**Likely root causes (ranked by frequency):**

1. **`Close()` does not call `tooltipItem.HideToolTip()`** — Hovering an item slot showed the tooltip; closing the window via X or Escape hides the slot but the shared tooltip (owned by `interfacemodule`) keeps drawing. Fix: in `Close()`, `if self.tooltipItem: self.tooltipItem.HideToolTip()`.
2. **Tooltip is owned by interfacemodule but window holds last `Show()` ref** — Multiple windows share the same tooltip; closing one without an explicit hide leaves the tooltip in the visible-state from that window's last hover. Fix: same as #1 — every window that shares the tooltip must hide it on its own `Close()`.
3. **Modal layered on top hides parent but leaves tooltip on top** — A confirmation dialog opens above the slot window; the slot window's `Hide()` doesn't hide the tooltip. Fix: chain `tooltipItem.HideToolTip()` into whatever opens the modal, OR hide before opening the modal.

**Quick check:** Hover a slot, then Escape-close the window. If the tooltip remains painted in the same screen position, root cause is #1.

**See also:** `skills/m2ui/reference/anchors/06-tooltip-bound.md` shows the Close → HideToolTip pattern explicitly.

---

## 10. "EditLine input goes nowhere after close"

**Likely root causes (ranked by frequency):**

1. **`KillFocus()` not called on the EditLine before `Hide()`** — Focus stays on the now-hidden widget; subsequent keypresses are routed there and discarded silently. Fix: in `Close()`, `if self.editLine: self.editLine.KillFocus()`.
2. **Focus stuck on a destroyed widget** — Window was `Destroy`'d while the EditLine had focus; the engine still routes input to the dangling reference. Fix: same as #1 but call `KillFocus()` from `Destroy()` too (or via `Initialize()` reset that the decorator triggers).
3. **Engine input dispatch routes to last-focused widget regardless of visibility** — Chat or another EditLine takes focus next; if your window's hide-cycle is wrong, those keypresses appear to "do nothing" because they go to your hidden widget. Fix: same as #1 — explicit `KillFocus()` is the universal cure.

**Quick check:** Type after close. If your in-game chat doesn't receive the keys (and nothing else does either), focus is stuck on the hidden EditLine.

**See also:** `skills/m2ui/reference/widgets.md` for EditLine focus API.

---

## 11. "Feature flag check fails silently (gated window doesn't appear)"

**Likely root causes (ranked by frequency):**

1. **Feature flag check inverted** — `if not app.ENABLE_X` instead of `if app.ENABLE_X`. The window code runs only when the feature is OFF. Fix: re-read the gating expression; flip the negation.
2. **Flag exists but defaults to False** — The flag is registered in `app.py` but commented-out / set to `False` for the build. Fix: confirm `app.ENABLE_X = True` (or the project's equivalent) is uncommented and reachable on import.
3. **`getattr(app, "ENABLE_X", False)` returns False because the flag was never registered** — The defensive `getattr` swallows the missing attribute and returns the False default. Fix: either register the flag in `app.py`, OR drop the gate entirely if the feature is always-on in your project.
4. **Flag name typo against the registered name** — `app.ENABLE_FOO_BAR` vs `app.ENABLE_FOOBAR`. Fix: grep your `app.py` (or wherever flags live) for the exact name.

**Quick check:** Add `dbg.TraceError("flag value: " + repr(getattr(app, 'ENABLE_X', '<MISSING>')))` immediately above the gate. Trigger the open. The trace tells you whether it's `False`, `True`, or `<MISSING>`.

**See also:** `skills/m2ui/reference/anchors/05-feature-gated.md` for the canonical 5-point gating pattern.

---

## 12. "Window opens then immediately closes"

**Likely root causes (ranked by frequency):**

1. **`OnUpdate` calls `Close()` based on a distance/state check that's too tight** — Per-frame check evaluates True on the first frame and closes before the user sees anything. Fix: log the `OnUpdate` checks; loosen the threshold or guard with a state flag.
2. **Net packet handler sends `Close` packet on every receive** — A handler bound to a frequent packet (e.g., `RECV_CHARACTER_UPDATE`) calls `Close()` unconditionally. Fix: check the packet payload before deciding to close; gate on a specific event id, not the receive itself.
3. **Quest engine triggers a hide on quest-state-change** — Generic quest hooks call `interfacemodule.HideAllWindows()` when any quest state mutates; your window gets caught in the dragnet. Fix: your window's `Close()` should be safe to call repeatedly, but if the quest hide is wrong, exempt this window via a registry or gate the quest handler.
4. **`OpenX` called inside `Close()` (or vice versa)** — Recursion: open triggers a side effect that triggers a close that triggers an open. Stack winds up on `Close`. Fix: comment out the suspect call; bisect with traces.

**Quick check:** Add `dbg.TraceError("Close called from " + traceback.format_stack()[-2])` at the top of `Close()`. The trace tells you who's calling Close immediately after Open.

**See also:** `skills/m2ui/reference/anchors/01-simple-dialog.md` for canonical Open / Close flow.

---

## 13. "Header / text appears at wrong vertical position (offset from intended)"

**Likely root causes (ranked by frequency):**

1. **`all_align` set on the text widget** — `LoadElementText` treats `all_align` as a SUPER-set: it calls `SetWindowHorizontalAlignCenter()` AND `SetWindowVerticalAlignCenter()` in addition to text alignment. The widget's `(x, y)` then becomes an OFFSET from parent CENTER, not absolute coords from parent top-left. So `{"y": 30, "all_align": "center"}` on a board of height 700 renders at engine-y `350 + 30 = 380`. Two text widgets with `"y": 30` and `"y": 385` and `all_align` BOTH render off-spec — the first appears mid-board, the second renders beyond the bottom edge and is invisible. Fix: drop `all_align` from headers/body text; use `horizontal_align: "center"` + `text_horizontal_align: "center"` (both align text WITHIN the widget without re-anchoring the widget itself).
2. **Hardcoded y collides with chrome** — text at `y < 32` inside `board_with_titlebar` may sit behind the engine-rendered titlebar. Fix: section headers under a titlebar start at `y >= 32` (titlebar height + 4 px clearance).
3. **Parent's own `vertical_align` re-anchored the parent** — same trap one level up. Fix: walk up `self.X` parent refs and audit every `align` flag.
4. **Computed coordinate exceeds parent height** — `y >= parent.height` makes the text invisible (clipped or off-screen). Fix: confirm `text_y + text_height <= parent.height`.

**Quick check:** Temporarily comment out `"all_align"` on the suspect text widget and reload. If the text appears at the intended y, root cause is #1. If not, walk #2 → #4.

**See also:** `skills/m2ui/reference/widgets.md` text section — `all_align` row contains the canonical warning. `skills/m2ui/reference/mental-model.md` Section 1 has the alignment rules.

---

## 14. "ComboBox dropdown overlaps the rows below it"

**Likely root causes (ranked by frequency):**

1. **Engine behavior — dropdown opens DOWNWARD only** — `ui.ComboBox.__ArrangeListBox()` always positions the list at relative `(0, height + 5)` of the combo, on the `TOP_MOST` layer. There is no flag to flip upward. With rows spaced 25 px and an item count of 5, the list always covers the next 1-3 rows. Not a code bug; a design constraint. Fix: pick one mitigation (a) reserve clearance via row spacing `next_row_y - this_combo_y >= max_item_count * 17 + 10`, (b) replace `ComboBox` with a popup `ListBox` triggered by a button (you control the open direction), (c) subclass `ui.ComboBox` and override `__ArrangeListBox` to flip up when near the parent's bottom edge, (d) replace with a `radio_button` group when there are ≤ 4 options.
2. **Multiple ComboBoxes in a dense column** — row spacing was sized for the COLLAPSED combo (~17 px) without considering the expanded list. Fix: at design time, pick spacing for the WORST-case open list, OR adopt mitigation (b) above for the form as a whole.

**Quick check:** Click the topmost ComboBox in the offending form. If the dropdown visually covers the next widget, root cause is #1. The behavior is reproducible — it's not a transient or focus-related bug.

**See also:** `skills/m2ui/reference/widgets.md` "ComboBox dropdown caveat" subsection (load-time guidance for new forms).

---

## 15. "Window position not persisted across login"

**Likely root causes (ranked by frequency):**

1. **`SetCenterPosition` called in `Open()` always** — every Open re-centers the window, ignoring last-known position. Fix: persist `(x, y)` to a per-character settings store on close, restore on Open. The exact API varies per fork — `app.SaveSetting`/`LoadSetting` if the fork exposes it, otherwise a `constInfo` dict written to disk via `playerSettingModule` or a fork-specific helper. Grep the fork for "SaveSetting" / "settings.txt" / similar to find the canonical persistence path before wiring; if absent, this fix requires adding the persistence layer first.
2. **Window flagged `movable` but lacks save hook** — user drags the window to a new position; nothing persists the move. Fix: hook `OnMouseLeftButtonUp` (or fork-equivalent) to write the position to whatever persistence layer the fork provides.
3. **HideAllWindows on logout teardown drops position state** — interfacemodule-level cleanup zeroes out all instance state. Fix: persist settings BEFORE the teardown runs (in `Close()` not in `Destroy()`).

**Quick check:** Drag the window, log out, log back in. If the window opens at `SetCenterPosition` default, root cause is #1 or #3. If it opens at `(0,0)`, root cause is #2.

**See also:** `skills/m2ui/reference/anchors/05-feature-gated.md` for app.* API discipline. Verify any persistence API in `bindings.md` before relying on it (Critical Rule 16).

---

## 16. "Drag stops mid-op when source slot hides"

**Likely root causes (ranked by frequency):**

1. **Source window's `Hide()` called during drag** — engine cancels in-flight drags when the source becomes invisible. Fix: in `Hide()`, check `mouseModule.mouseController.isAttached()` and call `DeattachObject()` first.
2. **Drag started from a slot whose parent window closes via OnUpdate distance check** — the auto-close pattern (patterns.md section 7.15) hides the parent mid-drag. Fix: gate the OnUpdate close on `not mouseController.isAttached()`.
3. **Drag callback raised an exception** — `SetCallBack`'s handler crashed; engine silently drops the drag. Fix: wrap drop-handler body in try/except + `dbg.TraceError(traceback.format_exc())`.

**Quick check:** Add `dbg.TraceError("hide called: attached=" + str(mouseController.isAttached()))` to `Hide()`. Drag, then close the window. If trace fires `attached=True`, root cause is #1 or #2.

**See also:** `skills/m2ui/reference/anchors/14-drag-and-drop.md`; bindings.md `mouseModule.mouseController`.

---

## 17. "ItemTooltip references wrong item after rebind"

**Likely root causes (ranked by frequency):**

1. **`SetItemToolTip` called once at `__LoadWindow` with stale ref** — tooltip widget binds to the slot present at load time; later slot reassignment doesn't re-bind. Fix: re-call `SetItemToolTip` after every slot-content change.
2. **Tooltip cached state from previous hover** — `OnOverInItem` sets internal cache; same item ID at a different slot pulls cached visuals. Fix: call `tooltipItem.ClearToolTip()` before showing the new item.
3. **`tooltipItem` is shared across multiple windows** — interfacemodule-owned tooltip serves all windows; Window A binds it last, Window B opens and tries to use the still-bound state. Fix: each window calls `SetItemToolTip(self.tooltipItem)` in its own `__LoadWindow`.

**Quick check:** Hover slot 0 (item A) → close window → reopen → hover slot 0 (now item B). If tooltip shows A's stats, root cause is #1 or #2.

**See also:** `skills/m2ui/reference/anchors/06-tooltip-bound.md`; failure-atlas entry 9 (tooltip stuck after close — related but distinct).

---

## 18. "EditLine maxlen ignored under IME composition"

**Likely root causes (ranked by frequency):**

1. **Engine maxlen enforced post-commit only** — IME composition (Korean/Japanese/Chinese) accepts unbounded length until commit; engine truncates on commit. By that point the user already typed past the limit. Fix: hook `OnIMEUpdate` and call `SetText(GetText()[:maxlen])` to truncate live.
2. **Pasted text bypasses maxlen** — engine paste path skips the IME maxlen check. Fix: hook the paste event (fork-specific name; grep `OnIMEPaste` or `OnPaste`) and truncate.

**Quick check:** Enable IME (system tray → Korean/Japanese/Chinese), type more than maxlen characters in the EditLine. If the field accepts them all and only truncates on commit, root cause is #1.

**See also:** `skills/m2ui/reference/widgets.md` EditLine IME gotcha subsection.

---

## 19. "Grid slot click selects wrong cell (off-by-one)"

**Likely root causes (ranked by frequency):**

1. **`int()` vs `//` on cell-index math** — `int()` truncates TOWARD ZERO, `//` floors TOWARD NEGATIVE INFINITY. They differ for negative offsets: `int(-1.5)` is `-1` but `-3 // 2` is `-2`. When `mouse_x - grid_origin_x` goes negative (click just left of grid), `int(x / cell_width)` gives the wrong cell index. Also, py3's `/` returns float regardless of operand type, so emitting `/` in py2-targeted code that gets ported to py3 introduces float-vs-int drift. Fix: use `//` explicitly for cell-index math so behavior is identical and well-defined across both Python versions.
2. **Grid origin offset not subtracted before division** — agent forgot to subtract `grid_origin_x` first; `mouse_x // cell_width` returns global-coord cell which is wrong. Fix: `(mouse_x - grid_origin_x) // cell_width`.
3. **Cell width computed off `parent.width / cols`** — division rounds; (parent.width=200, cols=5) gives cell_width=40 BUT (parent.width=201, cols=5) gives cell_width=40 still — last column overflows. Fix: use `parent.width // cols` and add a sentinel for the last column.

**Quick check:** Click each cell of the grid in sequence. Print `dbg.TraceError("clicked: " + str(computed_index))`. If trace shows wrong index for cells near grid edges, root cause is #1 or #2.

**See also:** `skills/m2ui/reference/widgets.md` SlotWindow vs GridSlotWindow gotcha; patterns.md section 7.5 paginated slot grid.

---

## 20. "Sound on button never plays"

**Likely root causes (ranked by frequency):**

1. **Asset path missing or wrong** — `snd.PlaySound("sound/ui/click.wav")` requires the file at `D:\ymir work\sound\ui\click.wav` (case-sensitive on Linux server). Fix: verify with Glob; lowercase the path; confirm `.wav` extension.
2. **Sound module not imported** — `import snd` missing at top of root file. Fix: add the import.
3. **`snd.PlaySound` on a button without a callback wire** — agent put PlaySound at the wrong scope (e.g., in `__LoadWindow` directly, fires once on load). Fix: call PlaySound from inside the button's `SetEvent` callback.
4. **Audio disabled in client settings** — user turned off UI sound globally. Fix: not a code bug; check the client's settings dialog.

**Quick check:** Add `dbg.TraceError("PlaySound called: " + path)` next to the `snd.PlaySound` call. Click the button. If trace fires but no sound, root cause is #1, #2, or #4. If trace doesn't fire, root cause is #3.

**See also:** bindings.md `snd` module.

---

## 21. "ARGB/RGBA channel swap (color renders as wrong channel)"

**Likely root causes (ranked by frequency):**

1. **`0xAARRGGBB` mistaken for `0xAABBGGRR`** — agent emitted color hex with red/blue swapped. Fix: A-R-G-B reads alphabetically; cross-check the bytes.
2. **`0xRRGGBBAA` (web-style) used directly** — agent applied CSS-style channel order; engine reads the literal as `0xAARRGGBB`, putting the alpha byte where red should be. Fix: convert from web-style: web `0xRRGGBBAA` = engine `0x{AA}{RR}{GG}{BB}` — rotate the alpha byte to the front.
3. **`grp.GenerateColor(r, g, b, a)` arg order swapped** — agent wrote `(a, r, g, b)` thinking alpha-first matches the literal. Fix: `grp.GenerateColor` is `(r, g, b, a)` in 0.0-1.0 floats.

**Quick check:** Set the color to `0xFF0000FF` (intended: red with alpha=full). If it renders as blue, root cause is #1 or #2. If it renders correctly as red, the issue is elsewhere.

**See also:** `skills/m2ui/reference/visual-conventions.md` Color hex format subsection.

---

## 22. "Search dialog returns stale results after server delay"

**Likely root causes (ranked by frequency):**

1. **Synchronous list-refresh after Send** — `OnSearch()` calls `net.SendSearchPacket(filters)` then immediately calls `self.RefreshList()` reading prior `RecvSearchResults` payload. New results arrive later via `RecvSearchResults` and re-trigger refresh, but the user already sees the OLD list for the gap. Fix: clear list + show "Searching..." status overlay on Send; populate ONLY on Recv. Track `isSearchPending` bool.
2. **Multiple Sends without dedup** — fast clicker sends 3 search packets; server replies in any order; last-arrived overwrites earlier results, not the most-recent-sent. Fix: increment a request-id counter on Send; ignore Recv if its request-id != latest.
3. **Filter snapshot read at Recv time instead of Send time** — user changes filter → clicks Search → fast-changes filter → first Recv populates with stale filters. Fix: snapshot `currentFilters` at Send time; render Recv results against that snapshot.

**Quick check:** Click Search rapidly with different filter values. If shown results don't match the last-active filters, root cause is #1, #2, or #3.

**See also:** `skills/m2ui/reference/anchors/17-search-filter-dialog.md`; `skills/m2ui/reference/anchors/15-network-coupled-flow.md` (request-response variant 2).

---

## 23. "Daily reward grid claims wrong day after midnight (tz boundary)"

**Likely root causes (ranked by frequency):**

1. **Client-`app.GetTime()`-based `today` computation** — UI computes `today_idx = (app.GetTime() // 86400) % 7` locally. Server uses its own `serverEpoch`. At midnight near tz boundary, client's `today_idx` jumps to tomorrow before server agrees. Fix: server pushes `todayDay` in `RecvDailyState`; UI uses that exclusively.
2. **Daylight-saving transition** — `app.GetTime()` shifts ±1 hour. Same desync as #1.
3. **Player travels through tz** — local time changes; server time doesn't. Same desync as #1.

**Quick check:** Set client clock 1 hour ahead of server. If grid shows tomorrow as available, root cause is #1.

**See also:** `skills/m2ui/reference/anchors/19-daily-reward-grid.md`; `skills/m2ui/reference/timer-patterns.md` section 5 (daily-event-timing).

---

## 24. "Wheel animation ends on wrong segment (server desync)"

**Likely root causes (ranked by frequency):**

1. **Client-side random selection in OnUpdate** — `OnUpdate` picks the final segment via `random.randint(0, totalSegments)` to drive the animation. The server's reward (received later via `RecvSpinResult`) doesn't match. Fix: server's `RecvSpinResult` payload INCLUDES `finalSegmentIdx`; client uses it exclusively to compute `finalRotation`.
2. **Mismatched `spinCount` on client and server** — client animates to `spinCount * 360 + targetDegrees`; server expected client to use `spinCount=5`. With `spinCount=4`, the wheel lands on a different visible segment. Fix: server payload also specifies `spinCount`, OR both sides agree on a shared constant.
3. **Floating-point precision drift** — animation runs for 5+ seconds; accumulated `dt` math drifts from intended `finalRotation` by 1-2 degrees, enough to land on a neighboring segment. Fix: at settle, snap rotation to exactly `finalRotation` (don't trust accumulated math).

**Quick check:** Spin 10 times; record server-reported reward vs visible segment. If they ever differ, root cause is #1 or #2.

**See also:** `skills/m2ui/reference/anchors/21-wheel-roulette.md`; `skills/m2ui/reference/timer-patterns.md` sections 2 / 6 / 7.

---

## 25. "Mailbox attachment lost on send-reject"

**Likely root causes (ranked by frequency):**

1. **DeattachObject before server confirms** — `OnSendMail()` sends the packet then calls `mouseModule.mouseController.DeattachObject()`. If the server rejects (over-capacity, item-bound, recipient-blocked), the attachment is gone but the item was not sent. Fix: detach only after `OnRecvMailSent(success=True)`. On reject, leave the attachment attached so the user can retry.
2. **Window close mid-send** — user clicks Send then closes the window before the Recv arrives. Window's `Destroy()` clears attachment refs. Fix: `Hide()`/`Destroy()` checks `is-send-pending`; if true, defer cleanup until Recv.

**Quick check:** Trigger over-capacity Reject (mail to a full inbox); check inventory for the attached item. If gone, root cause is #1.

**See also:** `skills/m2ui/reference/anchors/18-mailbox-two-pane.md`; `skills/m2ui/reference/anchors/14-drag-and-drop.md`.

---

## 26. "Rank list refresh hangs UI for >100ms"

**Likely root causes (ranked by frequency):**

1. **Full-list rebuild on every refresh** — `RefreshRanking()` deletes all N row widgets via `child.Destroy()` then re-creates N new widgets. For N=100 this is 200 widget operations; UI hangs noticeably. Fix: ROW-POOL pattern — pre-allocate N row widgets at `LoadWindow` time. On refresh, walk rows and call `SetText` / `SetIcon` on existing widgets. Hide overflow rows.
2. **Per-row tooltip widget rebuild** — each row owns its own tooltip widget; refresh creates 100 new tooltips. Fix: tooltip is shared (interfacemodule-owned `tooltipItem`); hover-enter sets its data.
3. **Synchronous icon-load on refresh** — each row loads its own icon image from disk. Disk I/O on 100 rows = hang. Fix: pre-cache icon handles at `LoadWindow`; refresh swaps cached handles.

**Quick check:** Refresh ranking with N=100. Time the UI hang via stopwatch. If >100ms, root cause is #1.

**See also:** `skills/m2ui/reference/anchors/20-leaderboard-table.md`.

---

## 27. "Auto-hide chrome doesn't re-show on hotkey-open"

**Likely root causes (ranked by frequency):**

1. **Hotkey calls `Toggle()` without resetting `lastActivity`** — `Toggle()` toggles visibility; `OnUpdate`'s fade-timer is still running on `lastActivity = (last mouse move)`. Window opens then immediately starts fading. Fix: `Toggle()` and `Open()` reset `self.lastActivity = app.GetTime()`.
2. **Mouse-move handler not registered while window is alpha=0** — engine stops dispatching mouse events to fully-transparent windows. Fix: keep alpha >= 0.05 always (never fully 0); OR register a global mouse-move via `wndMgr` regardless of alpha.
3. **Multiple auto-hide windows with independent timers** — Window A's `OnUpdate` fades; Window B's hotkey opens it. B's hotkey doesn't see A's `lastActivity`. Fix: shared `lastActivity` in interfacemodule; all auto-hide windows read from it.

**Quick check:** Wait for window to fade. Press hotkey. If it opens then immediately fades again, root cause is #1.

**See also:** `skills/m2ui/reference/anchors/23-auto-hide-chrome.md`; `skills/m2ui/reference/timer-patterns.md` section 3 (fade-timer).

---

## 28. "Compare-tooltip leaks second tooltip widget"

**Likely root causes (ranked by frequency):**

1. **`compareTooltip` not destroyed on Interface teardown** — `interfacemodule.MakeInterface` lazy-builds `self.tooltipItem.compareTooltip = uitooltip.ItemToolTip()` on first compare. Teardown destroys `tooltipItem` but forgets `compareTooltip`. Fix: `__DestroyDialogs` adds an explicit null-out for `tooltipItem.compareTooltip`.
2. **Second tooltip created per hover, not lazy-once at first compare** — `OnOverInItem` creates a fresh `compareTooltip` widget; the prior instance orphans. Fix: lazy-build the secondary tooltip ONCE on first compare; subsequent compares reuse the instance via `SetInventoryItem`.
3. **OverOutItem doesn't clear the second tooltip** — primary tooltipItem clears via `tooltipItem.HideToolTip()`, but `compareTooltip` lingers. Fix: `HideToolTip()` body hides BOTH widgets.

**Quick check:** Hover items in inventory rapidly for 30 seconds (Alt held). Check `wndMgr.GetWidgetCount()` (or fork-equivalent). If count grows monotonically, root cause is #1 or #2.

**See also:** `skills/m2ui/reference/anchors/22-compare-tooltip.md`; `skills/m2ui/reference/anchors/06-tooltip-bound.md`.

---

## 29. "History navigation leaks hidden pages"

**Likely root causes (ranked by frequency):**

1. **Forward history sliced without destruction** -- `del self.windowHistory[self.currSelected + 1:]` drops Python refs but never calls `Destroy()` on parent-attached page widgets.
2. **Hidden pages treated as cleaned-up pages** -- `Hide()` only removes rendering / interaction; it does not remove the page from the parent widget tree.
3. **Page-owned children / callbacks keep the orphan alive** -- tooltips, slot callbacks, or child dialogs created by the page are not torn down because the page `Destroy()` never runs.

**Quick check:** Navigate A -> B -> C, back to A, then open D repeatedly. Trace `len(self.windowHistory)` plus a fork-provided widget-count helper (typical name: `wndMgr.GetWidgetCount` -- not part of the stock binding set documented in `reference/bindings.md`; verify it exists in your fork before relying on it). If history length stays bounded but widget count grows, root cause is #1.

**See also:** `skills/m2ui/reference/anchors/24-page-history-browser.md`; failure-atlas entry 3 (callback leaks); entries 9 / 28 (tooltip cleanup).

---

## 30. "Slot DisableSlot / state lost after setting items"

**Likely root causes (ranked by frequency):**

1. **`SetItemSlot()` resets `dwState` to 0** — `CSlotWindow::SetSlot()` and `ClearSlot()` both zero out `pSlot->dwState`, clearing `SLOT_STATE_DISABLE`, `SLOT_STATE_LOCK`, and all other state bits. Any state set before the `SetItemSlot` call is silently lost.
2. **State set during init only** — `DisableSlot()` called once in initialization, then `SetItemSlot()` overwrites it when items load.

**Quick check:** Call `DisableSlot(0)` after `SetItemSlot(0, ...)`. If the red overlay appears, root cause is #1 (state was set before item load). If it doesn't, the slot index is wrong or the slot type doesn't support state.

**See also:** `skills/m2ui/reference/widgets.md` "Slot state lifecycle" section; `skills/m2ui/reference/patterns.md` §7.17.

---

## 31. "Server command handler receives only first token / TypeError on command"

**Likely root causes (ranked by frequency):**

1. **Variadic dispatch signature mismatch** — when `constInfo.ENABLE_CMDCHAT_VARIADIC_ARGS = True`, `stringCommander.Run()` splits the command line by whitespace and passes each token as a separate positional arg. A handler expecting a single string raises `TypeError` (too many positional args); a handler expecting fewer args than tokens also raises `TypeError`.
2. **Handler registered with wrong name** — command string in `serverCommandList` doesn't match what the server sends (case-sensitive).

**Quick check:** Add `dbg.TraceError("args: %s" % str(args))` with `*args` as the handler signature. If you see a tuple of individual tokens, root cause is #1.

**See also:** `skills/m2ui/reference/bindings.md` "Server command dispatch" section.

---

## 32. "Window open causes infinite packet loop / client freezes on open"

**Likely root causes (ranked by frequency):**

1. **`Open()` both sends a server request AND is called from the server response handler** — creates a loop: `Open()` → sends packet → server responds → handler calls `Open()` → sends packet → ... The client floods the server with packets and freezes.

**Quick check:** Search for `net.Send` inside `Open()`. If found, check whether the server response handler also calls `Open()`. If both are true, this is the cause.

**Fix:** Split into `Open()` (sends request, user-initiated) and `ShowWindow()` (just displays, called from server response). See `skills/m2ui/reference/patterns.md` §5.9 "Server-mediated variant".

---

## 33. "Tooltip handler exists but tooltip never shows on hover"

**Likely root causes (ranked by frequency):**

1. **`SetItemToolTip()` never called** — the window class defines `SetItemToolTip(self, tooltip)` and `OnOverInItem`/`OnOverOutItem` handlers, but no code ever calls `SetItemToolTip()` to pass the tooltip widget reference. `self.tooltipItem` stays `None`, handlers silently no-op.
2. **Creation order in interfacemodule** — window created before tooltips exist in `MakeInterface()`, so `SetItemToolTip()` receives `None`.

**Quick check:** Grep for `SetItemToolTip` in the window class definition. If it exists, grep the entire codebase for callers. If nobody calls it, root cause is #1. If it's called but with `None`, root cause is #2 (creation order).

**See also:** `skills/m2ui/reference/integration.md` Variation 4 (tooltip binding); `skills/m2ui/reference/anchors/06-tooltip-bound.md`.

---

## 34. "Replaced/redirected widgets don't update (show stale values)"

**Likely root causes (ranked by frequency):**

1. **RefreshStatus delegation chain broken** — an external panel replaced widgets from another window (e.g., inventory money display redirected to an expanded taskbar), but `interfacemodule.RefreshStatus()` doesn't delegate to the replacement panel's `RefreshStatus()`.
2. **Original window's refresh doesn't run when hidden** — the original window's `RefreshStatus` forwarded to the replacement widgets, but it only runs when the original window is visible.
3. **Event wiring order wrong** — buttons/events wired in `__init__` before `BindInterfaceClass` runs, so `self.interface` is `None` and event handlers silently fail.

**Quick check:** Call `replacement.RefreshStatus()` manually from the console. If values update, root cause is #1 (delegation not wired). If they don't, the replacement's own RefreshStatus is broken.

**See also:** `skills/m2ui/reference/integration.md` Variation 5 (widget reassignment).

---

## 35. "Duplicate widgets visible after adding define gate"

**Likely root causes (ranked by frequency):**

1. **Gate applied to primary uiscript but not variant/extended version** — e.g., `inventorywindow.py` gates out money slots with `app.ENABLE_*`, but `inventorywindowex.py` (extended inventory) still includes them unconditionally. Both files contribute to the UI, so missing the gate on either shows duplicates.
2. **Gate condition inverted** — `if app.ENABLE_X` instead of `if not app.ENABLE_X` (or vice versa) in the children list builder.

**Quick check:** Grep for the widget name (e.g., `"Money_Slot"`) across all uiscript files. If it appears ungated in a variant file, root cause is #1.

**See also:** `skills/m2ui/reference/anchors/05-feature-gated.md` variation 6 (multi-file children gating).

---

## Debug snippets (appendix — not a symptom entry)

The following snippets are useful when diagnosing unfamiliar UI bugs. Drop them in temporarily, remove before commit. They are NOT canonical patterns.

### Temporary `not_pick` removal

When a click "isn't reaching" a button, suspect a sibling decorative widget without `not_pick` is intercepting. Temporarily comment out `"style": ("not_pick",)` on every decorative widget in the uiscript dict; the click that previously didn't reach should now go to the bottom-most widget. Identify the offender, then re-add `not_pick` only to the offender (NOT mass-removal).

### Colored expanded_image rect-borders for visual debug

Wrap any widget you want to visualize with a 1-pixel-thick `expanded_image` border (using a solid-color tile) to see the widget's actual rect on screen:

```python
debug_border = ui.ExpandedImageBox()
debug_border.SetParent(self.suspectWidget.GetParent())
debug_border.SetPosition(self.suspectWidget.GetGlobalPosition()[0],
                         self.suspectWidget.GetGlobalPosition()[1])
debug_border.LoadImage("d:/ymir work/ui/public/parameter_slot_3.sub")  # or any 1px-edge tile
debug_border.SetRenderingRect(0, 0, 0, 0)
debug_border.SetSize(self.suspectWidget.GetWidth(), self.suspectWidget.GetHeight())
debug_border.SetAlpha(0.4)
debug_border.Show()
self.debug_border = debug_border  # store ref so it doesn't GC
```

Remove before commit. The border reveals whether the widget's rect is where you think it is (alignment / `all_align` re-anchor surprises).

### `dbg.TraceError` rect-print one-liner

When alignment is suspected, print every ancestor's resolved rect:

```python
def _DebugRect(self):
    w = self
    while w:
        try:
            x, y = w.GetGlobalPosition()
            dbg.TraceError("rect: " + str(type(w).__name__) +
                           " x=" + str(x) + " y=" + str(y) +
                           " w=" + str(w.GetWidth()) +
                           " h=" + str(w.GetHeight()))
        except:
            pass
        w = w.GetParent()
```

Call from anywhere a widget's resolved position is suspect. Walks up the parent chain, prints every level. Most alignment bugs reveal themselves in the first 2-3 levels of output.

---

## Cross-references

- Callback wrapping → `skills/m2ui/reference/event-binding.md`
- Boilerplate templates → `skills/m2ui/reference/patterns.md`
- All 34 widget types + properties → `skills/m2ui/reference/widgets.md`
- Anti-pattern audit (automated) → `skills/m2ui/modes/diagnose.md`
- Visual conventions (chrome / palette / sizing) → `skills/m2ui/reference/visual-conventions.md`
- Few-shot anchors → `skills/m2ui/reference/anchors/README.md`
