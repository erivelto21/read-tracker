## Context

The `read-tracker` system runs a Go REST API (`tracker`) and a MongoDB instance inside a Kubernetes cluster on Magalu Cloud (`br-se1`). MongoDB is deployed as a StatefulSet with a headless Service and a 10Gi PVC. The cluster VPC is `8dd43656-145b-4b9c-94f5-f2d3211d74ab` with node subnets in `172.18.0.0/18`. A separate MGC VM (`mongodb-study`) exists in the same cloud but is currently on the default network without VPC attachment, auth, or firewall restrictions.

## Goals / Non-Goals

**Goals:**
- Attach the MongoDB VM to the K8s cluster VPC so MGC internal DNS can resolve `mongodb-study` from within pods
- Secure port `27017` via a security group — accessible only from K8s node subnets (`172.18.0.0/18`)
- Enable MongoDB authentication via `cloud-init` at VM provisioning time
- Allow the Helm chart to switch between in-cluster and external MongoDB without requiring a chart version bump or structural changes
- Keep the existing StatefulSet available behind a feature flag for rollback

**Non-Goals:**
- Data migration from the in-cluster MongoDB — existing data is intentionally discarded
- TLS/SSL for MongoDB wire protocol (can be addressed in a future change)
- MongoDB replication or high availability on the VM
- Any changes to the `tracker` API application code

## Decisions

### Decision 1: ExternalName Service over Endpoints object

**Chosen**: Kubernetes `ExternalName` Service pointing to the MGC internal DNS hostname `mongodb-study`.

**Alternatives considered**:
- *Endpoints object with IP*: Works with bare IPs, but IP may change if the VM is recreated; requires manual Endpoints update.
- *Direct URI with VM IP*: Simplest, but couples the secret to a raw IP with no Kubernetes abstraction.

**Rationale**: Since the VM joins the K8s VPC, MGC internal DNS resolves `mongodb-study` by hostname. ExternalName gives a stable `mongo:27017` endpoint inside the cluster — unchanged from the current StatefulSet setup — and survives VM IP changes transparently.

### Decision 2: Helm conditional flag (`mongodb.external.enabled`)

**Chosen**: A boolean flag in `values.yaml` that gates StatefulSet rendering and toggles the Service type.

**Rationale**: The old StatefulSet + headless Service must remain deployable for rollback without editing templates. A single flag in `values.secret.yaml` is the operational lever — flipping it deploys the new wiring or reverts to in-cluster instantly.

### Decision 3: VPC attachment via Terraform (`vpc_id` + `subnet_id`)

**Chosen**: Attach `mongodb-study` to the same VPC and subnet (AZ-c, `172.18.32.0/20`) as the K8s node pool.

**Rationale**: Without explicit VPC assignment, the VM defaults to a shared network that may not share DNS resolution with the K8s cluster. Explicit attachment guarantees reachability and enables MGC internal DNS resolution.

### Decision 4: MongoDB auth via `cloud-init` (provisioning-time)

**Chosen**: Create a MongoDB user with `readWrite` on `read_tracker` during VM boot via `cloud-init.sh`, using a Terraform variable injected as a secret.

**Rationale**: Auth must be configured before any workload connects. `cloud-init` runs once at boot — idempotent enough for a single VM, and avoids a separate Ansible/manual step.

## Risks / Trade-offs

- **[Risk] VM hostname resolution depends on VPC alignment** → Mitigation: Terraform enforces VPC/subnet attachment; validate with `nslookup mongodb-study` from a pod before flipping the Helm flag.
- **[Risk] In-cluster PVC data is permanently lost** → Mitigation: Accepted and intentional per proposal; take a `mongodump` backup before decommissioning if data recovery is ever needed.
- **[Risk] `cloud-init` runs only once at first boot** → Mitigation: If re-provisioning is needed, `terraform destroy && terraform apply` re-runs the script. Auth setup is not idempotent on a live instance — document this clearly.
- **[Risk] `mongo_password` in Terraform state** → Mitigation: Use `sensitive = true` on the variable; state file should be stored in a remote backend (MGC object storage), not committed.

## Migration Plan

1. **Terraform**: Add `vpc_id`, `subnet_id`, `mongo_password` vars; attach VM to K8s VPC; add security group; update `cloud-init.sh` with auth setup. Run `terraform apply`.
2. **Validate connectivity**: From a pod in the cluster, verify `nslookup mongodb-study` resolves, and `mongosh mongodb://readtracker:<pass>@mongodb-study:27017` connects.
3. **Helm**: Add `mongodb.external` flag and conditional templates. Deploy with `mongodb.external.enabled = false` first (no behavior change) to validate chart renders correctly.
4. **Flip the switch**: Update `values.secret.yaml` (SOPS) with `mongodb.external.enabled: true` and new `mongodbUri`. Run `helm upgrade`.
5. **Decommission**: Once stable, manually delete the in-cluster PVC (`mongo-data-mongo-0`) to release storage.

**Rollback**: Set `mongodb.external.enabled: false` in secrets and run `helm upgrade`. In-cluster StatefulSet resumes immediately (with empty PVC).

## Open Questions

- _None. All decisions resolved during architecture exploration._
