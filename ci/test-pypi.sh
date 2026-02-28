#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
cp -R "${REPO_ROOT}/packages/python" "$work/pkg"

python -m pip install -q --upgrade pip build twine

sed -i.bak "s/^version = .*/version = \"${SMOKE_VERSION}\"/" "$work/pkg/pyproject.toml"
rm -f "$work/pkg/pyproject.toml.bak"

pushd "$work/pkg" >/dev/null
python -m build >/dev/null
python -m twine upload --non-interactive -u token -p "${REPOFLOW_PAT}" \
  --repository-url "${REPOFLOW_API_URL}/pypi/${REPOFLOW_WORKSPACE}/pypi-local/" dist/* >/dev/null

python -m venv .venv
source .venv/bin/activate
pip install "repoflow-pypi-smoke==${SMOKE_VERSION}" --index-url "https://token:${REPOFLOW_PAT}@${host_no_scheme}/api/pypi/${REPOFLOW_WORKSPACE}/pypi/simple" >/dev/null
python -c 'from repoflow_pypi_smoke import ping; assert ping()=="pong"'
deactivate
popd >/dev/null

echo "pypi smoke passed: repoflow-pypi-smoke==${SMOKE_VERSION}"
