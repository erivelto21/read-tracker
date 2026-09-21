## Context

The cluster currently exposes `api-nginx` as a `LoadBalancer` — it's the only public entrypoint and it guards the Go API with HTTP Basic Auth (htpasswd). The `front/` React app exists and builds, but has no deploy artifacts: `Dockerfile.front` is a placeholder and no Helm templates exist for a front service.

Adding a frontend deployment requires a public entrypoint that:
1. Serves the static React build
2. Proxies `/api/` requests to the existing `api-nginx`
3. Injects Basic Auth credentials so the browser never handles them
4. Protects the whole UI with Basic Auth (single-user app)

## Goals / Non-Goals

**Goals:**
- Serve the React SPA from inside the cluster via a dedicated `front-nginx` deployment
- Protect the entire frontend (static + API proxy) with HTTP Basic Auth
- Keep `api-nginx` unchanged except demoting its Service to ClusterIP
- Credentials injected at proxy layer — never exposed to the browser or JS bundle
- `Dockerfile.front` produces a minimal, production-ready nginx image

**Non-Goals:**
- Adding JWT or session-based auth (out of scope — single-user, Basic Auth is sufficient)
- TLS termination (handled externally by the cloud load balancer)
- CDN or asset caching strategies
- Changes to the Go API or nightcrawler

## Decisions

### Decision: `front-nginx` as a separate Deployment (not sidecar)

**Chosen:** Separate Deployment + Service for `front-nginx`.

**Alternatives considered:**
- *Sidecar in the API pod*: Couples lifecycle of frontend and API. Complicates scaling and rollback.
- *Replace api-nginx with front-nginx*: Would require merging two distinct nginx configs. Riskier.

**Rationale:** Separation of concerns. `api-nginx` keeps its existing rate-limiting and auth config untouched. `front-nginx` is independently deployable, scalable, and configurable.

---

### Decision: API credentials stored as a Kubernetes Secret, injected via `proxy_set_header`

**Chosen:** A dedicated Secret `front-nginx-api-credentials` holds `Authorization: Basic <base64>`. The nginx ConfigMap references it via `envsubst` or the value is mounted and read at startup.

**Simpler alternative:** Embed the `proxy_set_header` value directly in the ConfigMap.
→ Rejected: ConfigMaps are not encrypted at rest by default; credentials should live in Secrets.

**Rationale:** Credentials must not live in a ConfigMap. Using a Secret + env substitution in the nginx entrypoint keeps the nginx config template clean and the credential separate.

---

### Decision: `api-nginx` Service demoted from `LoadBalancer` to `ClusterIP`

**Chosen:** Change `api-nginx` Service type to `ClusterIP`.

**Rationale:** With `front-nginx` as the public entrypoint, `api-nginx` no longer needs a cloud load balancer. Removing the public IP reduces attack surface and cloud cost. `front-nginx` reaches `api-nginx` via internal DNS (`nginx.<namespace>.svc.cluster.local`).

---

### Decision: Multi-stage Docker build for `Dockerfile.front`

**Chosen:** Stage 1: `node:22-alpine` runs `npm ci && npm run build`. Stage 2: `nginx:1.27-alpine` copies `dist/` to `/usr/share/nginx/html`.

**Rationale:** Keeps the runtime image minimal (no Node, no source). Consistent with the existing API Dockerfile pattern.

---

### Decision: nginx config uses `auth_basic` on all locations

`front-nginx` applies `auth_basic` at the `server` block level so both static files and `/api/` proxy are protected. The htpasswd Secret is shared with (or mirrors) the existing `nginx-htpasswd` Secret.

## Risks / Trade-offs

- **Credential duplication** → The `api-nginx` htpasswd and the `front-nginx` API credentials derive from the same password but are stored as different Secret keys. A password rotation requires updating both Secrets. Mitigation: document in runbook; automate with SOPS.
- **nginx config complexity** → `envsubst` in the entrypoint is an extra moving part. Mitigation: bake the config generation into the Dockerfile or use a simple shell wrapper.
- **`api-nginx` demotion is a breaking infra change** → Any external scripts hitting the old `api-nginx` LoadBalancer IP will break. Mitigation: the only consumer is this single-user; document the new entrypoint clearly.

## Migration Plan

1. Build and push `front` image (`make build-front`, `make push-front`)
2. Run `helm upgrade tracker ./deploy/helm/tracker -f values.secret.yaml`
   - This creates `front-nginx` Deployment + Service (LoadBalancer)
   - This changes `api-nginx` Service to ClusterIP (existing LB IP is released)
3. Verify `front-nginx` LoadBalancer IP is assigned; confirm UI loads
4. Update DNS / bookmarks to the new IP

**Rollback:** `helm rollback tracker` restores `api-nginx` as LoadBalancer; delete `front-nginx` resources manually if needed.

## Open Questions

- Should `front-nginx` and `api-nginx` share the same htpasswd Secret, or maintain separate copies? (Currently: separate — simpler helm templating, slight duplication.)
