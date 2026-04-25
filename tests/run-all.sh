#!/usr/bin/env bash
# run-all.sh
# Runs every structural test in this directory, accumulates failures, exits non-zero on any failure.

set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
TOTAL_FAILURES=0

for test in "${DIR}"/test-*.sh; do
    echo
    bash "$test"
    rc=$?
    TOTAL_FAILURES=$((TOTAL_FAILURES + rc))
done

echo
echo "=========================================="
echo "Total failures across all tests: $TOTAL_FAILURES"
echo "=========================================="

exit "$TOTAL_FAILURES"
