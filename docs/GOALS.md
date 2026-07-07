# Goals

Roadmap for evolving this platform repo. Ordered roughly by priority; check
items off as they land and note the release they shipped in.

## 1. Third-party / infrastructure apps

- [ ] Add a `gitops/infra/` directory for cluster-level third-party apps,
      deployed the same pull-based way as workloads (one directory per app,
      per-env values, Argo CD reconciles):
  - [ ] **Cilium** — CNI; prerequisite for enforcing our NetworkPolicies
        properly (and future L7 policies / Hubble observability)
  - [ ] **External Secrets Operator** — closes the gap in our secrets story:
        the chart deliberately never templates Secrets and expects
        `envFrom.secretRef`, but nothing installs ESO yet
  - [ ] **Rook-Ceph** — storage layer for stateful workloads
  - [ ] **cert-manager** — the env values already reference
        `cert-manager.io/cluster-issuer` annotations; make it a managed app
        with the ClusterIssuers defined here
  - [ ] **ingress-nginx** — chart defaults assume `className: nginx`
  - [ ] **kube-prometheus-stack** — the chart ships ServiceMonitor support;
        deploy the thing that scrapes it
- [ ] Decide the pattern: a second ApplicationSet over `infra/*/envs/*`
      (mirroring `apps/`), or app-of-apps. Infra apps need `cluster-admin`-ish
      permissions — give them their own AppProject with wider `destinations`/
      `clusterResourceWhitelist` instead of loosening the workloads project.
- [ ] Pin every third-party chart by exact version; document the upgrade
      procedure (diff rendered manifests before bumping).
- [ ] Sync waves / ordering: CNI and cert-manager must reconcile before
      workloads (Argo CD sync-wave annotations).

## 2. Secrets management (end-to-end)

- [ ] Pick and document the backend (Vault / cloud secret manager) for ESO.
- [ ] Add a `ClusterSecretStore` per env to `gitops/infra/`.
- [ ] Extend docs/USAGE.md with the full app-secrets workflow:
      ExternalSecret → K8s Secret → `envFrom.secretRef`.
- [ ] Optionally add an `externalSecrets` section to the generic chart so apps
      can declare ExternalSecrets via values (schema-validated).

## 3. Supply-chain security in CI

- [ ] SBOM generation (syft) attached as a pipeline artifact / release asset.
- [ ] Image signing with cosign (keyless, GitLab OIDC) in `build.gitlab-ci.yml`.
- [ ] Signature verification at admission (Kyverno policy in `gitops/infra/`).
- [ ] Renovate (or a scheduled pipeline) to propose bumps for the pinned tool
      images in `base.gitlab-ci.yml` and third-party chart versions —
      pins without automation go stale.

## 4. Policy as code

- [ ] Kyverno (or Gatekeeper) baseline policies that enforce at admission what
      the chart provides by default — non-root, read-only rootfs, dropped
      capabilities, resource requests — so a child project overriding the
      security context gets caught by the cluster, not just review.
- [ ] Add `kube-score`/`polaris` (or conftest) scoring of rendered manifests
      to the lint stage as a non-blocking report first, blocking later.

## 5. Chart & template quality

- [ ] helm-unittest tests for `charts/app` (assert rendered output for the
      tricky conditionals: PDB only when replicas > 1, HPA vs replicaCount,
      metrics wiring) — run in the `test` stage and in `make validate`.
- [ ] Publish the chart to the OCI registry in addition to the GitLab Helm
      package registry (OCI is where the ecosystem is heading).
- [ ] Support Job/CronJob workloads (either in the generic chart behind a
      `kind:`-style toggle, or a sibling `charts/cronjob`).
- [ ] Automated changelog / release notes from conventional commits
      (release-please or semantic-release) feeding `release.gitlab-ci.yml`.

## 6. GitOps operability

- [ ] Argo CD notifications (Slack/Teams) on sync failure and degraded health.
- [ ] Sync windows for production (block auto-activity outside business hours;
      staging/production already promote manually — encode it).
- [ ] Document the rollback runbook: `git revert` in the GitOps repo, and how
      to find "what was deployed when" from the commit history.
- [ ] Multi-cluster support: ApplicationSet cluster generator (matrix of
      cluster × app × env) once there is more than one cluster.
- [ ] E2E smoke test in CI: spin up kind, install Argo CD + the chart, deploy
      demo-app, assert it becomes healthy — proves the whole loop, not just
      rendering.

## 7. Documentation & onboarding

- [ ] Architecture diagram (app repo → CI → registry → GitOps repo → Argo CD →
      cluster) in the README.
- [ ] CONTRIBUTING.md for this repo: MR checklist, when a change is MAJOR
      (public API rules from docs/CONVENTIONS.md), how to test locally.
- [ ] Per-goal ADRs (lightweight, one file per decision) once choices like
      ESO backend, Kyverno vs Gatekeeper, or the infra ApplicationSet pattern
      are made — record the why, not just the what.
