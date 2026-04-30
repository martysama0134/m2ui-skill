# Anchor 15: Network-Coupled UI Flow (Augmentor)

## What this is + when to use it

The canonical client-server data flow for UI: button click → callback → `net.Send*Packet(args)` → server processes → server writes a `RecvX` packet → client's `networkmodule.MainStream.OnX(...)` handler decodes → calls a `interface.OperationX(...)` method → which routes to a window's setter → which mutates the widget. The pattern is bidirectional: clicks travel up via `net.Send*`, results travel down via `Recv*` callbacks dispatched through the registered `net.SetHandler` handler.

This is an AUGMENTOR — it documents the server-driven data flow that any archetype with `net.Send*` calls or `Recv*` registrations participates in. Body content lives in section 7.

Use this augmentor as a reference when: any window emits `net.Send*Packet` or any flow path includes a `Recv*` handler. Do NOT use as a standalone anchor — without a primary archetype, there's no window to wire the flow to.

## Source

Pattern extracted from `pack/pack/root/uishop.py` (button → `net.SendShopBuyPacket` → server → `RecvShopUpdate` → setter), `pack/pack/root/uiquest.py` (server-driven dialog open via `RecvQuestDialog`), `pack/pack/root/networkmodule.py` (the `MainStream` class, registered via `net.SetHandler(self)`), and `pack/pack/root/uirefine.py` (synchronous request-response with confirmation dialog) — all from a real Metin2 fork.

`networkmodule.MainStream` is the canonical Recv-handler dispatch point. Its methods are named `OnX` (e.g., `OnSafeboxSet`, `OnShop`, `OnExchange`, `OnQuestDialog`) and called by the C++ `net` module when matching packets arrive. The `MainStream` instance is bound globally via `net.SetHandler(self)` in `MainStream.__init__`.

Normalized to current m2ui rules:

- Setter methods on the window (called from the Recv handler via `interface.X`) MUST be defensive — `if not self.window: return` guards because the handler may fire before `MakeInterface` finishes OR after `__DestroyDialogs` runs.
- `net.Send*` calls validate locally before sending — server-side validation is authoritative but client-side prevention saves a round-trip on obviously-invalid input.
- ASCII-only

## Uiscript dict

Same as augmented archetype. Network coupling is purely a class-side concern; uiscript declares no widgets specific to networking.

## Root class

Augmentor-only decoration: the `net.Send*` call sites in the window's button callbacks, the setter methods that get called from `interfacemodule.OperationX(...)` (which `networkmodule.MainStream` calls), and the defensive guards.

```python
# Source-side: button click -> net.Send.
def OnAcceptButtonClicked(self):
    # Local validation BEFORE send (saves round-trip on obvious errors).
    if not self.targetItemPos:
        return
    if 0 == len(self.itemStock):
        chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.PRIVATE_SHOP_EMPTY)
        return

    # Send the packet. Server processes async; UI updates arrive via
    # a Recv handler that calls back into this window.
    net.SendBuildPrivateShopPacket(self.title)

    # Optional optimistic close -- for fire-and-forget commands.
    # For request-response, wait for the Recv handler to call .Close().
    self.Close()


# Destination-side: setter called from interfacemodule (which is called
# from networkmodule.MainStream's Recv handler).
def RefreshFromServer(self, payload):
    # Defensive: the Recv handler may fire before MakeInterface or after
    # __DestroyDialogs. Guard widget refs.
    if not self.itemSlotWindow:
        return

    for slot in payload:
        self.itemSlotWindow.SetItemSlot(slot["pos"], slot["vnum"], slot["count"])
    self.itemSlotWindow.RefreshSlot()
```

## Locale entries

No locale entries are owned by the network-flow augmentor itself. The augmentor surfaces server-driven failure messages via `chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.X)` where `X` is owned by the augmented archetype's locale.

## interfacemodule.py integration snippet

The flow visits four files: the augmented window's button callback, `interfacemodule.py`'s dispatch method, `networkmodule.py`'s Recv handler, and the C++ `net` Python binding (which the user's fork provides; not editable from Python).

```python
# In interfacemodule.py:
class Interface(object):

    def OpenSafeboxWindow(self, size):
        # Called from networkmodule.MainStream.OnSafeboxSet
        if self.wndSafebox:
            self.wndSafebox.ShowWindow(size)

    def RefreshSafebox(self):
        # Called from networkmodule.MainStream.OnSafeboxItem
        if self.wndSafebox:
            self.wndSafebox.RefreshSafebox()

    def CommandCloseSafebox(self):
        # Called from networkmodule.MainStream.OnSafeboxClosed
        if self.wndSafebox:
            self.wndSafebox.CommandCloseSafebox()
```

```python
# In networkmodule.py (the MainStream class):
class MainStream(ui.NoWindow):

    def __init__(self):
        net.SetHandler(self)
        # ... other setup ...

    def OnSafeboxSet(self, size):
        # Server has confirmed the password; open the safebox window.
        interface = self.interface  # MainStream holds a ref to interface
        if interface:
            interface.OpenSafeboxWindow(size)

    def OnSafeboxItem(self, slot, vnum, count):
        safebox.SetItemData(slot, vnum, count)  # safebox C++ binding
        if self.interface:
            self.interface.RefreshSafebox()

    def OnSafeboxClosed(self):
        if self.interface:
            self.interface.CommandCloseSafebox()
```

## Common variations

This is where the augmentor's body content lives — five canonical flow shapes that vary per consuming window. Each shape has different timing, validation, and error-recovery semantics.

### Variation 1: Fire-and-forget

The simplest flow. Click sends, UI closes immediately (or stays open without waiting), no server confirmation needed.

```python
def OnSellItem(self, slotPos, count, itemtype):
    net.SendShopSellPacketNew(slotPos, count, itemtype)
    snd.PlaySound("sound/ui/money.wav")
    self.OnCloseQuestionDialog()  # Close UI immediately
```

Use case: sell, drop, simple inventory moves. Server validates and either accepts (silent success) or rejects (server pushes a chat-message, no UI roundtrip).

**Variadic command dispatch:** When `constInfo.ENABLE_CMDCHAT_VARIADIC_ARGS = True`, server command handlers registered in `serverCommandList` receive each whitespace-separated token as a separate positional arg (all strings). The handler signature must match the token count exactly — do NOT accept a single string and split it manually. See `reference/bindings.md` "Server command dispatch" section for full details and examples.

### Variation 2: Request-response (open dialog after server confirms)

The window doesn't show until the server confirms the request.

```python
# Source side (where the request originates):
def OnUseSafebox(self, password):
    net.SendSafeboxOpenPacket(password)
    # NOTE: window is NOT shown here. It opens when OnSafeboxSet fires.

# Destination side (interfacemodule + networkmodule):
class MainStream:
    def OnSafeboxSet(self, size):
        # Server validated the password and replied with safebox size.
        # NOW open the window.
        if self.interface:
            self.interface.OpenSafeboxWindow(size)
```

Use case: password-protected windows, server-rate-limited windows, windows whose size/content depends on server state.

### Variation 3: Broadcast update (server pushes refresh to all clients)

Server-driven refresh independent of any specific client request.

```python
class MainStream:
    def OnShopUpdate(self, slot, vnum, count):
        # Server updated this shop slot -- could be any client's purchase
        # or a server-side stock change. Refresh anyone watching.
        shop.SetItemData(slot, vnum, count)
        if self.interface:
            self.interface.RefreshShop()
```

Use case: shared shops (private-shop browsing, mall pages), exchange windows (both clients see updates), guild storage. Multiple clients can be looking at the same data simultaneously; server pushes updates to all.

### Variation 4: Error-path / server rejection

Server-side validation rejects the request; client surfaces the error.

```python
class MainStream:
    def OnSafeboxRefuse(self, reason):
        # Server rejected (wrong password, locked, full). Reason code
        # selects the locale string.
        if reason == 0:
            chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.SAFEBOX_WRONG_PASSWORD)
        elif reason == 1:
            chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.SAFEBOX_LOCKED)
        else:
            chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.SAFEBOX_GENERIC_ERROR)

        # Reset client-side state (close dialog, reset password input, etc.)
        if self.interface and self.interface.dlgSafeboxPassword:
            self.interface.dlgSafeboxPassword.Reset()
```

Use case: password validation, capacity limits, server-side anti-cheat. Client-side validation should already prevent obvious errors; server rejects only escalations or stale-state requests.

### Variation 5: Optimistic update (UI updates pre-confirmation)

UI shows the change immediately; rollback if server rejects.

```python
# Source side:
def OnEquipItem(self, slot):
    # Optimistic: update UI before server confirms.
    self.equipmentSlots[slot] = self.draggedItem
    self.RefreshEquipmentDisplay()
    # Send packet; server may reject (anti-flag, level requirement, etc.).
    net.SendEquipItemPacket(slot)

# Destination side: server can reject by sending a refresh that overwrites
# the optimistic update.
class MainStream:
    def OnEquipReject(self, slot, reason):
        chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.X[reason])
        # Re-pull authoritative state from server.
        if self.interface:
            self.interface.RefreshEquipment()
```

Use case: high-frequency interactions where round-trip latency would feel sluggish (equipment swaps, quick-slot rebinds). Trade-off: clients can see "wrong" state briefly when server rejects. Rare in canonical Metin2 (most flows are pessimistic) but common in quick-slot management.

## Don't copy these obsolete bits

- Some forks dispatch Recv handlers from `net.py` directly to a window class instead of through `interfacemodule`. Anchor uses the canonical interface-routed path: `MainStream.OnX → interface.OperationX → window.RefreshFromServer`. Direct dispatch from `MainStream` to a window bypasses `interfacemodule`'s lifecycle (window may not exist yet, may have been destroyed).
- Real source's `MainStream.__init__` has `print("NEWMAIN STREAM ...")` debug remnants. Strip — use `dbg.TraceError` for production.
- Some forks use module-level functions in `net.py` instead of a `MainStream` class. Both work, but the class-based pattern (`net.SetHandler(self)`) lets the handler hold state (the `interface` reference) and decay gracefully (when the class instance dies, handlers stop firing). Module-level handlers leak state.
- Don't call `net.Send*` from inside a Recv handler unless explicitly chaining (e.g., the canonical safebox-open → password-verify → safebox-list flow). Server-side flooding protection treats fast-fire chains as suspicious; rate-limit or batch.
- Don't trust `RecvX` payloads without minimal sanity checks. The C++ `net` module decodes the packet structure but doesn't validate semantics — `RecvShopUpdate` could push `slot=999` if the server is buggy. Check `0 <= slot < SHOP_SLOT_COUNT` before calling `SetItemSlot(slot, ...)` to avoid out-of-bounds widget calls.
- Some forks store the Recv handler directly on the window instance (`window.OnSafeboxSet = ...`) instead of routing through interfacemodule. Anchor uses the indirection because the window's lifecycle is shorter than `interfacemodule`'s — handlers should survive across window opens/closes.
