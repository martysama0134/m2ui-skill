# Locale String Reference

## Format

Tab-separated `KEY\tValue` — one entry per line, no quotes, no trailing whitespace.

```
WINDOW_NAME_BUTTON_LABEL	Click Here
WINDOW_NAME_TITLE	My Window
```

## Target Files

| Type | File | When to use |
|------|------|-------------|
| UI labels | `pack/pack/special_patch_ex/locale/common/locale_interface_ex.txt` | Window titles, button text, tab names, tooltips, column headers, static labels |
| Game messages | `pack/pack/special_patch_ex/locale/common/locale_game_ex.txt` | Chat notifications, system messages, error text, confirmation dialogs |

## Naming Convention

`WINDOW_NAME_ELEMENT_DESCRIPTION` — all uppercase, underscored.

Examples:
- `WON_EXCHANGE_TITLE` — window title
- `WON_EXCHANGE_SELL` — button label
- `WON_EXCHANGE_NOT_ENOUGH_GOLD` — error message (goes in locale_game_ex.txt)
- `FAST_SKILL_READER_WINDOW_NAME` — window title
- `FAST_SKILL_READER_SELECT_THE_SKILL_TO_TRAIN` — instructional text

## Code References

- In root `ui*.py` files: `localeInfo.KEY`
- In uiscript dict files: `uiScriptLocale.KEY`
- Never hardcode user-visible strings

## Rules

- **Append only** — never overwrite or reorder existing entries
- **Check before adding** — read the file first, avoid duplicate keys
- **Group new entries** — add all entries for one window together, at the end of the file
- **No empty lines** between entries (match existing file format)
