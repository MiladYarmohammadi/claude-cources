---
name: onboard-app
description: Onboard a new application to the platform — scaffold gitops/apps/<name>/envs/{dev,staging,production}/values.yaml and the child project's .gitlab-ci.yml. Use when asked to add, onboard, or scaffold a new app/service.
---

# Onboard a new app

Two deliverables: env values files in the GitOps tree, and a child
`.gitlab-ci.yml` for the app repo. Use `gitops/apps/demo-app/` and
`examples/child-project/` as the reference implementations.

## 1. GitOps env values

Create `gitops/apps/<name>/envs/<env>/values.yaml` for `dev`, `staging`,
`production`. Rules:

- **Only env-specific overrides** — chart defaults carry the security baseline;
  never restate defaults.
- `image.repository` set per app; `image.tag: "0000000"` with the comment that
  CI writes it (deploy-gitops template) — never hand-edited.
- dev: `replicaCount: 1`, `podDisruptionBudget.enabled: false`, staging issuer
  (`letsencrypt-staging`), debug-ish env.
- staging: ≥2 replicas (default), PDB on (default), staging or prod issuer.
- production: `autoscaling.enabled: true` (min ≥3), explicit `resources`
  (requests + memory limit, NO cpu limit), zone+host topology spread,
  `metrics.enabled` + `serviceMonitor` if the app exports metrics,
  `letsencrypt-prod` issuer.
- Namespace is NOT set in values — the ApplicationSet derives `<app>-<env>`.

## 2. Child .gitlab-ci.yml

Copy the pattern from `examples/child-project/.gitlab-ci.yml`: include the
templates from `platform/ci-templates` pinned to a `vX.Y.Z` tag (never a
branch), set `APP_NAME`, and remind that `GITOPS_REPO`/`GITOPS_TOKEN` come from
group-level CI/CD variables.

App contract (docs/CONVENTIONS.md): listens on 8080, metrics on 9090,
`/healthz` + `/readyz`, runs as uid/gid 10001 with read-only rootfs.

## 3. Verify

Render each new values file:
`helm template smoke charts/app -f gitops/apps/<name>/envs/<env>/values.yaml`
then run `make validate`.
