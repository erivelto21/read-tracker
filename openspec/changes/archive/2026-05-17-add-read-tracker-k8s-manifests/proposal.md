# Proposal: Add Kubernetes manifests for read-tracker API

## Summary
Add Kubernetes manifests under k8s/ to deploy the read-tracker HTTP API in-cluster. Deliverables: Deployment + ClusterIP Service for the API, in-cluster NGINX as a load‑balancer (ConfigMap + Deployment + Service), a MongoDB Deployment with a PersistentVolumeClaim (5Gi) and an internal ClusterIP Service, and a Kubernetes Secret to hold mongodb_uri and db_name.

## Motivation
Provide a simple, reproducible Kubernetes deployment for staging/cluster testing and a baseline for production hardening.

## Scope
In-scope:
- Files placed under project_root/k8s/
- API Deployment (image: erivelto/read-tracker:latest), Service type: ClusterIP (port 8080)
- NGINX Deployment + ConfigMap and Service (type: LoadBalancer)
- MongoDB Deployment (image: mongo:6.0) with PVC (5Gi) and Service (ClusterIP)
- Kubernetes Secret with keys: `mongodb_uri` and `db_name`

Out-of-scope:
- Helm charts, kustomize overlays, CI/CD integration, backups, MongoDB replica sets or StatefulSet (can be follow-up tasks)

## Design overview
Simple topology:

Internet -> NGINX (LoadBalancer svc) -> NGINX pod -> read-tracker Service (ClusterIP) -> read-tracker Pods
                            ↘
                             MongoDB (ClusterIP + PVC)

Notes: The API listens on port 8080 (project .env indicates PORT=8080). The API will receive DB connection info from a Secret. For compatibility, the Deployment maps secret keys into env vars MONGO_URI (or MONGODB_URI) and DB_NAME.

## Manifests to create
- k8s/namespace.yaml (optional: namespace `read-tracker`)
- k8s/read-tracker-deployment.yaml
- k8s/read-tracker-service.yaml (ClusterIP)
- k8s/nginx-configmap.yaml (nginx.conf)
- k8s/nginx-deployment.yaml
- k8s/nginx-service.yaml (LoadBalancer)
- k8s/mongo-deployment.yaml
- k8s/mongo-service.yaml (ClusterIP)
- k8s/mongo-pvc.yaml (PVC 5Gi)
- k8s/secret.yaml (Opaque secret containing `mongodb_uri` and `db_name`)

## Defaults / Assumptions
- App image: `erivelto/read-tracker:latest`, container port `8080`.
- NGINX image: `nginx:1.25` (or `nginx:latest`).
- Mongo image: `mongo:6.0`.
- PVC: 5Gi, default StorageClass used if available.
- Secret keys: `mongodb_uri`, `db_name`. Example secret create command:

```
kubectl create secret generic read-tracker-secrets \
  --from-literal=mongodb_uri='mongodb://mongo:27017' \
  --from-literal=db_name='readtracker'
```

The read-tracker Deployment should map the secret into environment variables expected by the app (e.g., `MONGO_URI` from secret key `mongodb_uri` and `DB_NAME` from `db_name`).

## Persistence & production note
Running MongoDB as a Deployment is acceptable for development and simple staging, but production should use a StatefulSet and a provisioned StorageClass, backups, and (optionally) replica sets.

## Tasks
1. Draft YAML manifests and place under `k8s/`.
2. Add a minimal `nginx.conf` in ConfigMap to proxy / to the API service.
3. Lint manifests and run `kubectl apply --dry-run=server` / test in minikube/kind.
4. Deploy to a cluster and perform a smoke test: hit the nginx external IP and validate API responses; confirm Mongo uses PVC.
5. Iterate: convert Mongo Deployment -> StatefulSet if production-ready cluster required.

## Acceptance criteria
- All YAML files exist under `k8s/` in the repository.
- `kubectl apply -f k8s/` brings up nginx, API, and MongoDB; API is reachable through nginx; MongoDB data persists across pod restarts via PVC; DB connection is injected via Secret.

## Risks / Open questions
- StatefulSet is recommended for DB in production.
- `LoadBalancer` service type depends on cloud provider (for local clusters use NodePort or port-forwarding).

## Next steps
If accepted, proceed to implement the manifests in `k8s/` and open a PR. If any defaults should change (image names, storage size, namespace), state them now.
