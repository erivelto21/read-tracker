## Why

MongoDB currently runs as an in-cluster StatefulSet inside the Kubernetes cluster, which couples storage lifecycle to the cluster and prevents independent database management. Moving MongoDB to a dedicated VM on the same Magalu Cloud VPC eliminates this coupling, allowing the database to be managed, backed up, and scaled independently from the application workload.

## What Changes

- **Terraform**: Attach the `mongodb-study` VM to the K8s cluster VPC (`8dd43656-145b-4b9c-94f5-f2d3211d74ab`) and its subnet (`172.18.32.0/20`, AZ-c), so it shares the same private network as the K8s nodes.
- **Terraform**: Add a security group that restricts port `27017` ingress to the K8s node subnet CIDR (`172.18.0.0/18`), blocking all other access.
- **Terraform**: Update `cloud-init.sh` to configure MongoDB with authentication (username + password) and bind it to all interfaces (`0.0.0.0`) so it is reachable over the private network.
- **Helm**: Add a `mongodb.external.enabled` flag to `values.yaml` to switch between in-cluster StatefulSet and external VM.
- **Helm**: Make `db-statefulset.yaml` conditional — only rendered when `mongodb.external.enabled = false`.
- **Helm**: Make `db-service.yaml` conditional — renders an `ExternalName` Service pointing to the VM's MGC internal DNS hostname (`mongodb-study`) when `mongodb.external.enabled = true`; renders the original headless Service otherwise.
- **Helm secrets**: Update `values.secret.yaml` to flip `mongodb.external.enabled = true` and set the new `MONGO_URI` with credentials and the VM hostname.

No application code changes. The `tracker` API already reads `MONGO_URI` from environment — it will transparently connect to the new host.

## Capabilities

### New Capabilities

- `external-mongodb`: Infrastructure capability to route MongoDB traffic from the K8s cluster to an external VM-hosted MongoDB instance via a Kubernetes ExternalName Service, using MGC internal DNS for hostname resolution within the same VPC.

### Modified Capabilities

_None. No existing spec-level behavior changes._

## Impact

- **`deploy/terraform/`**: `main.tf`, `variables.tf`, `outputs.tf`, `cloud-init.sh`
- **`deploy/helm/tracker/`**: `values.yaml`, `templates/db/db-service.yaml`, `templates/db/db-statefulset.yaml`, new `templates/db/db-endpoints-external.yaml` (if needed)
- **`deploy/helm/tracker/values.secret.yaml`** (SOPS-encrypted): `secrets.mongodbUri` and `mongodb.external.enabled`
- **In-cluster MongoDB StatefulSet and its 10Gi PVC**: decommissioned when flag is flipped — existing data is intentionally discarded
