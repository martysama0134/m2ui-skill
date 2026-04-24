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

### Claude Code (recommended)

Copy or symlink this directory into your Claude Code local plugins folder:

```bash
# macOS / Linux
ln -s /path/to/m2ui ~/.claude/plugins/local/m2ui

# Windows (PowerShell, run as admin)
New-Item -ItemType Junction -Path "$env:USERPROFILE\.claude\plugins\local\m2ui" -Target "C:\path\to\m2ui"
```

Restart Claude Code or run `/reload-plugins` to activate. Verify with `/help` — you should see `m2ui` in the skill list.

### Cursor / Windsurf / Cline / Copilot

Clone this repository into your Metin2 project root (or add as a submodule):

```bash
git clone https://github.com/user/m2ui-skill.git m2ui-skill
```

The tool-specific rule files (`.cursor/rules/`, `.windsurf/rules/`, etc.) will be picked up automatically by each agent.

### Codex

The Codex plugin is in `plugins/m2ui/`. Point your Codex configuration to this directory.

### Gemini CLI

Install as a Gemini extension using `gemini-extension.json` at the repo root.

## Usage

### In Claude Code

```
/m2ui                              Interactive mode — asks what you want to do
/m2ui screenshot                   Analyze an attached image, generate matching UI code
/m2ui talk make a shop window      Describe a UI in plain language, get generated code
/m2ui script uimovechannel.py      Modify an existing UI file
```

### In Other Agents

Just describe what you want in natural language. The agent will automatically read the reference docs and follow the m2ui rules:

- *"Create a new window with a title bar, three buttons, and a scrollable item list"*
- *"Add a search bar to the inventory window"*
- *"Here's a screenshot of a UI from another game — recreate it as Metin2 UI"*

### Auto-Detection

When no explicit mode is specified, the skill auto-detects from your input:

1. **Image attached** — screenshot mode (analyze and replicate)
2. **References a `.py` file** — script mode (modify existing)
3. **Text description** — talk mode (generate new)
4. **No input** — interactive mode (asks what you want)

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

All generated code enforces these rules to prevent common Metin2 UI bugs:

- **`@ui.WindowDestroy`** decorator on every `Destroy()` method — ensures proper cleanup of child windows and instance attributes
- **`ui.__mem_func__()`** for all callbacks referencing `self` — prevents circular reference memory leaks
- **No lambda capturing `self`** — lambdas that reference `self` leak identically to unproxied methods. Extra args are passed directly to event setters instead.
- **`Initialize()` / `Destroy()` / `Open()` / `Close()` / `OnPressEscapeKey()`** pattern — standard window lifecycle
- **Locale strings via `localeInfo` / `uiScriptLocale`** — never hardcoded, always externalized
- **`not_pick` flag** on decorative elements — prevents click interception by backgrounds, separators, and lines
- **`constInfo.intWithCommas()`** for large numbers — consistent number formatting
- **Clip mask support** (`app.__BL_CLIP_MASK__`) — proper clipping for scrollable content

## File Structure

```
m2ui/
├── .claude-plugin/
│   └── plugin.json                 Claude Code plugin manifest
├── plugins/m2ui/
│   └── .codex-plugin/
│       └── plugin.json             Codex plugin manifest
├── rules/
│   └── m2ui-activate.md            Source of truth — synced to all tools by CI
├── skills/m2ui/
│   ├── SKILL.md                    Entry point — mode detection and dispatch
│   ├── modes/
│   │   ├── screenshot.md           Screenshot interpretation workflow
│   │   ├── talk.md                 Natural language generation workflow
│   │   └── script.md              Existing file modification workflow
│   └── reference/
│       ├── widgets.md              All 34 widget types with properties (995 lines)
│       ├── patterns.md             Code templates and best practices (750+ lines)
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

- **`widgets.md`** — Add missing widget properties or document new widget types
- **`patterns.md`** — Add new code patterns or update templates
- **`bindings.md`** — Update when new C++ Python module functions are added
- **`locale.md`** — Update if locale path conventions change

**Important:** Do not edit the tool-specific rule copies (`.cursor/rules/`, `.windsurf/rules/`, etc.) directly. Edit `rules/m2ui-activate.md` instead — the CI workflow propagates changes to all copies automatically.

## Requirements

- A Metin2 client project with `pack/pack/root/` and `pack/pack/uiscript/uiscript/` directories
- One of the [supported AI coding agents](#supported-agents)
