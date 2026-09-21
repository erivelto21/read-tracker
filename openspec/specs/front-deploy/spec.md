# Spec: Front Deploy

## Purpose

Defines how the React frontend is built and served in the cluster. The `nginx` deployment serves as the single public entrypoint: it protects everything with HTTP Basic Auth, serves static React files at `/`, and proxies `/api/` requests directly to the Go API.

---

## Requirements

### Requirement: Dockerfile.front produces a minimal production image
`Dockerfile.front` SHALL use a multi-stage build: a `node:22-alpine` build stage runs `npm ci && npm run build`, and a `nginx:1.27-alpine` runtime stage copies `dist/` to `/usr/share/nginx/html`. No Node.js or source code SHALL be present in the final image.

#### Scenario: Image builds successfully
- **WHEN** `docker build -f deploy/docker/Dockerfile.front -t read-tracker-front .` is run from the repo root
- **THEN** it exits with code 0 and produces an image based on `nginx:1.27-alpine`

#### Scenario: Runtime image contains no Node.js
- **WHEN** the built image is inspected
- **THEN** `node` and `npm` are not present in the image filesystem

---

### Requirement: nginx serves the React SPA at /
The nginx ConfigMap SHALL configure `location /` to serve static files from `/usr/share/nginx/html` with `try_files $uri $uri/ /index.html` for SPA routing. The nginx Deployment SHALL use the `read-tracker-front` image.

#### Scenario: Static assets are reachable
- **WHEN** a request is made to `GET /` through the nginx Service with valid credentials
- **THEN** the response returns the React app HTML with status 200

#### Scenario: SPA deep links resolve
- **WHEN** a request is made to `GET /some/deep/route` through the nginx Service
- **THEN** nginx returns `index.html` (status 200) instead of a 404

---

### Requirement: nginx is the single public entrypoint
The `nginx` Service SHALL be of type `LoadBalancer`. The `read-tracker` (Go API) Service SHALL be of type `ClusterIP`.

#### Scenario: nginx Service is LoadBalancer
- **WHEN** `kubectl get svc -n read-tracker nginx` is run
- **THEN** `TYPE` is `LoadBalancer` and an external IP is assigned

---

### Requirement: Entire frontend is protected by HTTP Basic Auth
The nginx config SHALL apply `auth_basic` at the `server` block level, covering both static file serving (`/`) and the API proxy (`/api/`). Unauthenticated requests SHALL receive a 401 response.

#### Scenario: Unauthenticated request is rejected
- **WHEN** a request is made to `GET /` without an `Authorization` header
- **THEN** the response status is 401

#### Scenario: Authenticated request succeeds
- **WHEN** a request is made to `GET /` with valid Basic Auth credentials
- **THEN** the response status is 200

---

### Requirement: API calls proxied transparently to Go API
The nginx config SHALL proxy `/api/` requests to `http://read-tracker:<api.port>/`, stripping the `/api/` prefix. No credentials are injected — nginx communicates with the Go API directly over the internal cluster network.

#### Scenario: API call reaches Go API
- **WHEN** an authenticated browser makes a request to `GET /api/titles`
- **THEN** nginx forwards it as `GET /titles` to the Go API and returns the JSON response

---

### Requirement: Rate limiting applies to API proxy
The nginx config SHALL apply rate limiting (`limit_req`) on `location /api/` using the zone defined in `rate_limit.conf`. Static file serving at `location /` SHALL NOT be rate limited.

#### Scenario: Rate limit zone applied to /api/
- **WHEN** the rendered nginx `default.conf` is inspected
- **THEN** `limit_req` directive is present in `location /api/` and absent from `location /`
