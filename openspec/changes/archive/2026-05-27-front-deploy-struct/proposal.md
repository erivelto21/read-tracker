## Why

The frontend app (`front/`) exists and is buildable but has no deployment artifacts — no Dockerfile content, no Helm templates. Without a deploy structure, the UI cannot be served in the cluster.

## What Changes

- `deploy/docker/Dockerfile.front` gains a real multi-stage build (Node build → nginx serve)
- New Helm templates added for `front-nginx`: Deployment, Service, ConfigMap (nginx config), and Secret (API credentials for header injection)
- `values.yaml` gains a `front` section (image, replicas, port)
- `api-nginx` Service type changes from `LoadBalancer` to `ClusterIP` — it is no longer internet-facing
- `front-nginx` becomes the single public entrypoint (LoadBalancer), protected by Basic Auth, and proxies `/api/` calls to `api-nginx` with injected credentials

## Capabilities

### New Capabilities
- `front-deploy`: Dockerfile and Helm manifests that build and serve the React SPA behind Basic Auth, with transparent credential injection for API proxying

### Modified Capabilities
- `helm-chart`: New templates added; total rendered manifest count increases; `api-nginx` Service type changes to ClusterIP

## Impact

- `deploy/docker/Dockerfile.front` — replace placeholder with multi-stage build
- `deploy/helm/tracker/templates/` — new `front/` subdirectory with 4 templates
- `deploy/helm/tracker/values.yaml` — new `front` block
- `deploy/helm/tracker/templates/nginx/nginx-service.yaml` — Service type `LoadBalancer` → `ClusterIP`
- `deploy/helm/tracker/values.secret.yaml` (SOPS) — needs `front.nginx.apiCredentials` secret entry
- `Makefile` — may need a build/push target for the front image
