# Proposal: Helm Migration for Tracker Service

## Problem

The `tracker` service is deployed via raw `kubectl apply` across four ordered directories
(`k8s/secrets/`, `k8s/database/`, `k8s/api/`, `k8s/nginx/`). This approach has no
templating, no environment overrides, and commits secrets (htpasswd, MongoDB URI) in
plaintext. There is no way to do a clean rollback or diff a release.

## Proposed Solution

Introduce a Helm chart for the `tracker` service. The chart replaces `kubectl apply`
with `helm upgrade --install`, adds proper templating, and separates secrets from
committed code via a gitignored `values.secret.yaml`.

`nightcrawler` gets its own chart when it has deployable code — not now.

## Scope

### In scope
- Create `helm/tracker/` chart with all current resources templated
- Rename `k8s/` → `old-k8s/` (kept as reference, not deleted)
- Add `helm/tracker/values.secret.yaml` to `.gitignore`
- Update `Makefile` with `helm-apply` and `helm-down` targets
- Deploy into namespace `read-tracker`

### Out of scope
- `nightcrawler` chart (deferred — no deployable code yet)
- CI/CD pipeline
- Secrets manager (Vault, SOPS, External Secrets Operator)
- Multiple environments (dev/staging/prod)

## Chart Structure

```
helm/
└── tracker/
    ├── Chart.yaml
    ├── values.yaml               # committed — structure + safe defaults
    ├── values.secret.yaml        # gitignored — real secrets
    └── templates/
        ├── _helpers.tpl
        ├── namespace.yaml
        ├── secrets.yaml
        ├── api-configmap.yaml
        ├── api-deployment.yaml
        ├── api-service.yaml
        ├── db-statefulset.yaml
        ├── db-service.yaml
        ├── nginx-configmap.yaml
        ├── nginx-deployment.yaml
        └── nginx-service.yaml
```

## Values Design

`values.yaml` (committed — no real secrets):

```yaml
namespace: read-tracker

image:
  repository: container-registry.br-se1.magalu.cloud/my-register/read-tracker
  tag: latest
  pullPolicy: IfNotPresent

api:
  replicas: 2
  port: 8080

mongodb:
  image: mongo:6.0
  storage: 10Gi

nginx:
  image: nginx:1.25
  replicas: 1
  rateLimit:
    zone: api
    rate: 10r/s
    burst: 20

secrets:
  mongodbUri: ""
  dbName: "read_tracker"
  nginx:
    htpasswd: ""
```

`values.secret.yaml` (gitignored):

```yaml
secrets:
  mongodbUri: "mongodb://mongo:27017"
  dbName: "read_tracker"
  nginx:
    htpasswd: "user:$apr1$..."
```

## Deploy Command

```bash
helm upgrade --install tracker ./helm/tracker \
  --namespace read-tracker \
  --create-namespace \
  -f helm/tracker/values.secret.yaml
```

## Makefile Changes

Replace `kind-apply` / `down` with:

```makefile
helm-apply:
    helm upgrade --install tracker ./helm/tracker \
      --namespace read-tracker \
      --create-namespace \
      -f helm/tracker/values.secret.yaml

helm-down:
    helm uninstall tracker --namespace read-tracker
```

## Migration Path

1. Rename `k8s/` → `old-k8s/`
2. Create `helm/tracker/` chart
3. Update `.gitignore`
4. Update `Makefile`
5. Validate locally with `helm template` and `helm lint`
6. Deploy with `make helm-apply` against local kind cluster
7. Verify parity with old manifests

## Risks / Notes

- The `imagePullSecrets` (`magalu-registry-secret`) must exist in the `read-tracker`
  namespace before deploy — chart does not manage it (external pre-requisite)
- `old-k8s/` secrets files still contain plaintext credentials — should not be deployed
  after migration is complete
