# Locale String Reference

## Format

Tab-separated `KEY\tValue` — one entry per line, no quotes, no trailing whitespace.

```
WINDOW_NAME_BUTTON_LABEL	Click Here
WINDOW_NAME_TITLE	My Window
```

## Target Files

**Auto-detect locale paths before writing.** Glob for `**/locale_interface*.txt` and `**/locale_game*.txt` under `pack/`. If exactly one pair found, use those paths. If multiple pairs found, show the user what you found and ask which locale directory to use. Cache the choice for the rest of the session.

Common locations (varies by project):

| Type | Possible paths | When to use |
|------|---------------|-------------|
| UI labels | `pack/pack/locale/<lang>/locale_interface.txt` | Window titles, button text, tab names, tooltips, column headers, static labels |
| | `pack/pack/special_patch_ex/locale/common/locale_interface_ex.txt` | |
| Game messages | `pack/pack/locale/<lang>/locale_game.txt` | Chat notifications, system messages, error text, confirmation dialogs |
| | `pack/pack/special_patch_ex/locale/common/locale_game_ex.txt` | |

Where `<lang>` is a language code like `en`, `de`, `fr`, `tr`, `ro`, `pl`, `cz`, `br`, etc.

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

## File Encoding

The Metin2 client uses Windows code pages, not UTF-8. When writing locale files, determine the encoding from the locale directory name:

| Language | Code | Encoding |
|----------|------|----------|
| Arabic | `ae` | Windows-1256 |
| Brazilian | `br` | Windows-1252 |
| Czech | `cz` | Windows-1250 |
| German | `de` | Windows-1252 |
| Danish | `dk` | Windows-1252 |
| English | `en` | Windows-1252 |
| Spanish | `es` | Windows-1252 |
| French | `fr` | Windows-1252 |
| Greek | `gr` | Windows-1253 |
| Hungarian | `hu` | Windows-1250 |
| Italian | `it` | Windows-1252 |
| Korean | `kr` | cp949 |
| Dutch | `nl` | Windows-1252 |
| Polish | `pl` | Windows-1250 |
| Portuguese | `pt` | Windows-1252 |
| Romanian | `ro` | Windows-1250 |
| Russian | `ru` | KOI8-R |
| Turkish | `tr` | Windows-1254 |

**Rules:**
- Check the locale directory name (e.g., `locale/de/`) to determine the correct encoding
- If the directory name matches a known language code above, write the file in that encoding
- If unknown, default to Windows-1252 (Western European)
- Romanian (`ro`) uses Windows-1250 but has two accents (ș/ț with comma below) that require conversion from their Unicode cedilla variants (ş/ţ) to the correct comma-below forms — the code page only has the cedilla variants, so use those
- Never write locale files as UTF-8 unless the project explicitly uses UTF-8 locale files

## Rules

- **Append only** — never overwrite or reorder existing entries
- **Check before adding** — read the file first, avoid duplicate keys
- **Group new entries** — add all entries for one window together, at the end of the file
- **No empty lines** between entries (match existing file format)
- **Match existing encoding** — when appending, write in the same encoding as the rest of the file
