# Design: Helm Migration for Tracker Service

## Context

The `tracker` service currently deploys via `kubectl apply` in four ordered steps driven
by the `Makefile`. Secrets are committed as plaintext in `k8s/secrets/`. There is no
templating, no release history, and no way to diff or rollback a deployment.

The goal is to replace raw manifests with a Helm chart while keeping the workflow as
close to the current `make`-based flow as possible. There is no CI/CD pipeline — all
deploys are manual from a developer machine against a local `kind` cluster.

## Goals / Non-Goals

**Goals:**
- All 8 existing manifests rendered as Helm templates with no behavioral change
- Secrets removed from git via gitignored `values.secret.yaml`
- Single deploy command: `helm upgrade --install` (wrapped in Makefile target)
- Namespace `read-tracker` created automatically on first deploy
- Old manifests preserved under `old-k8s/` for reference

**Non-Goals:**
- `nightcrawler` chart (deferred)
- Multi-environment values files (dev/staging/prod)
- External secrets manager integration
- Helm subcharts or chart dependencies (e.g., bitnami/mongodb)
- CI/CD automation

## Decisions

### 1. Flat templates directory (not per-component subdirectories)

**Decision:** All templates live directly under `helm/tracker/templates/` prefixed by
component (`api-`, `db-`, `nginx-`), not in subdirectories.

**Rationale:** Helm resolves all `templates/**/*.yaml` recursively, so subdirectories
work. However, with only ~11 templates, a flat structure is simpler and avoids path
confusion. Subdirectories would add value only when the chart grows significantly.

**Alternative considered:** `templates/api/`, `templates/db/`, `templates/nginx/`
subdirectories — mirroring the old `k8s/` layout. Rejected for added complexity with
minimal gain at this scale.

---

### 2. Secrets via gitignored `values.secret.yaml` (not `--set` flags)

**Decision:** Real secret values live in `helm/tracker/values.secret.yaml`, gitignored.
Passed at deploy time with `-f helm/tracker/values.secret.yaml`.

**Rationale:** `--set` flags work but are error-prone on the command line (escaping,
especially for bcrypt htpasswd strings containing `$`). A file is reproducible and
reviewable locally. Since there is no pipeline, a local file is the simplest approach.

**Alternative considered:** `helm-secrets` plugin with SOPS encryption — correct for
team/CI setups, overkill for a single-developer local cluster.

---

### 3. Namespace managed by the chart (`namespace.yaml` template)

**Decision:** A `Namespace` resource is included in the chart templates. `helm upgrade
--install` is called with `--create-namespace` as a safety net.

**Rationale:** Keeps the chart self-contained. A developer cloning the repo and running
`make helm-apply` for the first time should not need to pre-create the namespace.

**Alternative considered:** Require the namespace to be pre-created (document in README).
Rejected — unnecessary manual step.

---

### 4. `imagePullSecret` (`magalu-registry-secret`) is a pre-requisite, not chart-managed

**Decision:** The chart references `magalu-registry-secret` in the API deployment's
`imagePullSecrets` but does not create the secret itself.

**Rationale:** The registry credential is a cluster-level pre-requisite tied to a
specific container registry account. It should not be embedded in the chart (would
require registry password in `values.secret.yaml`). It is a one-time manual step per
cluster, documented as a pre-requisite.

---

### 5. `old-k8s/` kept in repo, not deleted

**Decision:** Rename `k8s/` to `old-k8s/`. Never deploy from it after migration.

**Rationale:** The old manifests serve as a reference for diffing rendered Helm output
during migration validation. Deleting them removes a useful cross-check. The directory
name makes clear they are no longer the active deploy path.

## Risks / Trade-offs

| Risk | Mitigation |
|------|-----------|
| `values.secret.yaml` accidentally committed | Add to `.gitignore` before creating the file; verify with `git status` before any commit |
| `old-k8s/` secrets deployed by mistake | Rename only, add a comment in the Makefile that `old-k8s/` is reference only |
| `imagePullSecrets` missing in new namespace | Document as explicit pre-requisite; deployment will fail fast with a clear error if absent |
| Helm template rendering differs from raw manifests | Validate with `helm template . \| diff` against old manifests before switching over |
| htpasswd `$` characters in values.secret.yaml | Use YAML block scalar (`\|`) to avoid interpolation issues |

## Migration Plan

1. Rename `k8s/` → `old-k8s/` (git mv to preserve history)
2. Create `helm/tracker/` chart skeleton (`Chart.yaml`, `values.yaml`, `templates/`)
3. Port each manifest to a template, parameterising names, images, replicas, ports
4. Add `helm/tracker/values.secret.yaml` to `.gitignore`
5. Run `helm lint ./helm/tracker` — must pass clean
6. Run `helm template tracker ./helm/tracker -f values.secret.yaml` and diff against `old-k8s/`
7. Pre-create `magalu-registry-secret` in `read-tracker` namespace
8. `make helm-apply` — verify all pods come up healthy
9. Remove `kind-apply` / `down` Makefile targets (or leave as deprecated with a comment)

**Rollback:** `helm uninstall tracker -n read-tracker && kubectl apply -f old-k8s/secrets/ -f old-k8s/database/ -f old-k8s/api/ -f old-k8s/nginx/`

## Open Questions

- None — scope is well-defined and constrained to a single environment.
