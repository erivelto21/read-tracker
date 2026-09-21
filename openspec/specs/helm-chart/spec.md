# Spec: Helm Chart

## Purpose

Defines the Helm chart capability for deploying the tracker stack from `helm/tracker/`, including namespace management, template layout, secret handling, and migration constraints from legacy Kubernetes manifests.

---

## Requirements

### Requirement: Chart lives under helm/tracker
The project SHALL contain a Helm chart at `helm/tracker/` with `Chart.yaml`, `values.yaml`,
and a `templates/` directory. The chart name SHALL be `tracker`.

#### Scenario: Chart is valid
- **WHEN** `helm lint ./helm/tracker` is run
- **THEN** it exits with code 0 and no errors

#### Scenario: Chart renders all resources
- **WHEN** `helm template tracker ./helm/tracker -f helm/tracker/values.secret.yaml` is run
- **THEN** it outputs 10 Kubernetes manifests: 2x Secret (api secrets + nginx-htpasswd), 2x ConfigMap (api + nginx), 3x Service (api + nginx + mongo), 2x Deployment (api + nginx), StatefulSet (mongo)

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
The file `deploy/helm/tracker/values.secret.yaml` SHALL be encrypted with SOPS + age and committed to the repository. Real secret values (MongoDB URI, htpasswd) SHALL only exist in `values.secret.yaml` in encrypted form and SHALL never appear in `values.yaml` or in git history. The `.sops.yaml` file at the repository root SHALL define the encryption rules using an age public key.

#### Scenario: values.secret.yaml is tracked but encrypted
- **WHEN** `git ls-files deploy/helm/tracker/values.secret.yaml` is run
- **THEN** the file is listed as tracked by git

#### Scenario: Secret values are not readable without the age key
- **WHEN** `cat deploy/helm/tracker/values.secret.yaml` is run
- **THEN** secret fields appear as `ENC[AES256_GCM,...]` ciphertext, not plaintext strings

#### Scenario: values.yaml has no real credentials
- **WHEN** `values.yaml` is inspected
- **THEN** secret fields (`mongodbUri`, `nginx.htpasswd`) are empty strings or placeholders

---

### Requirement: Templates organized in component subdirectories
All Helm templates SHALL live under `deploy/helm/tracker/templates/` in component subdirectories: `api/`, `db/`, `nginx/`. A `_helpers.tpl` file SHALL exist at the top level.

#### Scenario: Templates are organized in subdirectories
- **WHEN** `ls deploy/helm/tracker/templates/` is run
- **THEN** subdirectories `api/`, `db/`, `nginx/` are present alongside `_helpers.tpl`

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
