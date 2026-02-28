# homelab-repoflow-smoke

CI smoke repository for validating RepoFlow publish/pull workflows using real project directories that Jenkins builds.

## Repository layout

- `packages/npm`: Node package published to npm-local and installed from npm (virtual)
- `packages/python`: Python package built and uploaded to pypi-local, then installed from pypi (virtual)
- `packages/go`: Go module/app built with dependencies resolved through Go virtual proxy
- `charts/rf-helm-smoke`: Helm chart packaged and uploaded to helm-local, then pulled from helm (virtual)
- `assets/universal`: Files packaged and uploaded to universal-local, then downloaded from universal (virtual)
- `docker`: Docker context built and pushed to docker-local, then pulled from docker (virtual)
- `ci/`: CI stage scripts used by `Jenkinsfile`

## Jenkins parameters

- `REPOFLOW_BASE_URL` (default: `https://repoflow.erauner.dev`)
- `REPOFLOW_WORKSPACE` (default: `homelab`)
- `REPOFLOW_PAT` (required)
- `RUN_DOCKER` (default: `false`)

## Notes

- Docker stage is optional because it requires daemon access in the Jenkins agent runtime.
- Go stage currently uses `GOSUMDB=off` because RepoFlow Go sumdb proxy support is not enabled.
