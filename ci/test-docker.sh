#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

if ! command -v docker >/dev/null 2>&1; then
  echo "docker not available"
  exit 1
fi

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cp -R "${REPO_ROOT}/docker/." "$work/"

cat > "$work/config.json" <<CFG
{"auths":{"${host_no_scheme}":{"auth":"$(printf 'token:%s' "${REPOFLOW_PAT}" | base64)"}}}
CFG
export DOCKER_CONFIG="$work"

local_tag="${host_no_scheme}/${REPOFLOW_WORKSPACE}/docker-local/smoke:${SMOKE_VERSION}"
virt_tag="${host_no_scheme}/${REPOFLOW_WORKSPACE}/docker/smoke:${SMOKE_VERSION}"

docker build -t "$local_tag" "$work" >/dev/null
docker push "$local_tag" >/dev/null
docker pull "$virt_tag" >/dev/null

echo "docker smoke passed: ${virt_tag}"
