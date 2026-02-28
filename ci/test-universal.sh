#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

cp -R "${REPO_ROOT}/assets/universal" "$work/universal"
tar -czf "$work/universal-smoke-${SMOKE_VERSION}.tar.gz" -C "$work" universal

api_post_form "/1/workspaces/${REPOFLOW_WORKSPACE}/repositories/universal-local/packages/single" \
  -F "packageFiles=@$work/universal-smoke-${SMOKE_VERSION}.tar.gz" \
  -F "packageName=universal-smoke" \
  -F "packageVersion=${SMOKE_VERSION}" >/dev/null

curl -fsS -H "Authorization: Bearer ${REPOFLOW_PAT}" \
  "${REPOFLOW_API_URL}/universal/${REPOFLOW_WORKSPACE}/universal/universal-smoke/${SMOKE_VERSION}/universal-smoke-${SMOKE_VERSION}.tar.gz" >/dev/null

echo "universal smoke passed: universal-smoke-${SMOKE_VERSION}.tar.gz"
