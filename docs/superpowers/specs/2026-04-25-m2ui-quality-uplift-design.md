# m2ui Quality Uplift — Design Spec

**Date:** 2026-04-25
**Status:** Draft, pending user approval
**Plugin:** `C:\Users\marty\.claude\plugins\local\m2ui` (current version 2.0.0)

## Goal

Identify and add the highest-leverage knowledge tweaks that massively improve LLM output quality for Metin2 client UI generation, beyond what the current m2ui skill already documents. Phased rollout: small/safe first, behavioral depth later.

## Audit context

Current skill state at time of audit:

| File | Lines | Purpose |
|------|-------|---------|
| `skills/m2ui/SKILL.md` | 82 | Mode dispatch + 15 critical rules |
| `skills/m2ui/reference/widgets.md` | 997 | 34 widget types |
| `skills/m2ui/reference/patterns.md` | 2727 | Code templates (already includes BAD/GOOD pairs) |
| `skills/m2ui/reference/bindings.md` | 1281 | C++ Python module catalog |
| `skills/m2ui/reference/locale.md` | 81 | Locale rules |
| `skills/m2ui/modes/{screenshot,talk,script,diagnose}.md` | 75-130 each | Per-mode workflows |
| `rules/m2ui-activate.md` | 64 | Source of truth, CI-synced to all other agent copies |

**Sample reference codebase:** `C:\Users\marty\Documents\git\_ETERCORE-PROJECT\asf-v5-ex-v5.9-patched\pack\pack`
**Real ymir asset root:** `D:\ymir work\ui\`

**Audit method:** Self-review by Claude (this session) + independent audit by OpenAI Codex CLI via `/askcodex` skill. Both agents read plugin dir and sample pack. Findings merged.

## Confirmed gaps

| # | Gap | Source |
|---|-----|--------|
| 1 | No pre-generation self-review gate (diagnose runs after, not before emit) | Claude + Codex |
| 2 | No idiom translation layer (web/React mental model → ymir engine) | Claude + Codex |
| 3 | No behavioral failure atlas (symptom → root cause decision trees) | Claude + Codex |
| 4 | No few-shot canonical anchor windows | Claude + Codex |
| 6 | No fork delta notes (vanilla vs ASF vs ETERCORE vs 40k) | Claude + Codex |
| 7 | No Metin2-native visual/UX convention guide | Claude + Codex |
| 8 | Modes don't enforce inline self-review before file write | Claude + Codex |
| B | Reference overload — full patterns.md (2727 lines) + widgets.md (997) loaded every gen | Codex |
| C | Event setter matrix missing — current rule "ui.__mem_func__ no exceptions" is wrong about `SAFE_SetEvent` | Codex |
| D | No asset existence discipline — model invents image paths instead of checking `D:\ymir work\ui\` | Codex |
| E | No "don't invent unverified APIs" rule — model fabricates `net.X` / `player.X` calls | Codex |

## Rejected hypotheses

- **#5 BAD/GOOD paired snippets:** Codex verified `patterns.md` already contains WRONG/CORRECT pairs for callbacks/cleanup/Python traps. Not needed.

## Out of scope (explicit)

- **Gap A (stale `plugins/m2ui/SKILL.md` drift):** GitHub Action will fix. User confirmed.
- New paired snippets in patterns.md (already covered).
- Automated test harness for skill prompts (separate project).
- New modes (explain, refactor): different brainstorm.
- Programmatic asset-check CLI tool (agent's Glob is sufficient).

---

## Approach: Phased rollout

Three phases, each = own design + plan + PR(s). This spec covers all three at design level; only Phase 1 detailed enough to plan immediately. Phases 2+3 sketched; their plans get written when prior phase ships.

| Phase | Effort | Ship version | Rationale |
|-------|--------|--------------|-----------|
| 1 — Pre-emit gate + correctness | ~1 day | 2.1.0 | Smallest input, immediate quality jump on every future generation |
| 2 — Mental model + anchors + router | ~3-5 days | 2.2.0 | Changes how model thinks before writing line one |
| 3 — Failure atlas + fork deltas + visual | ~5-7 days | 2.3.0 | Larger effort, polish + behavioral depth |

---

## Phase 1 — Pre-emit gate + correctness

### 1.1 Pre-Emit Gate (gaps #1, #8)

**Where:** New `## Pre-Emit Self-Review` section in SKILL.md + 4-line invocation in `modes/talk.md`, `modes/screenshot.md`, `modes/script.md`.

**Shape:** ~20-line checklist agent runs *silently* before file write or code display. Failed item → revise, don't emit. Single pass, no user-visible output unless gate trips.

**Checklist items:**

1. `@ui.WindowDestroy` on every Destroy
2. All `self.X` assignments listed in Initialize
3. Every callback wrapped (`ui.__mem_func__` OR `SAFE_SetEvent` OR no-self lambda)
4. `OnPressEscapeKey` returns True/False
5. All user-visible strings via locale module
6. All decorative elements have `not_pick`
7. Parent bounds contain all interactive children
8. Z-order = back-to-front SetParent order
9. Image paths verified to exist in `D:\ymir work\ui\` (or noted as TBD)
10. C++ API calls verified in `bindings.md` (or noted as stub)
11. Python 2.7 compat (`//` not `/`, `in` not `has_key`, `xrange`)
12. uiscript dict name == root file's `LoadScriptFile` arg
13. Script-backed: `ClearDictionary()` in Destroy
14. `__del__` calls `ui.ScriptWindow.__del__(self)`

### 1.2 Event setter matrix (gap C)

**Where:** Replace SKILL.md rules #5+#6 with single matrix pointer. Add expanded section in new `reference/event-binding.md`.

| Pattern | Safe? | When to use |
|---------|-------|-------------|
| `btn.SetEvent(ui.__mem_func__(self.OnClick))` | yes | Default for self-referencing callbacks |
| `btn.SAFE_SetEvent(self.OnClick)` | yes | When fork provides it (auto-wraps); shorter |
| `btn.SetEvent(self.OnClick)` | **no** | Leak — bare bound method |
| `btn.SetEvent(lambda: self.OnClick())` | **no** | Leak — lambda captures self |
| `btn.SetEvent(lambda r=proxy(self): r.OnClick())` | yes | Only acceptable lambda+self pattern |
| `btn.SetEvent(SomeFreeFunction)` | yes | No `self` ref → no leak risk |

**SAFE_SetEvent caveat:** Check if fork defines it (grep `def SAFE_SetEvent` in pack root before recommending — note in skill).

### 1.3 Asset existence discipline (gap D)

**Where:** New rule in SKILL.md + 3-line gate in Pre-Emit checklist (item #9).

**Rule:** Before referencing any image path (`d:/ymir work/ui/...`), verify file exists via Glob. If user-supplied design needs new asset, emit `# TBD ASSET: path/name.tga — needs creation` comment instead of inventing. Asset root = `D:\ymir work\ui\` (configurable via project setting later).

### 1.4 API anti-hallucination rule (gap E)

**Where:** New rule in SKILL.md.

**Rule:** Before calling any C++ Python module function (`net.X`, `player.X`, `item.X`, `chr.X`, `app.X`, `wndMgr.X`, `chat.X`, `quest.X`), verify in `reference/bindings.md`. If absent: (a) ask user if function exists in their fork, OR (b) emit stub with `# TODO: verify <module>.<func> exists in your fork` comment. Never invent.

### Phase 1 deliverables

| File | Action | Est lines |
|------|--------|-----------|
| `skills/m2ui/SKILL.md` | Edit: add Pre-Emit section, replace rules 5-6 w/ matrix pointer, add asset + API rules | +50 net |
| `rules/m2ui-activate.md` | Mirror SKILL.md changes (CI syncs other copies) | +50 net |
| `skills/m2ui/modes/talk.md` | Add Pre-Emit invocation | +5 |
| `skills/m2ui/modes/screenshot.md` | Add Pre-Emit invocation | +5 |
| `skills/m2ui/modes/script.md` | Add Pre-Emit invocation | +5 |
| `skills/m2ui/reference/event-binding.md` | New file w/ event matrix | ~80 |
| `skills/m2ui/reference/patterns.md` | Add cross-link to event-binding.md at top of "Callbacks" section; remove inline ui.__mem_func__ lecture (now in event-binding.md) | -20 net |

**Note on "Mirror" actions:** `rules/m2ui-activate.md` is the CI source of truth that propagates to `.cursor/rules/`, `.windsurf/rules/`, `.clinerules/`, `.github/copilot-instructions.md`, and `plugins/m2ui/skills/m2ui/SKILL.md`. "Mirror SKILL.md changes" = re-apply the same textual edit to `m2ui-activate.md` in the same PR. Hand-editing other copies is forbidden.

### Phase 1 success criteria

- Generated code from talk/screenshot modes always passes diagnose checklist on first run
- No fabricated image paths or API calls in generation output
- `SAFE_SetEvent` recognized as valid (not flagged by diagnose anymore)

---

## Phase 2 — Mental model + anchors + router

### 2.1 `reference/mental-model.md` (gap #2)

**Purpose:** Deprogram web/React assumptions BEFORE generation. ~150-250 lines, dense.

**Sections:**

1. **Layout model** — No flex/grid/stack. Absolute coords from parent origin (0,0 = top-left). No auto-resize. Padding/margin = manual offsets. "Centering" = `(parent_w - child_w) // 2`.

2. **Component model** — No reusable components. Each window = own root class. Composition via `InsertChild()`. "Props" = constructor args + setter methods. No render() — UI built once in `__LoadDialog` or via `LoadScriptFile`.

3. **State model** — No reactive state. State = instance vars. Updates = explicit widget setter calls. List rerender = clear children + rebuild loop, OR pool widgets + reassign data.

4. **Event model** — No bubbling/delegation. Single callback per event per widget. Mouse picking respects parent bounds + `not_pick` flag + z-order.

5. **Lifecycle model** — Manual `Initialize` / `Destroy` / `Open` / `Close`. `OnUpdate` = per-frame tick (NOT React effect). Use sparingly.

6. **Asset model** — No imports/bundler. Reference disk paths directly. Asset = .tga / .dds / .sub / .ttf. 9-slice borders use `expanded_image` widget + 9 corner/edge tiles.

7. **Translation table:**

| Web/React idiom | ymir equivalent |
|-----------------|-----------------|
| `<div className="card">` | `Window` w/ `expanded_image` background |
| `flex` row | manual x-offset accumulator |
| `useState(x)` | `self.x = x` + setter that updates widget |
| `onClick={fn}` | `btn.SetEvent(ui.__mem_func__(self.fn))` |
| `useEffect` | OnUpdate (per-frame!) or manual call after state change |
| `<img src="..." />` | `image` widget w/ `image` key = disk path |
| `display: none` | `widget.Hide()` |
| `z-index: 99` | SetParent call order; or `SetTop()` w/ `"float"` flag |
| component composition | `parent.InsertChild(child)` + `child.SetParent(parent)` |
| controlled input | `EditLine` w/ `SetText`/`GetText` + change callback |

### 2.2 Canonical anchor windows (gap #4)

**Purpose:** Few-shot exemplars. When generating new window of type X, read matching anchor first.

**Where:** New `skills/m2ui/reference/anchors/` dir. Each anchor = self-contained tutorial file.

**Anchor list (Codex picks, validated):**

| File | Anchor type | Source pack file | Demonstrates |
|------|-------------|------------------|--------------|
| `anchors/01-simple-dialog.md` | Modal yes/no/text dialog | `systemdialog.py` | Lifecycle, OK/cancel, locale, Open/Close |
| `anchors/02-board-with-list.md` | Board + scrolling dynamic list | `cuberenewalwindow.py` | Board chrome, scrollbar, dynamic row creation |
| `anchors/03-search-form.md` | Multi-input form w/ submit | `privateshopsearchdialog.py` | EditLine, ComboBox, validation, submit chain |
| `anchors/04-9slice-panel.md` | Custom 9-slice border container | `worldbosswindow.py` | expanded_image tiling, parent bounds, asset refs |
| `anchors/05-feature-gated.md` | Window guarded by `app.ENABLE_*` | `systemdialog.py` variant | Feature-flag pattern, conditional integration |
| `anchors/06-tooltip-bound.md` | Window using SetItemToolTip / SetSkillToolTip | `inventorywindow.py` slice | Tooltip wiring, BindInterface |

**Anchor file shape:**
- 1-paragraph "what this is + when to use it"
- Full uiscript dict (normalized to current rules — `//` not `/`, no lambda-self)
- Full root class (normalized — SAFE_SetEvent or `ui.__mem_func__`, full lifecycle)
- Locale entries needed
- Integration snippet for `interfacemodule.py`
- "Common variations" list (3-5 swaps)
- "Don't copy these obsolete bits" callout (pointing at sample-pack drift)

**Index file:** `anchors/README.md` w/ matrix: "Generating type X? Read anchor Y."

### 2.3 Decision-matrix router (gap B)

**Where:** Replace SKILL.md "Before Generating Any Code" section.

```markdown
## Before Generating

Always load: SKILL.md (this file), reference/mental-model.md.

Conditional load:

| Generating | Load |
|-----------|------|
| Any window | reference/event-binding.md |
| New window from scratch | matching anchor from reference/anchors/ |
| Specific widget you haven't used recently | reference/widgets.md (just that section) |
| Locale-heavy work | reference/locale.md |
| Calling C++ API not in context | reference/bindings.md (grep for the function) |
| Patterns reminder | reference/patterns.md (just relevant section) |
```

### Phase 2 deliverables

| File | Action | Est lines |
|------|--------|-----------|
| `skills/m2ui/reference/mental-model.md` | New | ~200 |
| `skills/m2ui/reference/anchors/README.md` | New (index + decision matrix) | ~50 |
| `skills/m2ui/reference/anchors/01-simple-dialog.md` | New | ~120 |
| `skills/m2ui/reference/anchors/02-board-with-list.md` | New | ~180 |
| `skills/m2ui/reference/anchors/03-search-form.md` | New | ~150 |
| `skills/m2ui/reference/anchors/04-9slice-panel.md` | New | ~130 |
| `skills/m2ui/reference/anchors/05-feature-gated.md` | New | ~100 |
| `skills/m2ui/reference/anchors/06-tooltip-bound.md` | New | ~140 |
| `skills/m2ui/SKILL.md` | Edit "Before Generating" → router | +30 net |
| `rules/m2ui-activate.md` | Mirror | +30 net |

### Phase 2 success criteria

- New windows match the structural shape of equivalent anchor (no ad-hoc layouts)
- No more flex/grid/state-machine thinking in generated code
- Context usage per generation drops (router only loads relevant refs)

---

## Phase 3 — Failure atlas + fork deltas + visual conventions

### 3.1 `reference/failure-atlas.md` (gap #3)

**Purpose:** Symptom-first decision trees. User reports "X looks broken on screen" → atlas maps to root cause → fix.

**Where:** New `skills/m2ui/reference/failure-atlas.md` (~250-350 lines).

**Content shape:** Each entry = symptom heading + ranked root-cause checklist + fix snippet.

**Entries (draft):**

1. "Window doesn't appear" — Show() missing, parent.Hide(), x/y off-screen, z-buried, LoadScriptFile path wrong
2. "Click goes through / nothing happens" — decorative parent missing not_pick, button outside parent bounds, SetEvent never called, hidden but listening, wrong z-order
3. "Memory leak / crashes after closing N times" — missing @ui.WindowDestroy, bare bound method, lambda captures self, ChildWindow on self never released
4. "OnPressEscapeKey crashes during child iteration" — missing return
5. "Text/locale shows as raw key string" — localeInfo.X missing, wrong locale module, hardcoded in uiscript
6. "Image shows as red X / pink box" — asset path wrong, wrong format, 9-slice corner sizes mismatch
7. "Scrollbar doesn't scroll / scrolls wrong range" — content height not set, OnMouseWheel missing return
8. "Layout breaks at certain resolution" — hardcoded coord, window not re-centered on resize
9. "Tooltip stuck after window close" — tooltip not Hide()'d in Close()
10. "EditLine input goes nowhere after close" — KillFocus not called
11. "Feature shows in vanilla but not in fork" — feature flag check missing, wrong flag name (see fork-deltas.md)
12. "Window opens then immediately closes" — net packet sent every frame from OnUpdate, distance check failing

### 3.2 `reference/fork-deltas.md` (gap #6)

**Purpose:** Behavior matrix across vanilla / ASF / ETERCORE / 40k. Prevents emitting vanilla idioms in fork codebase.

**Where:** New `skills/m2ui/reference/fork-deltas.md` (~150-200 lines).

**Detection section:** How agent identifies which fork it's in:
- Glob for fork-specific feature flags in `app.py` / `constInfo.py`
- Check for `SAFE_SetEvent` definition
- Check for ENABLE_* flags unique to each fork
- Read project README/CLAUDE.md if present

**Delta matrix (draft columns):**

| Feature | Vanilla | ASF | ETERCORE | 40k |
|---------|---------|-----|----------|-----|
| `SAFE_SetEvent` | absent | present | present | present |
| Clip mask (`app.__BL_CLIP_MASK__`) | absent | present | present | varies |
| Cube renewal window | absent | present | present | absent |
| Aura system | absent | present | present | varies |
| Acce slot (extra equip) | absent | present | present | varies |
| Dragon Soul refine | present | extended | extended | extended |
| Feature-flag style | none | `app.ENABLE_X` | `app.ENABLE_X` | `app.WJ_ENABLE_X` |
| Locale module split | localeInfo | +uiScriptLocale | +uiScriptLocale | +uiScriptLocale |
| Inventory page count | 4 | 4-6 | 4-6 | 6-9 |
| Dialog naming | uiCommon | uiCommon + custom | uiCommon + custom | varies |

Specific deltas need pack-side verification during Phase 3 plan execution. This spec captures the structure; row content fleshed out in plan.

### 3.3 `reference/visual-conventions.md` (gap #7)

**Purpose:** Native Metin2 visual vocabulary. Stops generic "modern UI" output.

**Where:** New `skills/m2ui/reference/visual-conventions.md` (~150-200 lines).

**Sections:**

1. **Window archetypes** — Standard board, slim dialog, inventory grid, list-with-detail, slot picker, notification toast (with typical sizes)
2. **Standard chrome elements** — Board background asset, close button family + 11x11 size, titlebar font, padding (8px outer, 4px inner)
3. **Slot conventions** — Item slot 32x32, equipment 32x96/32x64, skill 32x32, quickslot 32x32
4. **Color palette** — Title gold `0xFFFFCE9C`, standard text `0xFFFFFFFF`, disabled `0xFF888888`, error red `0xFFFF4444`, highlight `0xFFFFFF00`
5. **Asset vocabulary** — "Board", "ThinBoard", "ExpandedImage", "ImageBox", "AniImage" definitions
6. **Anti-patterns (visual)** — Modern flat aesthetic, custom font weights, drop shadows/blurs, gradients, large rounded corners

### Phase 3 deliverables

| File | Action | Est lines |
|------|--------|-----------|
| `skills/m2ui/reference/failure-atlas.md` | New | ~300 |
| `skills/m2ui/reference/fork-deltas.md` | New | ~180 |
| `skills/m2ui/reference/visual-conventions.md` | New | ~180 |
| `skills/m2ui/SKILL.md` | Edit router to include atlas + fork + visual | +15 net |
| `rules/m2ui-activate.md` | Mirror | +15 net |
| `skills/m2ui/modes/diagnose.md` | Add cross-link to failure-atlas for symptom-mode | +10 |

### Phase 3 success criteria

- User reports "X looks wrong" → agent navigates atlas instead of guessing
- Generated code matches detected fork's idioms (no SAFE_SetEvent suggestion in vanilla)
- New windows look native (chrome, palette, sizing) instead of generic flat UI

---

## Cross-cutting

### CI sync

`rules/m2ui-activate.md` is source of truth → CI propagates to:
- `.cursor/rules/m2ui.mdc`
- `.windsurf/rules/m2ui.md`
- `.clinerules/m2ui.md`
- `.github/copilot-instructions.md`
- `plugins/m2ui/skills/m2ui/SKILL.md` (per user note: GitHub Action handles drift)

**Implication:** Edit `rules/m2ui-activate.md` only; never hand-edit copies. Each phase PR mirrors SKILL.md changes into `m2ui-activate.md` as paired commits.

**New ref files** (mental-model.md, anchors/*, failure-atlas.md, etc) live under `skills/m2ui/reference/` only — agents read them via path, not via rule sync. Phase 1 plan task: verify CI workflow handles new file additions; extend if not.

### Version bumps

Current: 2.0.0 (per `gemini-extension.json`).

| Phase | Version |
|-------|---------|
| Phase 1 ship | 2.1.0 |
| Phase 2 ship | 2.2.0 |
| Phase 3 ship | 2.3.0 |

Update locations: `gemini-extension.json`, plugin manifests in `.claude-plugin/` and `plugins/m2ui/.codex-plugin/`.

### Testing

No automated test harness exists for skill content (it's prompts, not code).

**Manual test protocol per phase:**

1. **Pre-phase baseline:** generate a known window type via current skill, save output.
2. **Post-phase regen:** same prompt, new skill version, save output.
3. **Diff + diagnose:** run diagnose mode on both. Phase passes if new output has fewer/zero issues vs baseline.
4. **Fresh-prompt eval:** 3 new prompts agent hasn't seen. Outputs reviewed manually for shape/correctness.

**Phase-specific:**
- Phase 1: verify Pre-Emit Gate trips on known-bad input (intentionally broken prompt), agent self-corrects before emit.
- Phase 2: verify router loads only relevant refs (inspect tool calls).
- Phase 3: ask "my window doesn't show" → verify agent walks atlas, doesn't guess.

### Rollout per phase

**Phase 1 (~1 day):** branch `phase1-pre-emit-gate`, 1 PR, manual test against 2-3 sample prompts, bump 2.1.0.

**Phase 2 (~3-5 days):** branch `phase2-mental-model-anchors`, 1 PR (or split: mental-model + anchors + router if too big). Anchor extraction = read sample-pack file, normalize to current rules, write tutorial. Bump 2.2.0.

**Phase 3 (~5-7 days):** branch `phase3-behavioral-depth`, 3 PRs likely (atlas / fork-deltas / visual) — each independently shippable. Fork-deltas needs hands-on pack inspection across 4 forks (or marked partial w/ user-fillable rows). Bump 2.3.0.

### Risks

| Risk | Mitigation |
|------|-----------|
| Pre-Emit Gate makes generation slower (extra silent pass) | Acceptable — quality > speed for this skill |
| Anchors get stale as fork conventions drift | Anchor files dated; include "last verified against pack vX" header |
| Fork-deltas matrix incomplete or wrong | Phase 3 plan ships partial matrix + invites user contributions |
| Router cuts too much context, agent misses edge cases | Conservative defaults: always load mental-model + event-binding + 1 anchor minimum |
| New ref files not synced to other agent copies | Phase 1 task: extend CI workflow to include `reference/` subtree or document path-based reads |

---

## Next step

After user approval of this spec → invoke `superpowers:writing-plans` to write a detailed implementation plan for Phase 1. Phases 2 and 3 get their own plans when prior phase ships.
