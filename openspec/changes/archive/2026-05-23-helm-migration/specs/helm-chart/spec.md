## ADDED Requirements

### Requirement: Chart lives under helm/tracker
The project SHALL contain a Helm chart at `helm/tracker/` with `Chart.yaml`, `values.yaml`,
and a `templates/` directory. The chart name SHALL be `tracker`.

#### Scenario: Chart is valid
- **WHEN** `helm lint ./helm/tracker` is run
- **THEN** it exits with code 0 and no errors

#### Scenario: Chart renders all resources
- **WHEN** `helm template tracker ./helm/tracker -f helm/tracker/values.secret.yaml` is run
- **THEN** it outputs 11 Kubernetes manifests: Namespace, Secret, 2x ConfigMap, 2x Service, 2x Deployment, StatefulSet, and PersistentVolumeClaim (via StatefulSet volumeClaimTemplate)

---

### Requirement: All resources deployed into read-tracker namespace
Every Kubernetes resource rendered by the chart SHALL target the `read-tracker` namespace.
The chart SHALL include a `Namespace` resource template so the namespace is created
automatically on first install.

#### Scenario: Namespace resource is rendered
- **WHEN** `helm template` is run
- **THEN** output includes a `kind: Namespace` resource with `name: read-tracker`

#### Scenario: All other resources carry the namespace
- **WHEN** `helm template` is run
- **THEN** every non-Namespace resource has `metadata.namespace: read-tracker`

---

### Requirement: Secrets are not committed to git
The file `helm/tracker/values.secret.yaml` SHALL be listed in `.gitignore`.
Real secret values (MongoDB URI, htpasswd) SHALL only exist in `values.secret.yaml`
and never in `values.yaml`.

#### Scenario: values.secret.yaml is ignored
- **WHEN** `git status` is checked after creating `helm/tracker/values.secret.yaml`
- **THEN** the file does not appear as a tracked or untracked file

#### Scenario: values.yaml has no real credentials
- **WHEN** `values.yaml` is inspected
- **THEN** secret fields (`mongodbUri`, `nginx.htpasswd`) are empty strings or placeholders

---

### Requirement: Flat templates directory with component-prefixed filenames
All Helm templates SHALL live directly under `helm/tracker/templates/` with filenames
prefixed by component: `api-`, `db-`, `nginx-`. No subdirectories are used.

#### Scenario: Templates are discoverable at the top level
- **WHEN** `ls helm/tracker/templates/` is run
- **THEN** all `.yaml` files are present at that level with no subdirectories (except `_helpers.tpl`)

---

### Requirement: Old manifests preserved under old-k8s
The existing `k8s/` directory SHALL be renamed to `old-k8s/` using `git mv`
to preserve history. It SHALL NOT be deleted and SHALL NOT be used for deployments
after migration.

#### Scenario: History is preserved after rename
- **WHEN** `git log --follow old-k8s/api/deployment.yaml` is run
- **THEN** the full commit history of the original file is shown

#### Scenario: old-k8s is not referenced in active deploy targets
- **WHEN** the Makefile `helm-apply` target is inspected
- **THEN** no reference to `old-k8s/` or `k8s/` appears in that target

---

### Requirement: imagePullSecret is a pre-requisite, not chart-managed
The chart SHALL reference `magalu-registry-secret` in the API deployment's
`imagePullSecrets` but SHALL NOT create the secret itself.

#### Scenario: Deployment template references pull secret
- **WHEN** `helm template` output is inspected for the API deployment
- **THEN** `imagePullSecrets` contains an entry with `name: magalu-registry-secret`

#### Scenario: Secret is not rendered by the chart
- **WHEN** `helm template` output is inspected
- **THEN** there is no `kind: Secret` resource named `magalu-registry-secret`
