# m2ui Anchors — Few-Shot Exemplars

Each anchor in this directory is a self-contained tutorial for one canonical Metin2 UI window type. When you need to generate a new window of type X, **read the matching anchor first** — copy its structure, swap the specifics for your case.

Anchors are extracted from a real Metin2 fork's `pack/pack/root/` and `pack/pack/uiscript/uiscript/` and normalized to current m2ui rules (Phase 1+ event matrix, locale strings, asset path discipline).

## Decision matrix — which anchor to load

| You're generating... | Read |
|----------------------|------|
| Modal yes/no/text dialog | `anchors/01-simple-dialog.md` |
| Window w/ board chrome + scrolling list of dynamic items | `anchors/02-board-with-list.md` |
| Form w/ list of radio-buttons + an Accept/Submit button | `anchors/03-list-selector.md` |
| Window with custom 9-slice bordered panels | `anchors/04-9slice-panel.md` |
| Any window that should be hidden behind a feature flag (`app.ENABLE_X`) | `anchors/05-feature-gated.md` |
| Inventory-style window using `SetItemToolTip` / `SetSkillToolTip` | `anchors/06-tooltip-bound.md` |

If your window doesn't match any anchor exactly, pick the closest, copy its skeleton, and swap the specifics. Do NOT invent layout from scratch — start from a working pattern.

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

## Cross-references

- Mental model (read FIRST for any new window) → `skills/m2ui/reference/mental-model.md`
- Callback wrapping (mandatory for every window) → `skills/m2ui/reference/event-binding.md`
- Widget catalog (when you need property names) → `skills/m2ui/reference/widgets.md`
