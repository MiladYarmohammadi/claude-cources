---
name: bump-tool-images
description: Update the pinned CI tool images (Kaniko, Trivy, Gitleaks, Helm, kubeconform, yamllint, hadolint, yq) in ci/templates/base.gitlab-ci.yml. Use when asked to bump, update, or renovate tool versions.
---

# Bump pinned tool images

All tool images are pinned in ONE place: the `variables:` block of
`ci/templates/base.gitlab-ci.yml` (`KANIKO_IMAGE`, `TRIVY_IMAGE`,
`GITLEAKS_IMAGE`, `HELM_IMAGE`, `KUBECONFORM_IMAGE`, `YAMLLINT_IMAGE`,
`HADOLINT_IMAGE`, `YQ_IMAGE`). Never pin a version anywhere else.

## Steps

1. For each image to bump, look up the latest stable release (WebSearch /
   WebFetch on the project's GitHub releases or registry tags). Keep the same
   variant suffix (`-debug` for Kaniko, `-alpine` where used) — jobs depend on
   the variant's entrypoint/shell.
2. Read the upstream changelog between the pinned and target versions for
   behavior changes that affect our job scripts (CLI flag renames, default
   changes — Trivy is the usual offender).
3. Edit only `base.gitlab-ci.yml`. Never use `latest` or a mutable tag.
4. Verify: `make lint && make validate`, and grep the other templates for any
   hardcoded versions that should have been variables.

## Versioning

Tool bumps don't change job names, stage names, or documented variables, so
they are a MINOR (behavior-visible, e.g. new Trivy findings) or PATCH bump —
never silently ride along in an unrelated MR; call out scanner bumps in the
changelog since they can start failing child pipelines with new findings.
