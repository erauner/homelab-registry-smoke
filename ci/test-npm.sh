#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cp -R "${REPO_ROOT}/packages/npm" "$work/pkg"

pushd "$work/pkg" >/dev/null
npm version "${SMOKE_VERSION}" --no-git-tag-version >/dev/null
cat > .npmrc <<NPMRC
registry=${REPOFLOW_API_URL}/npm/${REPOFLOW_WORKSPACE}/npm-local/
//${host_no_scheme}/api/npm/${REPOFLOW_WORKSPACE}/npm-local/:_authToken=${REPOFLOW_PAT}
NPMRC
npm publish --registry "${REPOFLOW_API_URL}/npm/${REPOFLOW_WORKSPACE}/npm-local/" >/dev/null

mkdir -p "$work/consume"
cd "$work/consume"
npm init -y >/dev/null
cat > .npmrc <<NPMRC
registry=${REPOFLOW_API_URL}/npm/${REPOFLOW_WORKSPACE}/npm/
//${host_no_scheme}/api/npm/${REPOFLOW_WORKSPACE}/npm/:_authToken=${REPOFLOW_PAT}
NPMRC
npm install "repoflow-npm-smoke@${SMOKE_VERSION}" --registry "${REPOFLOW_API_URL}/npm/${REPOFLOW_WORKSPACE}/npm/" >/dev/null
popd >/dev/null

echo "npm smoke passed: repoflow-npm-smoke@${SMOKE_VERSION}"
