## 1. Prepare Repository

- [x] 1.1 Rename `k8s/` to `old-k8s/` using `git mv k8s old-k8s`
- [x] 1.2 Add `helm/tracker/values.secret.yaml` to `.gitignore`

## 2. Create Chart Skeleton

- [x] 2.1 Create `helm/tracker/Chart.yaml` with name `tracker`, version `0.1.0`, appVersion `1.0`
- [x] 2.2 Create `helm/tracker/values.yaml` with all configurable values (replicas, images, ports, resource names, empty secret placeholders)
- [x] 2.3 Create `helm/tracker/templates/_helpers.tpl` with a `tracker.labels` named template

## 3. Port Manifests to Templates

- [x] 3.1 Create `templates/namespace.yaml` — `kind: Namespace` for `read-tracker`
- [x] 3.2 Create `templates/secrets.yaml` — renders `read-tracker-secrets` from `values.secrets.*`
- [x] 3.3 Create `templates/api-configmap.yaml` — ports `k8s/api/configmap.yaml`, parameterise `PORT`
- [x] 3.4 Create `templates/api-deployment.yaml` — ports `k8s/api/deployment.yaml`, parameterise image, replicas, secret refs, `imagePullSecrets`
- [x] 3.5 Create `templates/api-service.yaml` — ports `k8s/api/service.yaml`, parameterise port
- [x] 3.6 Create `templates/db-statefulset.yaml` — ports `k8s/database/statefulset.yaml` (now `old-k8s`), parameterise image, storage
- [x] 3.7 Create `templates/db-service.yaml` — ports `old-k8s/database/service.yaml`
- [x] 3.8 Create `templates/nginx-configmap.yaml` — ports nginx config, parameterise rate limit zone/rate/burst via values
- [x] 3.9 Create `templates/nginx-deployment.yaml` — ports `old-k8s/nginx/deployment.yaml`, parameterise image, replicas, secret/configmap refs
- [x] 3.10 Create `templates/nginx-service.yaml` — ports `old-k8s/nginx/service.yaml`
- [x] 3.11 Create `templates/nginx-secret.yaml` — renders `nginx-htpasswd` secret from `values.secrets.nginx.htpasswd`

## 4. Create values.secret.yaml

- [x] 4.1 Create `helm/tracker/values.secret.yaml` (gitignored) with real values copied from `old-k8s/secrets/`
- [x] 4.2 Verify `git status` does not show `values.secret.yaml` as tracked

## 5. Validate

- [x] 5.1 Run `helm lint ./helm/tracker` — must pass with no errors
- [x] 5.2 Run `helm template tracker ./helm/tracker -f helm/tracker/values.secret.yaml` and confirm 11 resources are rendered
- [x] 5.3 Diff rendered output against `old-k8s/` manifests and confirm no unintended differences

## 6. Update Makefile

- [x] 6.1 Add `helm-apply` target: `helm upgrade --install tracker ./helm/tracker --namespace read-tracker --create-namespace -f helm/tracker/values.secret.yaml`
- [x] 6.2 Add `helm-down` target: `helm uninstall tracker --namespace read-tracker`
- [x] 6.3 Mark `kind-apply` and `down` targets as deprecated with a comment

## 7. Deploy and Verify

- [x] 7.1 Pre-create `magalu-registry-secret` in the `read-tracker` namespace if not present
- [x] 7.2 Run `make helm-apply` and confirm all pods reach `Running` state
- [x] 7.3 Run `helm list -n read-tracker` and confirm release `tracker` shows status `deployed`
- [x] 7.4 Run `make helm-down` and confirm all resources are removed from the namespace
