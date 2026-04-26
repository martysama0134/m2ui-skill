---
description: Generate or modify Metin2 client UI code via the m2ui skill (screenshots, descriptions, existing scripts, audits)
argument-hint: [screenshot|talk|script <file>|diagnose <file>|<description>]
---

# /m2ui

Thin entry point to the `m2ui` skill. The skill's `SKILL.md` handles mode detection, file lookup, and code generation.

## Invocation

The user typed: `/m2ui $ARGUMENTS`

Invoke the `m2ui` skill via the **Skill** tool, passing the arguments verbatim. The skill auto-detects mode from the input:

- **Empty `$ARGUMENTS`** → interactive mode (the skill asks what to do)
- **Image attached** → screenshot mode
- **Args start with `screenshot` / `talk` / `script` / `diagnose`** → that mode explicitly
- **Diagnose/audit/check/review keywords** → diagnose mode
- **References a `.py` file** in `pack/pack/uiscript/` or `pack/pack/root/` → script mode
- **Any other text** → talk mode

Do not duplicate the skill's logic here. Pass `$ARGUMENTS` through and let `SKILL.md` dispatch.

## Notes

- m2ui targets **client** code (`pack/pack/uiscript/`, `pack/pack/root/`). If the active project is server-only, ask the user to confirm they have client UI files in scope before generating.
- Both the slash command (`/m2ui ...`) and natural-language invocation (e.g. *"use m2ui to make a shop window"*) reach the same skill. The slash command is for discoverability via `/help`.
