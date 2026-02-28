#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cp -R "${REPO_ROOT}/packages/npm" "$work/pkg"

pushd "$work/pkg" >/dev/null
npm version "${SMOKE_VERSION}" --no-git-tag-version >/dev/null
cat > .npmrc <<NPMRC
registry=${ARTI_BASE}/api/npm/${ARTI_NPM_LOCAL_REPO}/
//${ARTI_HOST}${ARTI_BASE_PATH}/api/npm/${ARTI_NPM_LOCAL_REPO}/:_auth=${basic_auth_b64}
//${ARTI_HOST}${ARTI_BASE_PATH}/api/npm/${ARTI_NPM_LOCAL_REPO}/:always-auth=true
NPMRC
npm publish --registry "${ARTI_BASE}/api/npm/${ARTI_NPM_LOCAL_REPO}/" >/dev/null

mkdir -p "$work/consume"
cd "$work/consume"
npm init -y >/dev/null
cat > .npmrc <<NPMRC
registry=${ARTI_BASE}/api/npm/${ARTI_NPM_VIRTUAL_REPO}/
//${ARTI_HOST}${ARTI_BASE_PATH}/api/npm/${ARTI_NPM_VIRTUAL_REPO}/:_auth=${basic_auth_b64}
//${ARTI_HOST}${ARTI_BASE_PATH}/api/npm/${ARTI_NPM_VIRTUAL_REPO}/:always-auth=true
NPMRC

# Virtual repositories can lag briefly after publish; retry to avoid flaky smoke failures.
installed=0
for attempt in {1..12}; do
  if npm install "repoflow-npm-smoke@${SMOKE_VERSION}" --registry "${ARTI_BASE}/api/npm/${ARTI_NPM_VIRTUAL_REPO}/" >/dev/null 2>&1; then
    installed=1
    break
  fi
  echo "npm virtual not ready yet (attempt ${attempt}/12), retrying in 5s..."
  sleep 5
done
if [[ "${installed}" -ne 1 ]]; then
  echo "failed to install repoflow-npm-smoke@${SMOKE_VERSION} from artifactory virtual repo after retries"
  exit 1
fi
popd >/dev/null

echo "artifactory npm passed"
