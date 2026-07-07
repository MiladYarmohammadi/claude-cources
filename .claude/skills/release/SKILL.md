---
name: release
description: Cut a release of this repo — determine the correct semver bump from changes since the last tag, sync Chart.yaml versions, and create the annotated vX.Y.Z tag. Use when asked to release, tag, or publish a version.
---

# Cut a release

One annotated tag `vX.Y.Z` on `main` does everything: publishes the chart to
the GitLab Helm registry, tags the image alias, and creates the GitLab release
(release.gitlab-ci.yml + helm.gitlab-ci.yml react to `.rules:on-tag`).

## 1. Determine the bump

Diff since the last tag: `git describe --tags --abbrev=0` then
`git diff <last-tag>..HEAD --stat` and review `ci/templates/` + `docs/USAGE.md`.

- **MAJOR** — any rename/removal of a job name, stage name, or documented
  variable (the public API, per docs/CONVENTIONS.md); changed defaults that
  can break existing child pipelines; chart value removals/renames.
- **MINOR** — new opt-in jobs, new variables with safe defaults, new chart
  features, tool-image bumps that can surface new findings.
- **PATCH** — fixes with no contract change.

When unsure, run the `ci-api-reviewer` agent on the diff.

## 2. Pre-tag checklist

- Working tree clean, on `main`, up to date with origin.
- `make lint && make validate` pass.
- If `charts/app/` changed since the last tag: bump `version:` in
  `charts/app/Chart.yaml` (independent semver from the repo tag) and confirm
  `values.schema.json` matches `values.yaml`.

## 3. Tag

```bash
git tag -a vX.Y.Z -m "vX.Y.Z: <one-line summary>"
git push origin vX.Y.Z
```

Confirm with the user before pushing the tag — it is the publish action.
