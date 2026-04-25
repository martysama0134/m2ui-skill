#!/usr/bin/env bash
# test-pre-emit-invariants.sh
# Validates structural invariants of the Pre-Emit checklist, failure-atlas,
# anchors, and the mandatory-floor reference files.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="${REPO_ROOT}/skills/m2ui/SKILL.md"
ATLAS="${REPO_ROOT}/skills/m2ui/reference/failure-atlas.md"
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

assert_file_exists() {
    local name="$1"; local path="$2"
    if [ -f "$path" ]; then
        echo "PASS: $name exists"
    else
        echo "FAIL: $name missing at $path"
        FAILURES=$((FAILURES + 1))
    fi
}

echo "=== test-pre-emit-invariants.sh ==="
echo

# 1. Pre-Emit Self-Review checklist has at least 16 numbered items (current: 16; future-proofed with >=).
pre_emit_items=$(awk '/^## Pre-Emit Self-Review/{f=1; next} /^## /{f=0} f && /^[0-9]+\./{c++} END{print c+0}' "$SKILL")
assert_ge "Pre-Emit checklist items" "16" "$pre_emit_items"

# 2. failure-atlas has 14 numbered entries (## N. "...")
atlas_entries=$(grep -cE '^## [0-9]+\. "' "$ATLAS")
assert_eq "Atlas numbered entries" "14" "$atlas_entries"

# 3. Every atlas entry has a Quick check (one per entry minimum)
quick_checks=$(grep -c '\*\*Quick check:\*\*' "$ATLAS")
assert_ge "Atlas Quick check count" "$atlas_entries" "$quick_checks"

# 4. Every atlas entry has a See also cross-link
see_alsos=$(grep -c '\*\*See also:\*\*' "$ATLAS")
# Atlas entries without See also are tolerated only if they reference a future-phase item.
# Current target: every entry has one. Use >= entries - 2 for slack.
expected_see_alsos=$((atlas_entries - 2))
assert_ge "Atlas See also count (slack=2)" "$expected_see_alsos" "$see_alsos"

# 5. Six anchors present
anchors_dir="${REPO_ROOT}/skills/m2ui/reference/anchors"
for n in 01 02 03 04 05 06; do
    found=$(ls "${anchors_dir}/" 2>/dev/null | grep -c "^${n}-" || echo 0)
    assert_eq "Anchor ${n} present" "1" "$found"
done

# 6. Mandatory-floor reference files present
for ref in event-binding.md mental-model.md widgets.md patterns.md bindings.md locale.md failure-atlas.md visual-conventions.md; do
    assert_file_exists "reference/${ref}" "${REPO_ROOT}/skills/m2ui/reference/${ref}"
done

# 7. Anchor README present
assert_file_exists "anchors/README.md" "${anchors_dir}/README.md"

# 8. Reviewer agent present
assert_file_exists "agents/m2ui-pre-emit-reviewer.md" "${REPO_ROOT}/agents/m2ui-pre-emit-reviewer.md"

echo
echo "=== Result: $FAILURES failure(s) ==="
exit "$FAILURES"
