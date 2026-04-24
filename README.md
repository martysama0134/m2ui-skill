# /m2ui — Metin2 UI Code Generator

Claude Code plugin that generates and modifies Metin2 client UI code. Supports three input modes: create from screenshot, describe in natural language, or modify existing scripts.

## Installation

Copy or symlink this directory to your Claude Code local plugins folder:

```
~/.claude/plugins/local/m2ui/
```

On Windows:
```
%USERPROFILE%\.claude\plugins\local\m2ui\
```

Restart Claude Code (or run `/reload-plugins`) to pick up the plugin. Verify by running `/help` — `m2ui` should appear in the skill list.

## Usage

```
/m2ui                              Interactive — asks what you want to do
/m2ui screenshot                   Analyze attached image, generate matching UI code
/m2ui talk make a shop window      Describe a UI in plain text, get generated code
/m2ui script uimovechannel.py      Modify an existing UI file
```

### Auto-Detection

If you skip the mode keyword, the skill auto-detects:

1. Image attached → screenshot mode
2. References an existing `.py` file → script mode
3. Text description → talk mode
4. No args → interactive prompt

### What Gets Generated

- **uiscript dict file** — layout definition (`pack/pack/uiscript/uiscript/`)
- **root ui*.py class** — event handling and logic (`pack/pack/root/`)
- **locale string entries** — appended to your project's locale files (auto-detected)
- **interfacemodule.py snippet** — integration code shown for manual insertion

### Two UI Styles

The skill supports both Metin2 UI patterns:

- **Script-backed** (uiscript dict + root class) — for complex windows with many static elements
- **Code-only** (programmatic root class, no uiscript) — for simpler or dynamic windows

The skill auto-picks based on complexity, or you can choose.

## File Structure

```
m2ui/
├── .claude-plugin/
│   └── plugin.json            Plugin manifest
├── skills/m2ui/
│   ├── SKILL.md               Entry point — mode detection and dispatch
│   ├── modes/
│   │   ├── screenshot.md      Screenshot interpretation instructions
│   │   ├── talk.md            Natural language generation instructions
│   │   └── script.md          Existing file modification instructions
│   └── reference/
│       ├── widgets.md         All 34 widget types with properties
│       ├── patterns.md        Code templates and best practices
│       ├── bindings.md        C++ Python module function catalog
│       └── locale.md          Locale string format and rules
└── README.md
```

## Code Standards

All generated code follows these rules:

- `@ui.WindowDestroy` decorator on every `Destroy()` method
- `ui.__mem_func__()` for all callbacks referencing `self`
- No lambda capturing `self` — extra args passed directly to event setters
- `Initialize()` / `Destroy()` / `Open()` / `Close()` / `OnPressEscapeKey()` pattern
- Locale strings via `localeInfo` / `uiScriptLocale`, never hardcoded
- `not_pick` flag on decorative elements
- `constInfo.intWithCommas()` for large numbers

## Requirements

- [Claude Code](https://claude.ai/code) CLI or desktop app
- A Metin2 client source project with `pack/pack/root/` and `pack/pack/uiscript/uiscript/` directories
