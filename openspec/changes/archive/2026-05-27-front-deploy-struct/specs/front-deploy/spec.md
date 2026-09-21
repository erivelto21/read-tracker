## ADDED Requirements

### Requirement: Dockerfile.front produces a minimal production image
`Dockerfile.front` SHALL use a multi-stage build: a `node:22-alpine` build stage runs `npm ci && npm run build`, and a `nginx:1.27-alpine` runtime stage copies `dist/` to `/usr/share/nginx/html`. No Node.js or source code SHALL be present in the final image.

#### Scenario: Image builds successfully
- **WHEN** `docker build -f deploy/docker/Dockerfile.front -t read-tracker-front .` is run from the repo root
- **THEN** it exits with code 0 and produces an image based on `nginx:1.27-alpine`

#### Scenario: Runtime image contains no Node.js
- **WHEN** the built image is inspected
- **THEN** `node` and `npm` are not present in the image filesystem

#### Scenario: Static files are served at root
- **WHEN** the container is started and a request is made to `GET /`
- **THEN** the response is the React app's `index.html` with status 200

---

### Requirement: front-nginx Deployment serves the React SPA
The Helm chart SHALL include a `front-nginx` Deployment in `deploy/helm/tracker/templates/front/` that runs the `read-tracker-front` image and mounts an nginx ConfigMap.

#### Scenario: front-nginx pod reaches Running state
- **WHEN** `helm upgrade` is applied and pods settle
- **THEN** a pod with label `app: front-nginx` reaches `Running` state

#### Scenario: Static assets are reachable
- **WHEN** a request is made to `GET /` through the front-nginx Service
- **THEN** the response returns the React app HTML with status 200

---

### Requirement: front-nginx is the single public entrypoint
The `front-nginx` Service SHALL be of type `LoadBalancer`. The `api-nginx` Service SHALL be of type `ClusterIP` so it is not directly reachable from the internet.

#### Scenario: front-nginx Service is LoadBalancer
- **WHEN** `kubectl get svc -n read-tracker front-nginx` is run
- **THEN** `TYPE` is `LoadBalancer` and an external IP is assigned

#### Scenario: api-nginx Service is ClusterIP
- **WHEN** `kubectl get svc -n read-tracker nginx` is run
- **THEN** `TYPE` is `ClusterIP` and no external IP is assigned

---

### Requirement: Entire frontend is protected by HTTP Basic Auth
The `front-nginx` nginx config SHALL apply `auth_basic` at the `server` block level, covering both static file serving and the `/api/` proxy location. Unauthenticated requests SHALL receive a 401 response.

#### Scenario: Unauthenticated request is rejected
- **WHEN** a request is made to `GET /` without an `Authorization` header
- **THEN** the response status is 401

#### Scenario: Authenticated request succeeds
- **WHEN** a request is made to `GET /` with valid Basic Auth credentials
- **THEN** the response status is 200

---

### Requirement: API proxy injects credentials transparently
The `front-nginx` nginx config SHALL proxy `/api/` requests to `api-nginx` and inject a `proxy_set_header Authorization` value sourced from a Kubernetes Secret. The browser SHALL NOT need to supply credentials for API calls.

#### Scenario: API call proxied with injected credentials
- **WHEN** an authenticated browser makes a request to `GET /api/titles`
- **THEN** `front-nginx` forwards the request to `api-nginx` with the correct `Authorization: Basic ...` header injected

#### Scenario: Credentials not exposed in nginx ConfigMap
- **WHEN** `kubectl get configmap -n read-tracker front-nginx-config -o yaml` is run
- **THEN** the output contains no plaintext credentials

---

### Requirement: API credentials stored in a Kubernetes Secret
The Base64-encoded Basic Auth value for API proxying SHALL be stored in a dedicated Secret (`front-nginx-api-credentials`) managed via SOPS-encrypted `values.secret.yaml`.

#### Scenario: Secret exists after helm install
- **WHEN** `helm upgrade` is applied
- **THEN** `kubectl get secret -n read-tracker front-nginx-api-credentials` exits with code 0

#### Scenario: Secret value is not committed in plaintext
- **WHEN** `git show HEAD:deploy/helm/tracker/values.secret.yaml` is run
- **THEN** the output is SOPS-encrypted and the raw credential is not readable
