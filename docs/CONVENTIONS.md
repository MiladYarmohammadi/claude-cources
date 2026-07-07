# Platform conventions

## Images

- Tag = short commit SHA; images are immutable, `latest` exists only as a
  convenience alias on the default branch and is never deployed.
- Images run as uid/gid `10001` with a read-only root filesystem and no
  capabilities. Build your Dockerfile accordingly (see examples/child-project).
- App listens on `8080` (HTTP) and, if it exports metrics, `9090`.
- Health endpoints: `/healthz` (liveness) and `/readyz` (readiness).

## Kubernetes

- One namespace per app+env: `<app>-<env>`.
- Requests are always set; memory limit is set; CPU limit is intentionally
  omitted (avoids throttling; requests still guarantee scheduling).
- ≥2 replicas + PDB in staging/production; HPA in production.
- NetworkPolicy default: same-namespace ingress only.
- Secrets are NOT templated in the chart — use External Secrets Operator or
  sealed-secrets and reference them via `envFrom.secretRef`.

## Git / releases

- Trunk-based: short-lived branches, MR pipelines, merge to `main`.
- Release = annotated tag `vX.Y.Z` on `main`; that single tag publishes the
  chart, tags the image, and creates the GitLab release.
- The GitOps repo is the deployment ledger: every deploy/rollback is a commit.

## Template evolution (this repo)

- Job names, stage names and documented variables are the public API;
  renaming any of them is a breaking change → major version bump.
- New jobs must be opt-in (rules with `exists:` or disabled by default).
- Pin every tool image by version in `base.gitlab-ci.yml`; renovate/bump them
  centrally there.
