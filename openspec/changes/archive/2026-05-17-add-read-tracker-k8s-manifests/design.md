# Design: Kubernetes deployment for read-tracker API

## Overview
This document captures the software design decisions for deploying the read-tracker API into Kubernetes (k8s). It reflects the current implementation choices: a Dockerfile at the repository root, an API Deployment with a ClusterIP service, an in-cluster NGINX fronting the API (LoadBalancer service), and MongoDB deployed as a StatefulSet with persistent storage. Secrets are provided by a Kubernetes Secret YAML (no runtime creation commands).

  Internet
     │
     ▼
  External LB (cloud) -> nginx (LoadBalancer svc)
                           │
                           ▼
                   read-tracker (ClusterIP svc)
                           │
                           ▼
                        mongo (StatefulSet + PVC)

## Goals
- Provide repeatable k8s manifests under k8s/ for local and cluster testing.
- Keep secrets in declarative YAML (k8s/secret.yaml).
- Ensure MongoDB uses persistent storage so data survives pod restarts.
- Expose the API via an in-cluster nginx load-balancer (config via ConfigMap).
- Allow port configuration via a ConfigMap rather than hard-coded envs.

## Key Design Decisions
1. Dockerfile
   - Multi-stage Go build located at repository root (`Dockerfile`). Builds from `tracker/cmd/api` and produces a small runtime image (Alpine). Exposes port 8080 by default.

2. API Port Configuration: ConfigMap
   - A ConfigMap (`read-tracker-config`) defines `PORT` (string). The Deployment uses `envFrom.configMapRef` to load the port value. This keeps runtime configuration declarative and cluster-editable.

3. Secrets: Declarative Secret YAML
   - A single Secret `read-tracker-secrets` (k8s/secret.yaml) contains `mongodb_uri` and `db_name` using `stringData` for readability. The API Deployment maps secret keys into environment variables expected by the app: `mongodb_uri` → env `MONGO_URI`, `db_name` → env `DB_NAME`.
   - For production, recommend external secret stores (Vault/Secrets Manager) or sealed-secrets.

4. MongoDB: StatefulSet + Headless Service + PVC
   - Mongo runs as a StatefulSet named `mongo` with `serviceName: "mongo"` and a headless Service (`clusterIP: None`).
   - Persistence: `volumeClaimTemplates` create a PVC named `mongo-data` per replica (requests: 5Gi, accessModes: ReadWriteOnce).
   - Single replica for simplicity in this change; convert to replica set + StatefulSet with init scripts for production.

5. NGINX as load‑balancer
   - In-cluster nginx Deployment reads `default.conf` from a ConfigMap (`nginx-config`) and proxies `http://read-tracker:8080`.
   - Exposed with a Service `nginx` of type `LoadBalancer` to get an external IP on clouds that support it. For local clusters, NodePort or port-forwarding is an alternative.

6. Services and Port mapping
   - `read-tracker` Service: ClusterIP, port 80 → targetPort 8080.
   - `nginx` Service: LoadBalancer, port 80.
   - `mongo` Service: headless (clusterIP None) to allow stable network identities for stateful pods.

## Environment mapping (implementation notes)
- config.Load() expects environment variables: `MONGO_URI`, `DB_NAME`, `PORT`.
- Deployment maps these as:
  - `PORT` via ConfigMap `read-tracker-config`
  - `MONGO_URI` via Secret `read-tracker-secrets` key `mongodb_uri` → env `MONGO_URI`
  - `DB_NAME` via Secret `read-tracker-secrets` key `db_name` → env `DB_NAME`

## Files produced (location: `k8s/` and repo root)
- Dockerfile           — repo root (multi-stage build)
- k8s/api/configmap.yaml
- k8s/api/deployment.yaml
- k8s/api/service.yaml
- k8s/nginx/configmap.yaml
- k8s/nginx/deployment.yaml
- k8s/nginx/service.yaml
- k8s/database/service.yaml (headless)
- k8s/database/statefulset.yaml
- k8s/secrets/secret.yaml

## Operational notes & tradeoffs
- StatefulSet + PVC provides persistence but not a production-ready replica set or backup strategy.
- Running Mongo in the same cluster is useful for dev/staging. For production prefer a managed DB or a fully configured Mongo replica set with backups.
- Secrets in YAML are convenient for dev; rotate and seal them for production.
- No liveness/readiness probes, resource requests/limits, or PodDisruptionBudgets were added in this change; add them in follow-up tasks.

## Acceptance criteria
- The manifests are in `k8s/` and reflect the design above.
- `kubectl apply -f k8s/` on a test cluster produces running pods and bound PVCs.
- API responds through nginx external endpoint; Mongo retains data after pod restarts.

## Next steps (suggested tasks)
1. Add liveness/readiness probes and resource requests/limits to Deployments and StatefulSet.
2. Add CI validation: `kubectl apply --dry-run=server` and `kubeval` (or similar) in CI.
3. Convert Mongo to replica set + readiness/liveness + init scripts for production, or switch to managed DB.
4. Commit SDD and k8s manifests and open PR for review.

