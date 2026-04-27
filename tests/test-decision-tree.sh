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

# 3. README Step 1 has >= 12 archetype rows (existing 5 + 7 new in this PR)
step1_rows=$(awk '
    /^### Step 1/{f=1; next}
    f && /^### Step 2/{exit}
    f && /`[0-9][0-9]-.*\.md`/{c++}
    END{print c+0}
' "$README")
assert_ge "README Step 1 archetype rows" "12" "$step1_rows"

# 4. README Step 2 has >= 4 augmentor rows
step2_rows=$(awk '
    /^### Step 2/{f=1; next}
    f && /^### Load order/{exit}
    f && /`[0-9][0-9]-.*\.md`/{c++}
    END{print c+0}
' "$README")
assert_ge "README Step 2 augmentor rows" "4" "$step2_rows"

# 5. SKILL.md has Step 1 + Step 2 sections (mirror)
assert_file_grep "SKILL Step 1 section" "$SKILL" 'Step 1.*pick ONE primary archetype'
assert_file_grep "SKILL Step 2 section" "$SKILL" 'Step 2.*pick zero or more augmentors'

# 6. activate.md has Step 1 + Step 2 sections (mirror)
assert_file_grep "activate Step 1 section" "$ACTIVATE" 'Step 1.*pick ONE primary archetype'
assert_file_grep "activate Step 2 section" "$ACTIVATE" 'Step 2.*pick zero or more augmentors'

# 7. Each augmentor file declares its body section
for n in 05 14 15 16; do
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

echo
echo "=== Result: $FAILURES failure(s) ==="
exit "$FAILURES"
