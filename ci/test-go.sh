#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cp -R "${REPO_ROOT}/packages/go" "$work/pkg"

cat > "$work/.netrc" <<NETRC
machine ${host_no_scheme}
login token
password ${REPOFLOW_PAT}
NETRC
chmod 600 "$work/.netrc"

pushd "$work/pkg" >/dev/null
export NETRC="$work/.netrc"
export GOPROXY="${REPOFLOW_API_URL}/go/${REPOFLOW_WORKSPACE}/go"
export GOSUMDB=off
export GONOSUMDB='*'
export GOPRIVATE='*'
go mod download >/dev/null
go build -o "$work/go-smoke" ./cmd/smoke
"$work/go-smoke" >/dev/null
popd >/dev/null

echo "go smoke passed: built and ran packages/go/cmd/smoke"
