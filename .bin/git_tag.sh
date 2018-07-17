#!/usr/bin/env bash
set -euo pipefail

BRANCH_CLEAN="${BUILDKITE_BRANCH/\//_}"
BRANCH_CLEAN="$(echo "${BRANCH_CLEAN}" | tr '[:upper:]' '[:lower:]')"

echo "${BRANCH_CLEAN}-${BUILDKITE_COMMIT:0:7}"
