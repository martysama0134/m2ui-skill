#!/usr/bin/env bash
# test-mode-dispatch.sh
# Validates SKILL.md mode-detection structure + emphasis blocks.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="${REPO_ROOT}/skills/m2ui/SKILL.md"
ACTIVATE="${REPO_ROOT}/rules/m2ui-activate.md"
FAILURES=0

assert_eq() {
    local name="$1"; local expected="$2"; local actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "PASS: $name (= $expected)"
    else
        echo "FAIL: $name expected=$expected actual=$actual"
        FAILURES=$((FAILURES + 1))
    fi
}

assert_ge() {
    local name="$1"; local expected="$2"; local actual="$3"
    if [ "$actual" -ge "$expected" ]; then
        echo "PASS: $name (>= $expected, got $actual)"
    else
        echo "FAIL: $name expected>=$expected actual=$actual"
        FAILURES=$((FAILURES + 1))
    fi
}

echo "=== test-mode-dispatch.sh ==="
echo "SKILL: $SKILL"
echo

# 1. SKILL.md exists
if [ ! -f "$SKILL" ]; then
    echo "FAIL: SKILL.md missing at $SKILL"
    exit 1
fi

# 2. Mode Detection section present
mode_section=$(grep -c "^## Mode Detection" "$SKILL")
assert_eq "Mode Detection section" "1" "$mode_section"

# 3. Mode Detection has 7 numbered items (Image / Diagnose / Symptom / File / Text / No-args / Explicit-keyword — order matters but count is 7 after v2.3.3)
# Items 1-7 numbered immediately after "## Mode Detection" until the next ## or blank gap.
# Use awk to count numbered items in the Mode Detection section only.
mode_items=$(awk '/^## Mode Detection/{f=1; next} /^## /{f=0} f && /^[0-9]+\./{c++} END{print c+0}' "$SKILL")
assert_eq "Mode Detection numbered items" "7" "$mode_items"

# 4. Symptom branch present (added v2.3.3)
symptom=$(grep -c "Symptom report" "$SKILL")
assert_ge "Symptom report branch" "1" "$symptom"

# 5. SUBAGENT-STOP guard present (added v2.4.0)
subagent_stop=$(grep -c "SUBAGENT-STOP" "$SKILL")
assert_eq "SUBAGENT-STOP tag count" "2" "$subagent_stop"

# 6. EXTREMELY-IMPORTANT blocks: 5 blocks = 10 tag occurrences
#    (3 original blocks from v2.4.0: callback wrapping, asset paths, verified APIs;
#     1 added by Critical Rule 17: preserve Destroy bodies;
#     1 added by Critical Rule 19: verify setter accepts *args)
emphasis_tags=$(grep -c "EXTREMELY-IMPORTANT" "$SKILL")
assert_eq "EXTREMELY-IMPORTANT tag count (5 blocks * 2 tags)" "10" "$emphasis_tags"

# 7. Conditional-load matrix has the 8 expected rows (incl. failure-atlas + visual-conventions added v2.3.0)
# Find the "Conditional load" marker, then the table separator |---, then count rows until blank.
conditional_rows=$(awk '
    /Conditional load/{found=1; next}
    found && /^\|---/{started=1; next}
    started && /^\| /{c++}
    started && /^$/{exit}
    END{print c+0}
' "$SKILL")
assert_ge "Conditional load matrix rows" "8" "$conditional_rows"

# 8. Pre-Emit Self-Review section present
pre_emit=$(grep -c "^## Pre-Emit Self-Review" "$SKILL")
assert_eq "Pre-Emit Self-Review section" "1" "$pre_emit"

# 9. m2ui-pre-emit-reviewer cross-link present (added v2.5.0)
reviewer_ref=$(grep -c "m2ui-pre-emit-reviewer" "$SKILL")
assert_ge "m2ui-pre-emit-reviewer cross-link" "1" "$reviewer_ref"

# 10. m2ui-activate.md mirror has same symptom branch
activate_symptom=$(grep -c "Symptom report" "$ACTIVATE")
assert_ge "m2ui-activate.md symptom branch (mirror)" "1" "$activate_symptom"

echo
echo "=== Result: $FAILURES failure(s) ==="
exit "$FAILURES"
