#!/usr/bin/env bash
# test-required-refs.sh
# Validates every cross-reference to skills/m2ui/reference/*.md and skills/m2ui/modes/*.md
# from key skill files points to a file that exists on disk.

set -u

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCAN_FILES=(
    "${REPO_ROOT}/skills/m2ui/SKILL.md"
    "${REPO_ROOT}/skills/m2ui/reference/failure-atlas.md"
    "${REPO_ROOT}/skills/m2ui/modes/screenshot.md"
    "${REPO_ROOT}/agents/m2ui-pre-emit-reviewer.md"
)
FAILURES=0

echo "=== test-required-refs.sh ==="
echo

for src in "${SCAN_FILES[@]}"; do
    if [ ! -f "$src" ]; then
        echo "FAIL: source file missing: $src"
        FAILURES=$((FAILURES + 1))
        continue
    fi

    # Two ref styles in the codebase, both normalized to canonical-from-repo-root paths:
    #  (a) full path from repo root: `skills/m2ui/reference/X.md`
    #  (b) relative to skills/m2ui/: `reference/X.md` or `modes/X.md`
    # Strategy: extract both, normalize (a) as-is, prepend `skills/m2ui/` to (b),
    # then dedupe so each unique target is verified exactly once per source file.
    refs_full=$(grep -oE 'skills/m2ui/(reference/anchors|reference|modes)/[a-zA-Z0-9_.-]+\.md' "$src")
    # Relative form: must NOT have `skills/m2ui/` immediately before it.
    refs_rel=$(grep -oE '(^|[^/])\b(reference/anchors|reference|modes)/[a-zA-Z0-9_.-]+\.md' "$src" \
        | sed -E 's|^[^a-z]*||' \
        | grep -vE '^(skills/m2ui/)?(reference|modes)/anchors')

    canonical=$( { echo "$refs_full"; echo "$refs_rel" | sed 's|^|skills/m2ui/|'; } \
        | grep -v '^$' \
        | grep -E '\.md$' \
        | sort -u)

    if [ -z "$canonical" ]; then
        echo "INFO: no refs in $(basename "$src") (skipping)"
        continue
    fi

    while IFS= read -r ref; do
        [ -z "$ref" ] && continue
        target="${REPO_ROOT}/${ref}"
        if [ -f "$target" ]; then
            echo "PASS: $(basename "$src") -> $ref"
        else
            echo "FAIL: $(basename "$src") -> $ref (file missing)"
            FAILURES=$((FAILURES + 1))
        fi
    done <<< "$canonical"
done

# Also verify every anchor file referenced by anchors/README.md exists.
ANCHORS_README="${REPO_ROOT}/skills/m2ui/reference/anchors/README.md"
if [ -f "$ANCHORS_README" ]; then
    anchor_refs=$(grep -oE '0[1-6]-[a-z0-9-]+\.md' "$ANCHORS_README" | sort -u)
    while IFS= read -r anchor; do
        [ -z "$anchor" ] && continue
        target="${REPO_ROOT}/skills/m2ui/reference/anchors/${anchor}"
        if [ -f "$target" ]; then
            echo "PASS: anchors/README.md -> $anchor"
        else
            echo "FAIL: anchors/README.md -> $anchor (file missing)"
            FAILURES=$((FAILURES + 1))
        fi
    done <<< "$anchor_refs"
fi

echo
echo "=== Result: $FAILURES failure(s) ==="
exit "$FAILURES"
