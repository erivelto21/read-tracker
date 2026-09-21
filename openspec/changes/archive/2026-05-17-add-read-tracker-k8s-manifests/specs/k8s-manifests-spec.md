# Specs: Kubernetes manifests for read-tracker

This file specifies the required fields and validation checks for the k8s manifests created in this change. Use this as a checklist when reviewing YAML files.

## 1) Dockerfile
- Location: `Dockerfile` (repo root)
- Multi-stage build that compiles `tracker/cmd/api` into a static binary and places it into a minimal runtime image (Alpine).
- Exposes port 8080.

Validation:
- `docker build -t erivelto/read-tracker:latest .` must succeed locally.

## 2) ConfigMap: API port
- File: `k8s/api/configmap.yaml`
- Keys: `PORT` (string)
- Name: `read-tracker-config`

Validation:
- Pods using `envFrom.configMapRef` see `PORT` set.

## 3) Secret: DB connection
- File: `k8s/secrets/secret.yaml`
- Name: `read-tracker-secrets`
- Keys (stringData): `mongodb_uri`, `db_name`

Validation:
- The secret should be applied declaratively (kubectl apply -f k8s/secret.yaml)
- The read-tracker Deployment must receive env `MONGO_URI` and `DB_NAME` (from secret keys)

## 4) API Deployment
- File: `k8s/api/deployment.yaml`
- Name: `read-tracker`
- Labels: `app: read-tracker`
- Replicas: >=1 (default 2 in current manifest)
- Container:
  - name: `read-tracker`
  - image: `erivelto/read-tracker:latest`
  - containerPort: 8080
  - envFrom: configMapRef `read-tracker-config`
  - env: `MONGO_URI` (secretKeyRef -> `mongodb_uri`), `DB_NAME` (secretKeyRef -> `db_name`)

Validation:
- Pod environment contains `PORT`, `MONGO_URI`, `DB_NAME`.
- If image is not present in cluster, CI should fail to pull or image should be loaded into local registry.

## 5) API Service
- File: `k8s/api/service.yaml`
- Type: ClusterIP
- selector: `app: read-tracker`
- ports: port 80 -> targetPort 8080

Validation:
- `kubectl get svc read-tracker` returns ClusterIP.

## 6) NGINX (ConfigMap, Deployment, Service)
- Files: `k8s/nginx/configmap.yaml`, `k8s/nginx/deployment.yaml`, `k8s/nginx/service.yaml`
- ConfigMap key: `default.conf` must define server that proxies `/` to `http://read-tracker:8080`.
- nginx Deployment must mount the config as `/etc/nginx/conf.d/default.conf` and expose container port 80.
- nginx Service type: LoadBalancer (cloud), port 80

Validation:
- External IP (if cloud) or NodePort/port-forward works for local clusters.
- Nginx proxies requests to the API and preserves headers.

## 7) MongoDB (StatefulSet + headless Service)
- Files: `k8s/database/service.yaml` (headless), `k8s/database/statefulset.yaml`
- Headless Service: `clusterIP: None`, name `mongo`.
- StatefulSet: serviceName `mongo`, replicas 1 (can be scaled later), container `mongo:6.0`, volumeMount `/data/db`.
- `volumeClaimTemplates` for `mongo-data` with storage request `5Gi`.
- Env: `MONGO_INITDB_DATABASE` sourced from Secret key `db_name`.

Validation:
- PVC created and bound for the StatefulSet pod.
- Data persists after deleting and re-creating the pod.

## Validation checklist (smoke tests)
1. Build the image: `docker build -t erivelto/read-tracker:latest .`
2. Apply manifests: `kubectl apply -f k8s/`
3. Wait for pods: `kubectl wait --for=condition=ready pod -l app=read-tracker --timeout=120s` (and for mongo and nginx)
4. Confirm API env: `kubectl exec -it <read-tracker-pod> -- printenv | grep MONGO`
5. Confirm persistence: create a document in Mongo, restart pod, check document still exists.
6. Confirm API endpoint via nginx: `curl http://<nginx-ip>/v1/...` returns expected results.

## Notes
- Secrets in `stringData` are not base64 encoded for readability in git. Consider using sealed-secrets or external secrets for secure storage.
- For local clusters (kind/minikube), the LoadBalancer type may require `minikube tunnel` or use a NodePort instead.

