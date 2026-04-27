# m2ui Anchors — Few-Shot Exemplars

Each anchor in this directory is a self-contained tutorial for one canonical Metin2 UI window type. When you need to generate a new window of type X, **read the matching anchor first** — copy its structure, swap the specifics for your case.

Anchors are extracted from a real Metin2 fork's `pack/pack/root/` and `pack/pack/uiscript/uiscript/` and normalized to current m2ui rules (Phase 1+ event matrix, locale strings, asset path discipline).

## Decision tree — which anchors to load

Anchors split into two categories:

- **Primary archetypes** — chrome-defining, mutually exclusive, pick exactly ONE.
- **Augmentors** — chrome-agnostic behaviors layered on top of a primary, pick zero or more.

### Step 1 — pick ONE primary archetype

| Window type | Anchor |
|-------------|--------|
| Modal yes/no/text dialog | `01-simple-dialog.md` |
| Board chrome + scrolling DYNAMIC list | `02-board-with-list.md` |
| Form: list of radio-buttons + Accept | `03-list-selector.md` |
| Custom 9-slice bordered panel | `04-9slice-panel.md` |
| Inventory-style with `SetItemToolTip` / `SetSkillToolTip` | `06-tooltip-bound.md` |
| Shop / exchange / trade (slots + gold + Accept) | `07-shop-exchange.md` |
| Inventory / equipment grid (refresh / page / locked) | `08-inventory-equipment.md` |
| Options / settings (checkbox / slider / combo) | `09-options-settings.md` |
| Paginated slot grid (private-shop-builder style) | `10-paginated-slot-grid.md` |
| Quest / NPC dialog (server text + close-on-distance) | `11-quest-npc-dialog.md` |
| Storage / warehouse / mall (slots + password / gold) | `12-storage-warehouse.md` |
| Craft / refine / item-enhancement (cube, dragon-soul) | `13-craft-refine-window.md` |
| Search / filter dialog with results list | `17-search-filter-dialog.md` |
| Mailbox / message inbox (two-pane list+detail) | `18-mailbox-two-pane.md` |
| Daily reward grid / check-in calendar | `19-daily-reward-grid.md` |
| Leaderboard / rank table | `20-leaderboard-table.md` |
| Wheel / roulette / gacha | `21-wheel-roulette.md` |

No exact match → pick CLOSEST. Do NOT skip Step 1.

### Step 2 — pick zero or more augmentors

| Behavior | Anchor |
|----------|--------|
| Window guarded by `app.ENABLE_*` | `05-feature-gated.md` |
| Slot↔slot or slot↔window drag-and-drop | `14-drag-and-drop.md` |
| Driven by `net.Send` / `RecvX` packets | `15-network-coupled-flow.md` |
| Multiple panes switched by tabs / radios | `16-tabbed-content.md` |
| Compare-tooltip side-by-side | `22-compare-tooltip.md` |
| Auto-hide chrome on inactivity timer | `23-auto-hide-chrome.md` |

### Load order

Read the primary FIRST (ground truth for window chrome), then each augmentor in the order picked. Augmentors layer on top — they DO NOT override the primary's lifecycle/structure.

### Conflict tie-breaker

When two archetypes seem to fit, pick the one matching the window's CHROME (visual structure), not its DATA (data shape is augmentor territory). Example: "tabbed inventory" → primary `08-inventory-equipment` + augmentor `16-tabbed-content`; NOT `16-tabbed-content` alone.

### Special case: integration

`interfacemodule.py` integration is NOT an anchor (not a window archetype). After selecting primary + augmentors, every emission produces an integration snippet — see `skills/m2ui/reference/integration.md`.

## Anchor file structure (uniform across all anchors)

Every anchor follows the same section layout:

1. **What this is + when to use it** — 1 paragraph
2. **Source** — real fork file extracted from + normalization notes
3. **Uiscript dict** — full normalized dict (if script-backed)
4. **Root class** — full normalized `ui*.py` class
5. **Locale entries** — strings to append
6. **interfacemodule.py integration snippet** — how to wire into the main interface
7. **Common variations** — 3-5 small swaps for typical adaptations
8. **Don't copy these obsolete bits** — callouts where the source has stale patterns superseded by current rules

### Augmentor body-content convention

Augmentor anchors (`05-feature-gated`, `14-drag-and-drop`, `15-network-coupled-flow`, `16-tabbed-content`, `22-compare-tooltip`, `23-auto-hide-chrome`) follow the same 8-section format but put their body content in section 6 (interfacemodule.py integration snippet) OR section 7 (Common variations) depending on which is the natural home:

- **Body in section 6** — when the augmentor is primarily an integration-time wiring (e.g., 05-feature-gated wraps the `if app.ENABLE_X:` guard around the import + instance creation; 14-drag-and-drop attaches/detaches via mouseModule at integration sites)
- **Body in section 7** — when the augmentor is a state machine or call-flow that varies per consuming window (e.g., 15-network-coupled-flow's Send→Recv→setter trace; 16-tabbed-content's radio-group + Show/Hide variations per pane count)

Sections 3 (Uiscript dict) and 4 (Root class) in augmentors typically read "Same as augmented archetype" with a short note about the augmentor-specific decoration only.

Each augmentor's section 1 ("What this is + when to use it") MUST contain a line of the form `Body content lives in section 6.` or `Body content lives in section 7.` so agents (and the structural test) know where to look.

## Cross-references

- Mental model (read FIRST for any new window) → `skills/m2ui/reference/mental-model.md`
- Callback wrapping (mandatory for every window) → `skills/m2ui/reference/event-binding.md`
- Widget catalog (when you need property names) → `skills/m2ui/reference/widgets.md`
