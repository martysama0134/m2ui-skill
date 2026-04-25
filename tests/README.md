# m2ui structural tests

Bash-based smoke tests that validate the skill's structural integrity. Run on every push (manually or via CI) to catch drift between releases — broken cross-references, missing required sections, atlas entries that lost their Quick check, etc.

These tests do NOT validate agent behavior (that's manual via fresh CC session). They validate the skill's text shape.

## Running

From the plugin root:

```bash
bash tests/run-all.sh
```

Or run an individual test:

```bash
bash tests/test-mode-dispatch.sh
bash tests/test-required-refs.sh
bash tests/test-pre-emit-invariants.sh
```

Each test prints `PASS` or `FAIL: <reason>` per assertion and exits non-zero on any failure.

## What each test covers

- **test-mode-dispatch.sh** — `SKILL.md` mode-detection numbered items, dispatch keywords, conditional-load matrix scope, EXTREMELY-IMPORTANT block presence, SUBAGENT-STOP guard.
- **test-required-refs.sh** — every `skills/m2ui/reference/*.md` cross-reference in `SKILL.md`, `failure-atlas.md`, `screenshot.md`, and `m2ui-pre-emit-reviewer.md` points to a file that exists on disk.
- **test-pre-emit-invariants.sh** — `SKILL.md` Pre-Emit Self-Review checklist has the expected number of items; every failure-atlas entry has a Quick check + a See-also cross-reference; mandatory anchors all present in `reference/anchors/`; mandatory ref files all present.

## Adding a new test

Follow the same pattern as the three existing scripts:

1. Print test name + a separator at start.
2. For each assertion, print `PASS` or `FAIL: <human description>` on its own line.
3. Maintain a `FAILURES` counter; `exit $FAILURES` at the end.
4. Add a line invoking the new script to `run-all.sh`.
5. Document what the test covers in this README.

Keep assertions independent — one failed assertion should not prevent the next from running. The goal is a complete map of what's broken, not a stop-on-first-failure debugger.

## Limitations

- These tests catch STRUCTURAL drift (missing sections, broken cross-refs, count mismatches). They do NOT catch SEMANTIC regressions (e.g., a rule that's worded incorrectly but still present). Behavioral validation requires running the skill against real prompts in a fresh Claude Code session.
- Personal-data scrub is NOT a test here — it's enforced at PR time via the `git ls-files | xargs grep -l ...` pattern in commit/PR plans. A test would risk false positives on the regex itself.
