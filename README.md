# Platform CI/CD Mother Project

Reusable, production-ready GitLab CI/CD templates, a generic Helm chart, and GitOps
(Argo CD) manifests. Downstream ("child") projects include this repository to get a
complete build → test → scan → package → deploy pipeline with Kubernetes best
practices baked in.

## Repository layout

```
ci/templates/          GitLab CI templates meant to be include:d by child projects
  base.gitlab-ci.yml       Workflow rules, stages, shared defaults
  lint.gitlab-ci.yml       yamllint, hadolint, helm lint, kubeconform
  build.gitlab-ci.yml      Container image build & push with Kaniko (no DinD)
  test.gitlab-ci.yml       Unit-test hook jobs (language-agnostic extension points)
  security.gitlab-ci.yml   Gitleaks secret scan, Trivy image/fs/config scans
  helm.gitlab-ci.yml       Helm chart lint, package, push to GitLab Helm registry
  deploy-gitops.gitlab-ci.yml  Pull-based deploy: bump image tag in the GitOps repo
  release.gitlab-ci.yml    Tag-driven release job (changelog + GitLab release)
charts/app/            Generic application Helm chart (deployment, HPA, PDB, ...)
gitops/                Argo CD bootstrap: projects, ApplicationSet, env values
examples/child-project GitLab CI of a downstream service consuming this project
docs/                  Usage & convention documentation
```

## Quick start for a child project

`.gitlab-ci.yml` of the child project:

```yaml
include:
  - project: platform/ci-templates        # path of THIS repo in your GitLab
    ref: v1.0.0                           # always pin a tag, never a branch
    file:
      - /ci/templates/base.gitlab-ci.yml
      - /ci/templates/lint.gitlab-ci.yml
      - /ci/templates/build.gitlab-ci.yml
      - /ci/templates/security.gitlab-ci.yml
      - /ci/templates/deploy-gitops.gitlab-ci.yml

variables:
  APP_NAME: my-service
  GITOPS_REPO: gitlab.example.com/platform/gitops.git
```

See [docs/USAGE.md](docs/USAGE.md) for the full contract (variables, override
points, required CI/CD settings) and [examples/child-project](examples/child-project)
for a complete working example.

## Design principles

- **Pin by tag** — child projects include templates at an immutable `ref`.
- **No docker-in-docker** — images are built with Kaniko; no privileged runners.
- **Pull-based GitOps** — CI never talks to the cluster. The deploy job commits an
  image-tag bump to the GitOps repo; Argo CD reconciles it.
- **Secure by default** — the Helm chart ships non-root, read-only rootfs, dropped
  capabilities, PDB, NetworkPolicy and probes enabled out of the box.
- **Override, don't fork** — every job exposes variables and `extends`-able hidden
  jobs so child projects customize without copying template code.

## Versioning

Semantic tags (`vMAJOR.MINOR.PATCH`). Breaking changes to job names, stage names,
or required variables bump MAJOR. The Helm chart is versioned independently via
`charts/app/Chart.yaml` and published to the GitLab Helm package registry on tags.
