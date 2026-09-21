## 1. Dockerfile

- [x] 1.1 Replace the placeholder content in `deploy/docker/Dockerfile.front` with a multi-stage build: Stage 1 (`node:22-alpine`) runs `npm ci && npm run build`; Stage 2 (`nginx:1.27-alpine`) copies `dist/` to `/usr/share/nginx/html`
- [x] 1.2 Verify the image builds successfully locally and contains no Node.js in the final layer

## 2. Helm Values

- [x] 2.1 Add a `front` block to `deploy/helm/tracker/values.yaml` with sub-keys: `image.repository`, `image.tag`, `replicas`, `port` (default 80), and `nginx.htpasswd` (empty placeholder)
- [x] 2.2 Add `secrets.front.apiCredentials` placeholder (empty string) to `deploy/helm/tracker/values.yaml`
- [x] 2.3 Edit `deploy/helm/tracker/values.secret.yaml` via `sops deploy/helm/tracker/values.secret.yaml` to add the real `secrets.front.apiCredentials` value (Base64 of `user:password`)

## 3. front-nginx Helm Templates

- [x] 3.1 Create `deploy/helm/tracker/templates/front/front-configmap.yaml`: ConfigMap with `default.conf` nginx config that applies `auth_basic` at server level, serves static files at `/`, and proxies `/api/` to `http://nginx:{{ .Values.api.port }}` with `proxy_set_header Authorization` sourced from an env var
- [x] 3.2 Create `deploy/helm/tracker/templates/front/front-secret.yaml`: Secret `front-nginx-api-credentials` with key `api_credentials` from `{{ .Values.secrets.front.apiCredentials }}`
- [x] 3.3 Create `deploy/helm/tracker/templates/front/front-nginx-secret.yaml`: Secret `front-nginx-htpasswd` with `.htpasswd` key from `{{ .Values.secrets.front.nginx.htpasswd }}` (or share the existing `nginx-htpasswd` secret by referencing it in the Deployment volume)
- [x] 3.4 Create `deploy/helm/tracker/templates/front/front-deployment.yaml`: Deployment for `front-nginx` that mounts the nginx ConfigMap and htpasswd Secret, and injects the `api_credentials` Secret as an env var consumed by the nginx config via `envsubst` wrapper
- [x] 3.5 Create `deploy/helm/tracker/templates/front/front-service.yaml`: Service of type `LoadBalancer` with selector `app: front-nginx`, port 80

## 4. Demote api-nginx to ClusterIP

- [x] 4.1 Change `spec.type` from `LoadBalancer` to `ClusterIP` in `deploy/helm/tracker/templates/nginx/nginx-service.yaml`

## 5. Makefile Targets

- [x] 5.1 Add `build-front` and `push-front` targets to the root `Makefile` following the same pattern as the existing `build-api` / `push-api` targets

## 6. Validation

- [x] 6.1 Run `helm lint ./deploy/helm/tracker` and confirm it exits with code 0
- [x] 6.2 Run `helm template tracker ./deploy/helm/tracker -f deploy/helm/tracker/values.secret.yaml` and confirm the manifest count matches the spec (15 resources)
- [x] 6.3 Deploy to cluster with `helm upgrade` and verify: `front-nginx` pod is Running, LoadBalancer IP assigned, UI loads, unauthenticated request returns 401, API proxy works end-to-end
