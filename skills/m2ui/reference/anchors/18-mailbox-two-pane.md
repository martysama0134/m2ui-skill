# Anchor 18: Mailbox / Message Inbox (Two-Pane List + Detail)

## What this is + when to use it

A primary archetype for **two-pane message inboxes**. Left pane is a paginated list of message-summary buttons; right pane is the currently-selected message detail (sender, title, body, attachment row, action buttons). Server-driven: every interaction (open, click post, delete, claim attachment, compose, send) is a request-response pair.

Use this archetype for: in-game mail, GM-message inbox, system-announcement reader, offline-message system, friend-request inbox. The two-pane chrome is what distinguishes anchor 18 from `02-board-with-list` (passive paginated list) and `11-quest-npc-dialog` (event-module-driven; quest dialogs don't have post lists).

Layer `15-network-coupled-flow` for the request-response contract -- every action this window emits goes through Send/Recv. Layer `14-drag-and-drop` for attachment handling. Layer `16-tabbed-content` if the mailbox has Inbox / Sent / Compose tabs.

## Source

Patterns synthesized from a peer mailbox implementation in real Metin2 forks plus a cross-domain reference for label-line read-pane structure. The reference uses a multi-window pattern (separate `PostRead` and `PostWrite` popups); this anchor normalizes to a single two-pane window since that is the more common shape requested by maintainers and reduces the lifecycle surface (one Destroy path, one OnPressEscapeKey, one set of state variables). The reference's `Destroy(self): pass` was discarded -- the anchor preserves the canonical decorator + body pattern.

## Uiscript dict

`pack/pack/uiscript/uiscript/mailbox.py`:

```python
window = {
    "name" : "MailboxWindow",
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
            "title" : uiScriptLocale.MAILBOX_TITLE,

            "children" :
            (
                # ----- Tab strip (Inbox / Sent / Compose) -----
                {
                    "name" : "tab_inbox_button",
                    "type" : "radio_button",
                    "x" : 18,
                    "y" : 36,
                    "default_image" : "d:/ymir work/ui/public/tab_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/tab_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/tab_button_03.sub",
                    "text" : uiScriptLocale.MAILBOX_INBOX_TAB,
                },
                {
                    "name" : "tab_sent_button",
                    "type" : "radio_button",
                    "x" : 92,
                    "y" : 36,
                    "default_image" : "d:/ymir work/ui/public/tab_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/tab_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/tab_button_03.sub",
                    "text" : uiScriptLocale.MAILBOX_SENT_TAB,
                },
                {
                    "name" : "tab_compose_button",
                    "type" : "radio_button",
                    "x" : 166,
                    "y" : 36,
                    "default_image" : "d:/ymir work/ui/public/tab_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/tab_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/tab_button_03.sub",
                    "text" : uiScriptLocale.MAILBOX_COMPOSE_TAB,
                },

                # ----- Left pane: post list -----
                {
                    "name" : "list_thinboard",
                    "type" : "thinboard",
                    "x" : 14,
                    "y" : 70,
                    "width" : 240,
                    "height" : 360,
                },
                # Post buttons inserted programmatically by __BuildPostList().

                # ----- Pagination under list -----
                {
                    "name" : "page_prev_button",
                    "type" : "button",
                    "x" : 14,
                    "y" : 436,
                    "text" : "<",
                    "default_image" : "d:/ymir work/ui/public/small_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/small_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/small_button_03.sub",
                },
                {
                    "name" : "page_next_button",
                    "type" : "button",
                    "x" : 224,
                    "y" : 436,
                    "text" : ">",
                    "default_image" : "d:/ymir work/ui/public/small_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/small_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/small_button_03.sub",
                },
                {
                    "name" : "page_label",
                    "type" : "text",
                    "x" : 110,
                    "y" : 440,
                    "text" : "",
                    "horizontal_align" : "center",
                    "not_pick" : 1,
                },

                # ----- Right pane: read detail -----
                {
                    "name" : "read_thinboard",
                    "type" : "thinboard",
                    "x" : 264,
                    "y" : 70,
                    "width" : 322,
                    "height" : 360,
                },
                {
                    "name" : "read_sender_label",
                    "type" : "text",
                    "x" : 280,
                    "y" : 84,
                    "text" : "",
                    "not_pick" : 1,
                },
                {
                    "name" : "read_title_label",
                    "type" : "text",
                    "x" : 280,
                    "y" : 106,
                    "text" : "",
                    "not_pick" : 1,
                },
                {
                    "name" : "read_body_text",
                    "type" : "text",
                    "x" : 280,
                    "y" : 132,
                    "text" : "",
                    "all_align" : "center",
                    "not_pick" : 1,
                },
                {
                    "name" : "read_attachment_slot",
                    "type" : "slot",
                    "x" : 286,
                    "y" : 360,
                    "width" : 32,
                    "height" : 32,
                    "slot" : ((0, 0, 0, 1, 1),),
                },

                # ----- Action buttons (right pane) -----
                {
                    "name" : "delete_button",
                    "type" : "button",
                    "x" : 410,
                    "y" : 436,
                    "text" : uiScriptLocale.MAILBOX_DELETE_BUTTON,
                    "default_image" : "d:/ymir work/ui/public/middle_button_01.sub",
                    "over_image" : "d:/ymir work/ui/public/middle_button_02.sub",
                    "down_image" : "d:/ymir work/ui/public/middle_button_03.sub",
                },
                {
                    "name" : "reply_button",
                    "type" : "button",
                    "x" : 502,
                    "y" : 436,
                    "text" : uiScriptLocale.MAILBOX_REPLY_BUTTON,
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

`pack/pack/root/uimailbox.py`:

```python
import ui
import net
import app
import chat
import item
import mouseModule
import localeInfo
import uiScriptLocale
import constInfo
from _weakref import proxy

POSTS_PER_PAGE = 8

TAB_INBOX = 0
TAB_SENT = 1
TAB_COMPOSE = 2


class Post(ui.Window):
    """One left-pane post-button summary widget."""

    def __init__(self, parent, rowIndex, clickCallback):
        ui.Window.__init__(self)
        self.SetParent(parent)
        self.rowIndex = rowIndex
        self.dataIndex = -1
        self.clickCallback = clickCallback
        self.button = ui.Button()
        self.button.SetParent(self)
        self.button.SetUpVisual("d:/ymir work/ui/public/parameter_slot_03.sub")
        self.button.SetOverVisual("d:/ymir work/ui/public/parameter_slot_03.sub")
        self.button.SetDownVisual("d:/ymir work/ui/public/parameter_slot_03.sub")
        self.button.SetEvent(lambda r=proxy(self): r.OnClick())
        self.button.Show()

    def __del__(self):
        ui.Window.__del__(self)

    def OnClick(self):
        if self.clickCallback is not None:
            self.clickCallback(self.rowIndex)

    def SetDataIndex(self, dataIndex):
        self.dataIndex = dataIndex

    def SetSummary(self, sender, title):
        text = "%s: %s" % (sender, title)
        self.button.SetText(text)

    def Clear(self):
        self.dataIndex = -1
        self.button.SetText("")


class MailboxWindow(ui.ScriptWindow):

    def __init__(self):
        ui.ScriptWindow.__init__(self)
        self.__Initialize()
        self.__LoadWindow()

    def __del__(self):
        ui.ScriptWindow.__del__(self)

    def __Initialize(self):
        # Tab strip
        self.tabInboxButton = None
        self.tabSentButton = None
        self.tabComposeButton = None
        self.activeTab = TAB_INBOX

        # Left pane
        self.listBoard = None
        self.postRows = []          # Post widgets (built once)
        self.pagePrevButton = None
        self.pageNextButton = None
        self.pageLabel = None

        # Right pane
        self.readBoard = None
        self.readSenderLabel = None
        self.readTitleLabel = None
        self.readBodyText = None
        self.readAttachmentSlot = None
        self.deleteButton = None
        self.replyButton = None

        # State
        self.postIdList = []        # ordered list of message ids from server
        self.postDataDict = {}      # id -> {sender, title, body, attachmentVnum, ...}
        self.selectedPostId = -1
        self.currentPage = 0
        self.totalPages = 0
        self.isLoadPending = False
        self.isSendPending = False
        self.attachmentVnum = 0
        self.attachmentSlotIndex = -1
        self.tooltipItem = None
        self.confirmDialog = None

    def __LoadWindow(self):
        try:
            self.LoadScriptFile("uiscript/mailbox.py")
        except:
            import exception
            exception.Abort("MailboxWindow.__LoadWindow.LoadScriptFile")

        try:
            self.tabInboxButton = self.GetChild("tab_inbox_button")
            self.tabSentButton = self.GetChild("tab_sent_button")
            self.tabComposeButton = self.GetChild("tab_compose_button")
            self.listBoard = self.GetChild("list_thinboard")
            self.pagePrevButton = self.GetChild("page_prev_button")
            self.pageNextButton = self.GetChild("page_next_button")
            self.pageLabel = self.GetChild("page_label")
            self.readBoard = self.GetChild("read_thinboard")
            self.readSenderLabel = self.GetChild("read_sender_label")
            self.readTitleLabel = self.GetChild("read_title_label")
            self.readBodyText = self.GetChild("read_body_text")
            self.readAttachmentSlot = self.GetChild("read_attachment_slot")
            self.deleteButton = self.GetChild("delete_button")
            self.replyButton = self.GetChild("reply_button")
        except:
            import exception
            exception.Abort("MailboxWindow.__LoadWindow.BindObject")

        self.tabInboxButton.SetEvent(ui.__mem_func__(self.OnSelectTabInbox))
        self.tabSentButton.SetEvent(ui.__mem_func__(self.OnSelectTabSent))
        self.tabComposeButton.SetEvent(ui.__mem_func__(self.OnSelectTabCompose))
        self.pagePrevButton.SetEvent(ui.__mem_func__(self.OnPrevPage))
        self.pageNextButton.SetEvent(ui.__mem_func__(self.OnNextPage))
        self.deleteButton.SetEvent(ui.__mem_func__(self.OnDelete))
        self.replyButton.SetEvent(ui.__mem_func__(self.OnReply))

        # Pre-allocate post rows (row-pool refresh; never destroy + recreate
        # per refresh -- failure-atlas entry 26).
        for index in range(POSTS_PER_PAGE):
            row = Post(self.listBoard, index, self.OnClickPost)
            row.SetPosition(8, 8 + index * 40)
            row.SetSize(224, 36)
            row.Hide()
            self.postRows.append(row)

    # ---- Lifecycle ----

    def Open(self):
        self.SetCenterPosition()
        self.SetTop()
        self.Show()
        self.RequestMailList()

    def Close(self):
        self.Hide()
        # Tell the server we are no longer tracking the inbox.
        # TODO: verify net.SendMailBoxClose exists in your fork (bindings.md).
        net.SendMailBoxClose()
        self.__ClearReadPane()
        self.selectedPostId = -1

    def OnPressEscapeKey(self):
        self.Close()
        return True

    @ui.WindowDestroy
    def Destroy(self):
        if self.tabInboxButton:
            self.tabInboxButton.SetEvent(0)
        if self.tabSentButton:
            self.tabSentButton.SetEvent(0)
        if self.tabComposeButton:
            self.tabComposeButton.SetEvent(0)
        if self.pagePrevButton:
            self.pagePrevButton.SetEvent(0)
        if self.pageNextButton:
            self.pageNextButton.SetEvent(0)
        if self.deleteButton:
            self.deleteButton.SetEvent(0)
        if self.replyButton:
            self.replyButton.SetEvent(0)
        if self.confirmDialog:
            self.confirmDialog.Close()
        self.postRows = []
        self.ClearDictionary()
        self.__Initialize()

    # ---- Tab dispatch ----

    def OnSelectTabInbox(self):
        self.activeTab = TAB_INBOX
        self.RequestMailList()

    def OnSelectTabSent(self):
        self.activeTab = TAB_SENT
        self.RequestMailList()

    def OnSelectTabCompose(self):
        self.activeTab = TAB_COMPOSE
        self.__ShowComposeUI()

    # ---- List flow ----

    def RequestMailList(self):
        if self.isLoadPending:
            return
        self.isLoadPending = True
        # TODO: verify net.SendMailListRequest exists in your fork (bindings.md).
        net.SendMailListRequest(self.activeTab)

    def OnRecvMailList(self, ids):
        # Called externally by network module's Recv handler (15-network-
        # coupled-flow). Server pushes the ordered id list; client requests
        # detail per-id on click.
        self.postIdList = list(ids) if ids else []
        if POSTS_PER_PAGE > 0:
            self.totalPages = (len(self.postIdList) + POSTS_PER_PAGE - 1) // POSTS_PER_PAGE
        else:
            self.totalPages = 0
        self.currentPage = 0
        self.isLoadPending = False
        self.RefreshList()

    def RefreshList(self):
        start = self.currentPage * POSTS_PER_PAGE
        end = start + POSTS_PER_PAGE
        visibleIds = self.postIdList[start:end]

        for index, row in enumerate(self.postRows):
            if index < len(visibleIds):
                postId = visibleIds[index]
                summary = self.postDataDict.get(postId)
                if summary is not None:
                    row.SetDataIndex(postId)
                    row.SetSummary(summary.get("sender", ""), summary.get("title", ""))
                else:
                    row.SetDataIndex(postId)
                    row.SetSummary("", "")
                row.Show()
            else:
                row.Clear()
                row.Hide()

        if self.totalPages > 0:
            self.pageLabel.SetText("%d / %d" % (self.currentPage + 1, self.totalPages))
        else:
            self.pageLabel.SetText("")

    def OnPrevPage(self):
        if self.currentPage > 0:
            self.currentPage -= 1
            self.RefreshList()

    def OnNextPage(self):
        if (self.currentPage + 1) < self.totalPages:
            self.currentPage += 1
            self.RefreshList()

    # ---- Read flow ----

    def OnClickPost(self, rowIndex):
        absoluteIndex = self.currentPage * POSTS_PER_PAGE + rowIndex
        if absoluteIndex < 0 or absoluteIndex >= len(self.postIdList):
            return
        postId = self.postIdList[absoluteIndex]
        self.selectedPostId = postId
        # If we already have details cached, render immediately; otherwise
        # request server detail.
        if postId in self.postDataDict and "body" in self.postDataDict[postId]:
            self.RefreshReadPane()
        else:
            # TODO: verify net.SendMailRead exists in your fork (bindings.md).
            net.SendMailRead(postId)

    def OnRecvMailDetail(self, postId, sender, title, body, attachmentVnum):
        self.postDataDict[postId] = {
            "sender": sender,
            "title": title,
            "body": body,
            "attachmentVnum": attachmentVnum,
        }
        if postId == self.selectedPostId:
            self.RefreshReadPane()
        else:
            # Detail arrived for a non-current selection (user clicked a
            # different post mid-flight); refresh the list cell so the
            # summary has the title shown.
            self.RefreshList()

    def RefreshReadPane(self):
        if self.selectedPostId < 0:
            self.__ClearReadPane()
            return
        data = self.postDataDict.get(self.selectedPostId)
        if data is None:
            self.__ClearReadPane()
            return
        self.readSenderLabel.SetText(localeInfo.MAILBOX_RECIPIENT_LABEL + " " + data.get("sender", ""))
        self.readTitleLabel.SetText(localeInfo.MAILBOX_TITLE_LABEL + " " + data.get("title", ""))
        self.readBodyText.SetText(data.get("body", ""))
        self.attachmentVnum = data.get("attachmentVnum", 0)
        if self.attachmentVnum > 0:
            self.readAttachmentSlot.Show()
        else:
            self.readAttachmentSlot.Hide()

    def __ClearReadPane(self):
        if self.readSenderLabel:
            self.readSenderLabel.SetText("")
        if self.readTitleLabel:
            self.readTitleLabel.SetText("")
        if self.readBodyText:
            self.readBodyText.SetText("")
        if self.readAttachmentSlot:
            self.readAttachmentSlot.Hide()
        self.attachmentVnum = 0

    # ---- Action flow ----

    def OnDelete(self):
        if self.selectedPostId < 0:
            return
        # TODO: verify net.SendMailDelete exists in your fork (bindings.md).
        net.SendMailDelete(self.selectedPostId)

    def OnReply(self):
        if self.selectedPostId < 0:
            return
        self.activeTab = TAB_COMPOSE
        self.__ShowComposeUI(replyTo=self.selectedPostId)

    def OnSendMail(self, recipient, title, body):
        if self.isSendPending:
            return
        self.isSendPending = True
        # Critical: do NOT detach a mouse-attached attachment item before the
        # server confirms (failure-atlas entry 25). Detach is delayed until
        # OnRecvMailSent.
        # TODO: verify net.SendMailWrite exists in your fork (bindings.md).
        net.SendMailWrite(recipient, title, body)

    def OnRecvMailSent(self, success):
        self.isSendPending = False
        if success:
            if mouseModule.mouseController.isAttached():
                mouseModule.mouseController.DeattachObject()
            self.activeTab = TAB_INBOX
            self.RequestMailList()
        else:
            chat.AppendChat(chat.CHAT_TYPE_INFO, localeInfo.MAILBOX_SEND_REJECTED)
            # Attachment stays attached -- user retries after fixing the
            # rejection cause (over-capacity, item-bound, etc.).

    def __ShowComposeUI(self, replyTo=-1):
        # Compose UI replaces the read pane content with editable fields.
        # Implementation-specific (depends on how your fork composes the
        # editline + body editbox); consult the augmented archetype's
        # Compose section if you split this into a separate window.
        pass
```

## Locale entries

```
MAILBOX_TITLE                Mailbox
MAILBOX_INBOX_TAB            Inbox
MAILBOX_SENT_TAB             Sent
MAILBOX_COMPOSE_TAB          Compose
MAILBOX_NO_MESSAGES          No messages.
MAILBOX_DELETE_BUTTON        Delete
MAILBOX_REPLY_BUTTON         Reply
MAILBOX_SEND_BUTTON          Send
MAILBOX_RECIPIENT_LABEL      From:
MAILBOX_TITLE_LABEL          Subject:
MAILBOX_BODY_LABEL           Body
MAILBOX_ATTACHMENT_LABEL     Attachment
MAILBOX_SEND_REJECTED        Send failed. The recipient may be over capacity.
```

## interfacemodule.py integration snippet

```python
import uimailbox

# Eager build is appropriate -- the mailbox is high-frequency in many forks.
self.wndMailbox = uimailbox.MailboxWindow()
self.wndMailbox.BindInterface(self)

def ToggleMailbox(self):
    if self.wndMailbox.IsShow():
        self.wndMailbox.Close()
    else:
        self.wndMailbox.Open()

# Recv dispatch (network module side)
def OnRecvMailList(ids):
    if interface.wndMailbox is not None:
        interface.wndMailbox.OnRecvMailList(ids)

def OnRecvMailDetail(postId, sender, title, body, attachmentVnum):
    if interface.wndMailbox is not None:
        interface.wndMailbox.OnRecvMailDetail(postId, sender, title, body, attachmentVnum)

def OnRecvMailSent(success):
    if interface.wndMailbox is not None:
        interface.wndMailbox.OnRecvMailSent(success)
```

## Common variations

### Variation 1: Preview-only mailbox (no compose tab)

Drop the Compose tab and the `OnSendMail` / `OnRecvMailSent` paths. Useful for read-only system-announcement readers.

### Variation 2: Multi-attachment grid

Replace the single `read_attachment_slot` with a `slotbar` of N slots. Maintain `self.attachmentVnums = [0] * N`. Recv detail payload returns a list. Send-mail compose tab supplies a parallel input grid.

### Variation 3: Auto-mark-read

When `OnClickPost` resolves, send `net.SendMailMarkRead(postId)` so the server flips the "unread" flag. Update `postDataDict[postId]["read"] = True` on Recv ack and update the post row's visual to "read" styling.

### Variation 4: Admin / GM broadcast inbox

Add a Compose tab variant that emits `net.SendMailBroadcast(title, body)` instead of `SendMailWrite(recipient, title, body)`. Gate the visibility of the broadcast button on `app.GetAccountUserName()` membership in an admin allowlist (or, more correctly, on a server-pushed "is-admin" flag delivered at login).

### Variation 5: Two-pane with vertical scrolling body

For long-body messages, swap the `read_body_text` text widget for a `ListBoxEx` with line-wrapped text rows. Cross-link: `widgets.md` text section for line-wrap behavior.

## Don't copy these obsolete bits

- **`Destroy(self): pass`** -- one survey source has the method as a literal `pass`. The anchor uses `@ui.WindowDestroy` plus an explicit body that clears event setters and calls `__Initialize()`. WOC nulls owned widget attrs before the body runs, so direct method calls on widgets need the `if self.X:` guard (Critical Rule 17).
- **Synchronous list refresh on Open without is-pending guard** -- `Open()` calls `Show()` then immediately renders rows from a stale `postDataDict`. If the server hasn't replied to the prior session's request, the user sees the previous session's posts. Use `isLoadPending` and request the list explicitly in `Open()`.
- **Missing post-button cleanup on list shrink** -- if the inbox shrinks (delete-all), some sources leave orphan post widgets visible because the row-pool walk only Shows the rows that have data. The anchor's `RefreshList` loop calls `Clear()` + `Hide()` on the surplus rows.
- **DeattachObject before server confirms (failure-atlas 25 candidate)** -- one common failure is `OnSendMail` calls `mouseModule.mouseController.DeattachObject()` immediately after `SendMailWrite`. If the server rejects, the attachment is gone but the item was not sent. Detach only after `OnRecvMailSent(success=True)`.
- **Storing the recipient EditLine value at compose-build time and reading it at send time without re-validation** -- recipient name validation must run on every Send (player-name format checks, length limits) so a partially-typed name doesn't raise a server-side parse error.
- **Bare bound methods on Post button events** -- `self.button.SetEvent(self.OnClick)` leaks `self` into every Post widget. The Post inner class uses `lambda r=proxy(self): r.OnClick()` to keep the widget's reference weak.
