# GitOps repository layout

This directory is the blueprint for the **GitOps repo** (usually a separate
repository, e.g. `platform/gitops`) that Argo CD watches. The
`deploy-gitops.gitlab-ci.yml` template commits image-tag bumps here.

```
argocd/
  appproject.yaml        Argo CD project: allowed repos, destinations, RBAC
  applicationset.yaml    One Application per apps/<name>/envs/<env> directory
apps/
  <app-name>/
    envs/
      dev/values.yaml         <- CI writes .image.tag here (auto)
      staging/values.yaml     <- CI writes .image.tag here (manual promote)
      production/values.yaml  <- CI writes .image.tag here (manual promote)
```

## How it fits together

1. CI in the app repo builds `registry/.../app:<sha>` and commits
   `.image.tag = <sha>` to `apps/<app>/envs/dev/values.yaml`.
2. The ApplicationSet's git generator discovers every `apps/*/envs/*`
   directory and generates one Argo CD Application per app+env.
3. Each Application pulls the generic `app` chart from the mother project's
   Helm registry and overlays the env values file from this repo
   (multi-source with `ref: values`).
4. Argo CD auto-syncs dev; staging/production sync policies can be made
   manual by editing the ApplicationSet template or using sync windows.

## Conventions

- Environment = directory name (`dev`, `staging`, `production`); it becomes
  the target namespace `<app>-<env>` and the Application name.
- Values files contain ONLY env-specific overrides; chart defaults carry
  the security baseline.
- Never edit `image.tag` by hand except for emergency rollback — and then
  still via a commit (audit trail), never `argocd app set`.
