# Using the mother project from a child project

## 1. Include the templates

```yaml
include:
  - project: platform/ci-templates
    ref: v1.0.0                # ALWAYS pin a tag
    file:
      - /ci/templates/base.gitlab-ci.yml      # required, include first
      - /ci/templates/lint.gitlab-ci.yml      # optional
      - /ci/templates/test.gitlab-ci.yml      # optional (extension points)
      - /ci/templates/build.gitlab-ci.yml     # optional
      - /ci/templates/security.gitlab-ci.yml  # optional
      - /ci/templates/helm.gitlab-ci.yml      # only if the project ships charts
      - /ci/templates/deploy-gitops.gitlab-ci.yml  # optional
      - /ci/templates/release.gitlab-ci.yml   # optional
```

`base.gitlab-ci.yml` is required by every other file (it defines the stages,
rule sets and tool-image variables).

## 2. Variable contract

| Variable | Default | Purpose |
|---|---|---|
| `APP_NAME` | `$CI_PROJECT_NAME` | Logical app name; keyed into GitOps paths |
| `CONTAINER_IMAGE` | `$CI_REGISTRY_IMAGE` | Image repo (no tag) |
| `IMAGE_TAG` | `$CI_COMMIT_SHORT_SHA` | Immutable per-commit tag — don't override |
| `DOCKERFILE_PATH` | `Dockerfile` | Dockerfile location |
| `DOCKER_CONTEXT` | `$CI_PROJECT_DIR` | Build context |
| `KANIKO_EXTRA_ARGS` | — | Extra Kaniko flags (`--build-arg …`) |
| `TRIVY_SEVERITY` | `HIGH,CRITICAL` | Severities reported |
| `TRIVY_EXIT_ON` | `CRITICAL` | Severities that fail the pipeline |
| `GITOPS_REPO` | — | **Required for deploy.** `host/group/gitops.git` |
| `GITOPS_TOKEN` | — | **Required for deploy.** Masked project access token |
| `GITOPS_BRANCH` | `main` | GitOps branch to commit to |
| `GITOPS_VALUES_PATH` | `apps/$APP_NAME/envs/$ENVIRONMENT/values.yaml` | File to patch |
| `GITOPS_IMAGE_KEY` | `.image.tag` | yq path of the tag field |

Set `GITOPS_REPO`/`GITOPS_TOKEN` as **group-level** CI/CD variables (masked,
protected) so every service inherits them.

## 3. Required GitLab configuration

- **Protect** the default branch and `v*` tags.
- Mark the `production` environment as **protected** (Settings → CI/CD →
  Protected environments) so only release managers can run `deploy:production`.
- Create the GitOps token as a **project access token** on the GitOps repo
  with role *Developer* and scope `write_repository`.

## 4. Adding tests

The templates can't know your toolchain; extend the provided bases:

```yaml
unit-tests:
  extends: .test:unit
  image: golang:1.23
  script:
    - go test ./... -coverprofile=cover.out
```

JUnit output at `reports/junit.xml` (override `TEST_REPORT_PATH`) is picked up
automatically for the MR test widget.

## 5. Overriding jobs

Standard GitLab semantics: redefining a job in the child project merges with
the included definition. Common patterns:

```yaml
# Skip a job entirely
hadolint:
  rules:
    - when: never

# Tighten security gates
trivy:image:
  variables:
    TRIVY_EXIT_ON: "HIGH,CRITICAL"

# Add a before_script to the image build (e.g. private npm token)
build:image:
  before_script:
    - !reference [.build:image, before_script]
    - echo "//registry.npmjs.org/:_authToken=$NPM_TOKEN" > .npmrc
```

## 6. Deployment flow

```
push to main ─▶ build:image (sha tag) ─▶ trivy:image ─▶ deploy:dev  (auto)
                                                        deploy:staging (manual)
                                                        deploy:production (manual)
```

Every environment receives the **same immutable image tag**; promotion is a
one-line values change committed to the GitOps repo, and Argo CD does the rest.
Rollback = `git revert` in the GitOps repo.

## 7. Consuming the generic Helm chart

The GitOps ApplicationSet already references the chart. To use it directly:

```bash
helm repo add platform https://gitlab.example.com/api/v4/projects/<id>/packages/helm/stable
helm install my-app platform/app -f values.yaml
```
