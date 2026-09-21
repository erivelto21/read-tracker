## ADDED Requirements

### Requirement: helm-apply Makefile target deploys the chart
The Makefile SHALL contain a `helm-apply` target that runs `helm upgrade --install`
for the `tracker` chart into the `read-tracker` namespace with `--create-namespace`
and `-f helm/tracker/values.secret.yaml`.

#### Scenario: First-time install
- **WHEN** `make helm-apply` is run on a cluster with no prior release
- **THEN** all chart resources are created in the `read-tracker` namespace
- **THEN** `helm list -n read-tracker` shows release `tracker` with status `deployed`

#### Scenario: Upgrade on re-run
- **WHEN** `make helm-apply` is run on a cluster with an existing `tracker` release
- **THEN** the release is upgraded (not duplicated or errored)

---

### Requirement: helm-down Makefile target removes the release
The Makefile SHALL contain a `helm-down` target that runs
`helm uninstall tracker --namespace read-tracker`.

#### Scenario: Release is removed
- **WHEN** `make helm-down` is run
- **THEN** `helm list -n read-tracker` shows no `tracker` release
- **THEN** all chart-managed resources are deleted from the namespace

---

### Requirement: Legacy kubectl targets are superseded
The `kind-apply` and `down` Makefile targets SHALL be removed or marked as deprecated
with a comment pointing to the new Helm targets.

#### Scenario: Deprecated targets are not used for deployment
- **WHEN** deployment instructions are followed
- **THEN** only `make helm-apply` is referenced — not `make kind-apply`
