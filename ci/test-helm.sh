#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cp -R "${REPO_ROOT}/charts/rf-helm-smoke" "$work/rf-helm-smoke"

sed -i.bak "s/^version: .*/version: ${SMOKE_VERSION}/" "$work/rf-helm-smoke/Chart.yaml"
sed -i.bak "s/^appVersion: .*/appVersion: \"${SMOKE_VERSION}\"/" "$work/rf-helm-smoke/Chart.yaml"
rm -f "$work/rf-helm-smoke/Chart.yaml.bak"

pushd "$work" >/dev/null
helm package rf-helm-smoke -d . >/dev/null

api_post_form "/1/workspaces/${REPOFLOW_WORKSPACE}/repositories/helm-local/packages/single" \
  -F "packageFiles=@rf-helm-smoke-${SMOKE_VERSION}.tgz" >/dev/null

helm repo add rf-smoke "${REPOFLOW_API_URL}/helm/${REPOFLOW_WORKSPACE}/helm" \
  --username token --password "${REPOFLOW_PAT}" >/dev/null
helm repo update >/dev/null
helm pull rf-smoke/rf-helm-smoke --version "${SMOKE_VERSION}" >/dev/null
popd >/dev/null

echo "helm smoke passed: rf-helm-smoke ${SMOKE_VERSION}"
