#!/usr/bin/env bash
# test-similarity-scan.sh
# Source-similarity check: scan anchor / reference markdown additions for any
# line >= MIN_LEN chars that verbatim-matches a .py file in a local research
# directory ($SURVEY_DIR). Output saved to /tmp/m2ui-similarity-report.txt for
# maintainer review. Allowlist filters known house-style idioms.
#
# Usage:
#   bash tests/test-similarity-scan.sh         # scan branch diff vs main
#   bash tests/test-similarity-scan.sh HEAD~5  # scan diff vs given ref
#
# Environment overrides:
#   SURVEY_DIR  default /tmp/m2ui-research      directory of .py reference files
#   REPORT      default /tmp/m2ui-similarity-report.txt
#   MIN_LEN     default 40                       minimum candidate line length
#
# Always exits 0 (informational tool, not a hard gate). Intended use:
# maintainer reviews report before publishing the branch.

set -u
set -o pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SURVEY_DIR="${SURVEY_DIR:-/tmp/m2ui-research}"
ALLOWLIST="${REPO_ROOT}/tests/similarity-allowlist.txt"
REPORT="${REPORT:-/tmp/m2ui-similarity-report.txt}"
MIN_LEN="${MIN_LEN:-40}"
BASE_REF="${1:-main}"

if [ ! -d "$SURVEY_DIR" ]; then
    echo "Note: research directory $SURVEY_DIR not present; nothing to scan against."
    echo "Set SURVEY_DIR or extract reference .py files there before scanning."
    : > "$REPORT"
    exit 0
fi

# List changed anchor + reference markdown files in the branch diff.
mapfile -t CHANGED_FILES < <(git diff --name-only "$BASE_REF"...HEAD -- \
    'skills/m2ui/reference/anchors/*.md' \
    'skills/m2ui/reference/integration.md' \
    'skills/m2ui/reference/timer-patterns.md' 2>/dev/null)

if [ "${#CHANGED_FILES[@]}" -eq 0 ]; then
    echo "No anchor / reference markdown changes vs $BASE_REF. Nothing to scan."
    : > "$REPORT"
    exit 0
fi

# Build allowlist patterns array (skip blank lines and # comments).
ALLOWLIST_PATTERNS=()
if [ -f "$ALLOWLIST" ]; then
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        ALLOWLIST_PATTERNS+=("$line")
    done < "$ALLOWLIST"
fi

is_allowlisted() {
    local candidate="$1"
    local pat
    for pat in "${ALLOWLIST_PATTERNS[@]}"; do
        if [[ "$candidate" == *"$pat"* ]]; then
            return 0
        fi
    done
    return 1
}

: > "$REPORT"
TOTAL_MATCHES=0

# For each changed markdown file, extract long ADDED lines from the diff and
# search each line verbatim across .py files under $SURVEY_DIR.
for f in "${CHANGED_FILES[@]}"; do
    candidates=$(git diff "$BASE_REF"...HEAD -- "$f" \
        | grep -E '^\+[^+]' \
        | sed -E 's/^\+//' \
        | awk -v min="$MIN_LEN" 'length($0) >= min')

    [ -z "$candidates" ] && continue

    while IFS= read -r line; do
        if is_allowlisted "$line"; then
            continue
        fi

        # grep -F: literal; -r recursive; -l filenames only.
        matched_files=$(grep -F -r -l --include='*.py' -- "$line" "$SURVEY_DIR" 2>/dev/null || true)
        if [ -n "$matched_files" ]; then
            echo "==== $f ====" >> "$REPORT"
            echo "  candidate line: $line" >> "$REPORT"
            echo "  verbatim match in:" >> "$REPORT"
            while IFS= read -r matched_path; do
                short=$(echo "$matched_path" | sed "s|^$SURVEY_DIR/||")
                line_nums=$(grep -F -n -- "$line" "$matched_path" 2>/dev/null | cut -d: -f1 | head -3 | tr '\n' ',' | sed 's/,$//')
                echo "    $short:$line_nums" >> "$REPORT"
            done <<< "$matched_files"
            echo "" >> "$REPORT"
            TOTAL_MATCHES=$((TOTAL_MATCHES + 1))
        fi
    done <<< "$candidates"
done

{
    echo ""
    echo "==== SUMMARY ===="
    echo "Total candidate matches: $TOTAL_MATCHES"
    echo "Files scanned: ${#CHANGED_FILES[@]}"
} >> "$REPORT"

if [ "$TOTAL_MATCHES" -eq 0 ]; then
    echo "Similarity scan: clean (0 candidate matches across ${#CHANGED_FILES[@]} files)."
else
    echo "Similarity scan: $TOTAL_MATCHES candidate matches in ${#CHANGED_FILES[@]} files."
    echo "Report: $REPORT"
    echo ""
    echo "Maintainer review: each match is either"
    echo "  (a) house-style idiom -- add the substring to tests/similarity-allowlist.txt and re-run"
    echo "  (b) too close to a single source -- revise the anchor wording before publishing"
fi

exit 0
