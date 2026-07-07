---
name: verify
description: Verify changes to charts/, gitops/, or ci/templates/ in this repo by rendering and validating everything CI would. Use after any chart, values, or CI-template change, and before committing.
---

# Verify changes in this repo

This repo has no runtime app — verification means proving the chart renders, the
YAML lints, and the manifests are schema-valid, exactly like CI does.

## Steps

1. **Lint**: `make lint` (helm lint --strict + yamllint; yamllint is skipped if
   not installed locally — CI still runs it, so treat local skips as untested).
2. **Render every env**: `make template` — renders `charts/app` with defaults
   and with each `gitops/apps/*/envs/*/values.yaml`. Any failure here is a
   regression a downstream app would hit on deploy.
3. **Schema-validate**: `make validate` (kubeconform -strict). If kubeconform
   is not installed, say so explicitly — do not claim validated.
4. **If `charts/app/values.yaml` changed**: confirm `charts/app/values.schema.json`
   still matches (new keys added to the schema, removed keys deleted). A schema
   mismatch fails child pipelines, not this repo's.
5. **If `ci/templates/*.gitlab-ci.yml` changed**: check every `extends:` /
   `!reference` target still exists across all templates, and confirm no job
   name, stage name, or documented variable (see docs/USAGE.md table) was
   renamed — that would be a breaking change requiring a major version bump.
   For deep API review, use the `ci-api-reviewer` agent.
6. **If `charts/app/templates/` changed**: render with a values file that
   exercises the changed template (e.g. production values enable HPA,
   ServiceMonitor, topology spread) and inspect the actual rendered output,
   not just the exit code:
   `helm template smoke charts/app -f gitops/apps/demo-app/envs/production/values.yaml`

## Report

State exactly what ran and what was skipped (missing tools). Never report
"verified" if only a subset ran.
