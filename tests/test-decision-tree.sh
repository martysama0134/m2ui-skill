#!/usr/bin/env bash
# test-decision-tree.sh
# Validates the 2-step anchor decision tree in SKILL.md, anchors/README.md,
# and rules/m2ui-activate.md, plus augmentor body-section declarations.

set -u
set -o pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SKILL="${REPO_ROOT}/skills/m2ui/SKILL.md"
README="${REPO_ROOT}/skills/m2ui/reference/anchors/README.md"
ACTIVATE="${REPO_ROOT}/rules/m2ui-activate.md"
INTEGRATION="${REPO_ROOT}/skills/m2ui/reference/integration.md"
ANCHORS_DIR="${REPO_ROOT}/skills/m2ui/reference/anchors"
FAILURES=0

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

assert_file_grep() {
    local name="$1"; local path="$2"; local pattern="$3"
    if grep -qE "$pattern" "$path" 2>/dev/null; then
        echo "PASS: $name"
    else
        echo "FAIL: $name (pattern not found in $path: $pattern)"
        FAILURES=$((FAILURES + 1))
    fi
}

echo "=== test-decision-tree.sh ==="
echo

# 1. integration.md exists
assert_file_exists "integration.md" "$INTEGRATION"

# 2. README.md has Step 1 + Step 2 sections
assert_file_grep "README Step 1 section" "$README" '^### Step 1'
assert_file_grep "README Step 2 section" "$README" '^### Step 2'

# 3. README Step 1 has >= 17 archetype rows (12 from Phase A + 5 new in Phase B)
step1_rows=$(awk '
    /^### Step 1/{f=1; next}
    f && /^### Step 2/{exit}
    f && /`[0-9][0-9]-.*\.md`/{c++}
    END{print c+0}
' "$README")
assert_ge "README Step 1 archetype rows" "17" "$step1_rows"

# 4. README Step 2 has >= 6 augmentor rows (4 from Phase A + 2 new in Phase B)
step2_rows=$(awk '
    /^### Step 2/{f=1; next}
    f && /^### Load order/{exit}
    f && /`[0-9][0-9]-.*\.md`/{c++}
    END{print c+0}
' "$README")
assert_ge "README Step 2 augmentor rows" "6" "$step2_rows"

# 5. SKILL.md has Step 1 + Step 2 sections (mirror)
assert_file_grep "SKILL Step 1 section" "$SKILL" 'Step 1.*pick ONE primary archetype'
assert_file_grep "SKILL Step 2 section" "$SKILL" 'Step 2.*pick zero or more augmentors'

# 6. activate.md has Step 1 + Step 2 sections (mirror)
assert_file_grep "activate Step 1 section" "$ACTIVATE" 'Step 1.*pick ONE primary archetype'
assert_file_grep "activate Step 2 section" "$ACTIVATE" 'Step 2.*pick zero or more augmentors'

# 7. Each augmentor file declares its body section
for n in 05 14 15 16 22 23; do
    files=$(ls "${ANCHORS_DIR}/${n}-"*.md 2>/dev/null || true)
    if [ -z "$files" ]; then
        # Augmentor file may not exist yet during incremental landing — skip
        echo "SKIP: augmentor ${n} not yet present (incremental landing)"
        continue
    fi
    for f in $files; do
        assert_file_grep "augmentor $(basename "$f") declares body section" "$f" 'Body content lives in section [67]\.'
    done
done

# 8. Each anchor file (existing + new) has all 8 uniform sections
for f in "${ANCHORS_DIR}"/[0-9][0-9]-*.md; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    sections=$(grep -cE '^## (What this is|Source|Uiscript dict|Root class|Locale entries|interfacemodule\.py integration snippet|Common variations|Don.t copy these obsolete bits)' "$f")
    if [ "$sections" -ge 8 ]; then
        echo "PASS: $name has all 8 sections"
    else
        echo "FAIL: $name only has $sections/8 sections"
        FAILURES=$((FAILURES + 1))
    fi
done

# 9. Mirror-list comparison: SKILL.md / anchors/README.md / rules/m2ui-activate.md
# must reference the SAME set of NN-name.md anchor filenames in their Step 1
# and Step 2 tables. Drift across mirrors causes non-Claude agents to load
# the wrong anchor list.
extract_anchor_refs() {
    local file="$1"
    grep -oE '[0-9][0-9]-[a-z0-9-]+\.md' "$file" | sort -u
}

skill_anchors=$(extract_anchor_refs "$SKILL")
readme_anchors=$(extract_anchor_refs "$README")
activate_anchors=$(extract_anchor_refs "$ACTIVATE")

if [ "$skill_anchors" = "$readme_anchors" ] && [ "$readme_anchors" = "$activate_anchors" ]; then
    anchor_count=$(echo "$skill_anchors" | wc -l | tr -d ' ')
    echo "PASS: mirror-list agreement (3 files reference same $anchor_count anchors)"
else
    echo "FAIL: mirror-list drift detected. SKILL/README/activate disagree on archetype list."
    echo "  SKILL.md anchors:    $(echo "$skill_anchors" | tr '\n' ' ')"
    echo "  README.md anchors:   $(echo "$readme_anchors" | tr '\n' ' ')"
    echo "  activate.md anchors: $(echo "$activate_anchors" | tr '\n' ' ')"
    FAILURES=$((FAILURES + 1))
fi

echo
echo "=== Result: $FAILURES failure(s) ==="
exit "$FAILURES"
