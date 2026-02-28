#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${REPOFLOW_PAT:-}" ]]; then
  echo "REPOFLOW_PAT is required"
  exit 1
fi

: "${REPOFLOW_BASE_URL:=https://repoflow.erauner.dev}"
: "${REPOFLOW_WORKSPACE:=homelab}"
: "${SMOKE_RUN_ID:=local}"

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPOFLOW_API_URL="${REPOFLOW_BASE_URL}/api"
RUN_TS="$(date +%Y%m%d%H%M%S)"
SMOKE_ID="${SMOKE_RUN_ID}-${RUN_TS}"
SMOKE_VERSION="0.0.${RUN_TS}"
host_no_scheme="$(echo "${REPOFLOW_BASE_URL}" | sed 's#^https\?://##')"

api_post_form() {
  local path="$1"
  shift
  curl -fsS -X POST \
    -H "Authorization: Bearer ${REPOFLOW_PAT}" \
    -H "Accept: application/json" \
    "${REPOFLOW_API_URL}${path}" "$@"
}

echo "RepoFlow: ${REPOFLOW_BASE_URL}"
echo "Workspace: ${REPOFLOW_WORKSPACE}"
echo "Smoke ID: ${SMOKE_ID}"
echo "Version: ${SMOKE_VERSION}"
