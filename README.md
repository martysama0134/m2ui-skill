# /m2ui — Metin2 UI Code Generator

A skill for AI coding assistants that generates and modifies Metin2 client UI code. It works with screenshots, natural language descriptions, or existing scripts — and outputs correct, production-ready uiscript dicts, root `ui*.py` classes, and locale string entries.

## Supported Agents

m2ui works with all major AI coding tools. Each tool picks up the skill through its native integration mechanism:

| Agent | Mechanism | Auto-activates? |
|-------|-----------|-----------------|
| [Claude Code](https://claude.ai/code) | Plugin system (`/m2ui` skill) | Yes |
| [Codex](https://github.com/openai/codex) | Plugin in `plugins/m2ui/` | Yes |
| [Cursor](https://cursor.sh) | `.cursor/rules/m2ui.mdc` | Yes |
| [Windsurf](https://codeium.com/windsurf) | `.windsurf/rules/m2ui.md` | Yes |
| [Cline](https://github.com/cline/cline) | `.clinerules/m2ui.md` | Yes |
| [GitHub Copilot](https://github.com/features/copilot) | `.github/copilot-instructions.md` | Yes |
| [Gemini CLI](https://github.com/google-gemini/gemini-cli) | `GEMINI.md` extension | Yes |
| Any other agent | `AGENTS.md` at repo root | Read on demand |

All agents share the same reference documentation. The source of truth is `rules/m2ui-activate.md` — a CI workflow syncs it to each tool's native format automatically.

## Installation

### **Quick Install (recommended)**

Paste this to your AI agent:

```
Install the m2ui skill from https://github.com/martysama0134/m2ui-skill into my project. For Claude Code, register the repo as a marketplace via `/plugin marketplace add <path>` and then `/plugin install m2ui@m2ui` — the repo ships a ready-to-use `.claude-plugin/marketplace.json` so symlinking alone is NOT enough.
```

### Claude Code

Claude Code does **not** auto-discover plugins under `~/.claude/plugins/local/`. Plugins must be registered via a marketplace and then installed. This repo ships a ready-to-use marketplace descriptor at `.claude-plugin/marketplace.json` so the same clone serves as both marketplace and plugin source.

**Step 1 — clone the repo somewhere local:**

```bash
# Anywhere on disk; the path doesn't have to be ~/.claude/plugins/local/
git clone https://github.com/martysama0134/m2ui-skill.git /path/to/m2ui-skill
```

**Step 2 — register the marketplace in Claude Code:**

```
/plugin marketplace add /path/to/m2ui-skill
```

**Step 3 — install the plugin from that marketplace:**

```
/plugin install m2ui@m2ui
```

(The first `m2ui` is the plugin name; the second is the marketplace name declared in `.claude-plugin/marketplace.json`.)

**Step 4 — restart Claude Code** (or run `/reload-plugins`) to pick up the slash command and skill. Verify with `/help` — you should see `/m2ui` in the slash-command list.

To upgrade later: `git pull` in the cloned dir + restart Claude Code. The marketplace registration persists.

### Cursor / Windsurf / Cline / Copilot

These agents look for rule files at your **project root**. Copy the relevant directories from this repo into your Metin2 project:

```bash
# Clone the skill repo
git clone https://github.com/martysama0134/m2ui-skill.git /tmp/m2ui-skill

# Copy the rule files and reference docs to your project root
cp -r /tmp/m2ui-skill/.cursor /tmp/m2ui-skill/.windsurf /tmp/m2ui-skill/.clinerules your-project/
cp -r /tmp/m2ui-skill/.github/copilot-instructions.md your-project/.github/
cp -r /tmp/m2ui-skill/skills your-project/
```

Alternatively, add as a submodule at your project root and symlink the rule directories.

The rule files are thin pointers that tell the agent to read the full reference docs in `skills/m2ui/reference/`.

### Codex

The Codex plugin is in `plugins/m2ui/`. Point your Codex configuration to this directory.

### Gemini CLI

Install as a Gemini extension using `gemini-extension.json` at the repo root.

## Usage

### In Claude Code

m2ui exposes both a slash command and a Skill. They reach the same engine — the slash command is a thin entry point that delegates to the skill, which does the actual work. Use whichever feels natural:

**Slash command** (discoverable via `/help`):

```
/m2ui                              Interactive mode — asks what you want to do
/m2ui screenshot                   Analyze an attached image, generate matching UI code
/m2ui talk make a shop window      Describe a UI in plain language, get generated code
/m2ui script uimovechannel.py      Modify an existing UI file
/m2ui diagnose uixxx.py            Audit an existing UI file for memory leaks and anti-patterns
```

**Natural language** (the skill auto-activates from context):

```
use m2ui to make a shop window
m2ui screenshot: <attach image>
modify uimovechannel.py with m2ui
m2ui diagnose uixxx.py
audit my UI files with m2ui
```

The keywords (`m2ui`, `screenshot`, `diagnose`), plus a `.py` file reference, an attached image, or a plain text description drive auto-detection of the right mode (see [Auto-Detection](#auto-detection) below).

### In Other Agents

Just describe what you want in natural language. The agent will automatically read the reference docs and follow the m2ui rules:

- *"Create a new window with a title bar, three buttons, and a scrollable item list"*
- *"Add a search bar to the inventory window"*
- *"Here's a screenshot of a UI from another game — recreate it as Metin2 UI"*

### Auto-Detection

When no explicit mode is specified, the skill auto-detects from your input:

1. **Image attached** — screenshot mode (analyze and replicate)
2. **"check"/"audit"/"diagnose"/"find bugs"** — diagnose mode (audit for anti-patterns)
3. **References a `.py` file** — script mode (modify existing)
4. **Text description** — talk mode (generate new)
5. **No input** — interactive mode (asks what you want)

### Notes

- **Restart needed after updates.** When you upgrade m2ui (pull a new version, or land a SKILL.md / `commands/` / metadata change), quit and relaunch Claude Code so the new skill, slash commands, and metadata are picked up. Existing sessions keep the previously-loaded version. Verify a restart worked by checking the version in `.claude-plugin/plugin.json` against `/help` output.

- **Project scope.** The recommended Claude Code install is **global** (`~/.claude/plugins/local/m2ui` — junction on Windows, symlink on macOS/Linux), not per-project. The skill targets **client** code (`pack/pack/uiscript/`, `pack/pack/root/`); a server-only project will not auto-engage the skill unless client UI files are in scope. Other agents (Cursor / Windsurf / Cline / Copilot / Gemini) are project-scoped — copy the relevant rule files into the client project root.

- **Subagent.** v2.5.0+ ships an optional `m2ui-pre-emit-reviewer` subagent for high-stakes generations (screenshot mode, multi-file edits, gated windows). It runs an independent audit before emission and surfaces findings without proposing fixes. See `agents/m2ui-pre-emit-reviewer.md`.

## What Gets Generated

Every invocation produces the appropriate combination of:

- **uiscript dict file** — declarative layout definition, written to `pack/pack/uiscript/uiscript/`
- **root `ui*.py` class** — event handling and logic, written to `pack/pack/root/`
- **locale string entries** — appended to your project's locale files (paths auto-detected)
- **interfacemodule.py snippet** — integration code shown for manual insertion

### Two UI Styles

The skill supports both Metin2 UI patterns and auto-picks based on complexity:

- **Script-backed** (uiscript dict + root class) — best for complex windows with many static elements. Uses `LoadScriptFile()` and `GetChild()` to wire layout to logic.
- **Code-only** (programmatic root class, no uiscript) — best for simpler or highly dynamic windows. Builds UI in a `__LoadDialog()` method using `SetParent()` and `InsertChild()`.

## Code Standards

All generated code enforces these rules to prevent common Metin2 UI bugs. Before emitting any output, the agent runs a silent **Pre-Emit Self-Review** gate against this checklist (see `skills/m2ui/SKILL.md` → `## Pre-Emit Self-Review`):

- **`@ui.WindowDestroy`** decorator on every `Destroy()` method — ensures proper cleanup of child windows and instance attributes
- **Callback wrapping** — every callback referencing `self` MUST use `ui.__mem_func__()`, `SAFE_SetEvent` (if fork provides it), or `lambda r=proxy(self): r.X()`. Never bare bound methods or self-capturing lambdas. See `skills/m2ui/reference/event-binding.md` for the full matrix and decision flow.
- **`Initialize()` / `Destroy()` / `Open()` / `Close()` / `OnPressEscapeKey()`** pattern — standard window lifecycle
- **`OnPressEscapeKey()`** returns `True` always; **`OnMouseWheel()`** returns `True`/`False` based on whether it consumed the event
- **Locale strings via `localeInfo` / `uiScriptLocale`** — never hardcoded, always externalized
- **`not_pick` flag** on decorative elements — prevents click interception by backgrounds, separators, and lines
- **`constInfo.intWithCommas()`** for large numbers — consistent number formatting
- **Clip mask support** (`app.__BL_CLIP_MASK__`) — proper clipping for scrollable content
- **Asset paths verified** — image paths checked against `D:\ymir work\ui\` before reference; absent assets emitted as `# TBD ASSET: ...` placeholders, not invented
- **C++ APIs verified** — calls to `net.X` / `player.X` / etc. checked against `skills/m2ui/reference/bindings.md` before emit; absent functions emitted as `# TODO: verify ...` stubs, not fabricated

## File Structure

```
m2ui/
├── .claude-plugin/
│   ├── marketplace.json            Claude Code marketplace descriptor (this repo IS a marketplace)
│   └── plugin.json                 Claude Code plugin manifest
├── commands/
│   └── m2ui.md                     /m2ui slash command (delegates to skill)
├── plugins/m2ui/
│   └── .codex-plugin/
│       └── plugin.json             Codex plugin manifest
├── rules/
│   └── m2ui-activate.md            Source of truth — synced to all tools by CI
├── skills/m2ui/
│   ├── SKILL.md                    Entry point — mode detection, Critical Rules, Pre-Emit Self-Review gate
│   ├── modes/
│   │   ├── screenshot.md           Screenshot interpretation workflow
│   │   ├── talk.md                 Natural language generation workflow
│   │   ├── script.md               Existing file modification workflow
│   │   └── diagnose.md             Anti-pattern audit workflow
│   └── reference/
│       ├── event-binding.md        Callback wrapping matrix — single source of truth for memory-safe event hookup
│       ├── widgets.md              All 34 widget types with properties (995 lines)
│       ├── patterns.md             Code templates and best practices (2,700+ lines)
│       ├── bindings.md             C++ Python module catalog (1,281 lines)
│       └── locale.md               Locale string format and rules
├── .cursor/rules/m2ui.mdc          Auto-synced Cursor rules
├── .windsurf/rules/m2ui.md         Auto-synced Windsurf rules
├── .clinerules/m2ui.md             Auto-synced Cline rules
├── .github/
│   ├── copilot-instructions.md     Auto-synced Copilot instructions
│   └── workflows/sync-skill.yml   CI workflow for syncing copies
├── AGENTS.md                       Generic agent entry point (Codex, etc.)
├── GEMINI.md                       Gemini CLI entry point
├── gemini-extension.json           Gemini CLI extension metadata
└── README.md
```

## Contributing

The reference documentation in `skills/m2ui/reference/` is the core of this skill. To improve it:

- **`event-binding.md`** — Update callback wrapping matrix when fork conventions change
- **`widgets.md`** — Add missing widget properties or document new widget types
- **`patterns.md`** — Add new code patterns or update templates
- **`bindings.md`** — Update when new C++ Python module functions are added
- **`locale.md`** — Update if locale path conventions change

**Important:** Do not edit the tool-specific rule copies (`.cursor/rules/`, `.windsurf/rules/`, etc.) directly. Edit `rules/m2ui-activate.md` instead — the CI workflow propagates changes to all copies automatically.

## Requirements

- A Metin2 client project with `pack/pack/root/` and `pack/pack/uiscript/uiscript/` directories
- One of the [supported AI coding agents](#supported-agents)
