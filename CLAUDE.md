# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

A GitLab CI/CD "mother project": reusable pipeline templates (`ci/templates/`), a generic application Helm chart (`charts/app/`), and an Argo CD GitOps blueprint (`gitops/`). There is no application code — downstream "child" projects `include:` the templates (pinned to a `vX.Y.Z` tag) to get a full build → scan → package → deploy pipeline. `examples/child-project/` shows a complete consumer.

## Commands

The Makefile mirrors what CI runs:

```bash
make lint       # helm lint --strict + yamllint
make template   # render chart with defaults and every gitops/apps/*/envs/*/values.yaml
make validate   # template + kubeconform -strict schema validation
make package    # helm package into .packaged/
```

Render against a single env values file:

```bash
helm template smoke charts/app -f gitops/apps/demo-app/envs/dev/values.yaml
```

There is no unit-test suite; "testing" a change means rendering the chart against all env values files and kubeconform-validating the output. Chart values are also constrained by `charts/app/values.schema.json` — keep it in sync when adding values.

## Architecture

Three artifacts that interlock:

1. **CI templates** (`ci/templates/*.gitlab-ci.yml`) — `base.gitlab-ci.yml` must be included first by every consumer: it defines the workflow rules, the canonical stage list, reusable `.rules:*` rule sets, and pinned tool-image variables (`KANIKO_IMAGE`, `TRIVY_IMAGE`, …) that every other template references. Images are built with Kaniko (no docker-in-docker); CI never talks to the cluster.
2. **Generic Helm chart** (`charts/app/`) — deployed for every app; env values files contain only overrides, the chart defaults carry the security baseline (non-root uid 10001, read-only rootfs, dropped capabilities, PDB, NetworkPolicy, probes). Secrets are never templated; apps reference them via `envFrom.secretRef`.
3. **GitOps blueprint** (`gitops/`) — the `deploy-gitops` template commits an `.image.tag` bump to `apps/<app>/envs/<env>/values.yaml` in a (normally separate) GitOps repo; the ApplicationSet git generator creates one Argo CD Application per `apps/*/envs/*` directory, pulling the chart from the Helm registry and overlaying the env values. Deploys and rollbacks are always git commits, never direct cluster operations.

This repo's own `.gitlab-ci.yml` dogfoods the templates via `include: local:` and additionally lints each template through the GitLab CI lint API and renders the chart against each gitops env values file.

## Claude Code project config

- **Skills** (`.claude/skills/`): `verify` (render + validate everything CI would — run before committing), `onboard-app` (scaffold gitops env values + child CI for a new service), `bump-tool-images` (update pinned tool versions in `base.gitlab-ci.yml`), `release` (semver decision + annotated tag).
- **Agents** (`.claude/agents/`): `ci-api-reviewer` (detects public-API breakage in template changes and names the required semver bump), `chart-security-reviewer` (catches security-baseline regressions and values.schema.json drift). Both read-only; use them before releases and on non-trivial chart/template diffs.
- **Hooks**: every Edit/Write is auto-linted by `.claude/hooks/lint-on-edit.sh` (yamllint on YAML, `helm lint --strict` on chart files). Fix hook feedback immediately rather than accumulating lint debt.
- **Permissions** (`.claude/settings.json`): the local toolchain (make/helm/yamllint/kubeconform/yq, read-only git) is pre-allowed. Cluster-mutating commands (`kubectl apply/delete/...`, `argocd app set/sync`, `helm install/upgrade`) are denied by policy — this repo's contract is pull-based GitOps; deploys happen only as commits to the GitOps repo.
- **MCP** (`.mcp.json`): a GitLab server for MRs/pipelines; it needs `GITLAB_TOKEN` (and optionally `GITLAB_API_URL` for self-hosted) exported in the environment.

## Rules that constrain changes

- **Job names, stage names, and documented variables are the public API.** Renaming any of them is a breaking change requiring a major version bump. The variable contract is documented in `docs/USAGE.md`.
- New jobs must be opt-in (rules with `exists:` or disabled by default).
- Tool images are pinned by version only in `base.gitlab-ci.yml`; bump them there, nowhere else.
- The chart is versioned independently via `charts/app/Chart.yaml` and published on `v*` tags.
- Platform conventions (ports 8080/9090, `/healthz`//`/readyz`, namespace `<app>-<env>`, no CPU limits, ≥2 replicas + PDB in staging/prod) live in `docs/CONVENTIONS.md`.