## Why

Production currently runs on a Magalu Cloud managed Kubernetes cluster that costs far more than the workload justifies: three control-plane nodes and a worker pool carry a single low-traffic API, one nginx serving a React SPA, and a MongoDB instance. The project needs the same production behavior at a fraction of the cost, on a single VM that hosts every workload plus the database.

## What Changes

- Add a new `deploy/terraform/app-vm/` Terraform stack that provisions one Magalu Cloud VM, its own VPC and subnet, a security group, a reserved public IP, and a dedicated block-storage data volume. The VM flavor, volume size, and volume type are configurable variables with `BV2-2-40` as the default.
- Bootstrap the VM with cloud-init that installs Docker Engine and the Compose plugin, mounts the data volume, and hardens SSH — **without any secret in `user_data`**, so credentials never enter Terraform state.
- Add `deploy/compose/` with a production Compose file and a flattened nginx configuration that preserves today's entrypoint behavior: static SPA at `/`, `/api/` proxied to the API, HTTP Basic Auth, and rate limiting. Application images are referenced by **pinned version tags**, never `latest`.
- Add a `make app-vm-deploy` workflow that decrypts SOPS secrets locally and ships them to the VM over SSH, keeping provisioning and configuration as separate phases.
- Add a new restore script that loads a MongoDB dump by running `mongosh` inside the MongoDB container, since the existing dump/restore scripts assume a host-installed `mongosh` and a database on `127.0.0.1:27017`.
- Add stack-specific Make targets (`tf-app-vm-apply`, `tf-app-vm-destroy`, `app-vm-deploy`) mirroring the existing per-stack Terraform targets.
- Leave the Kubernetes path untouched: `deploy/helm/`, `deploy/terraform/k8s-cluster/`, and `deploy/terraform/mongodbvm/` keep working exactly as they do today, so the migration is reversible until the cluster is switched off.

## Out of Scope

- **TLS is not part of this first step.** Production serves HTTP only, matching the current cluster deployment, where the frontend Service is also plain HTTP with Basic Auth. There is no domain or certificate dependency, so no external prerequisite blocks the migration. TLS is a deliberate follow-up.
- **`nightcrawler`** is not added to the Compose file. It has no source code or working image yet; it will be added once an image exists.
- **Scheduled MongoDB backups** are not part of this change. The VM becomes a total single point of failure, so this is a known gap to address in follow-up work rather than something this change closes.

## Capabilities

### New Capabilities
- `single-vm-compose-deploy`: Docker Compose deployment of the front, API, and MongoDB workloads on one Magalu Cloud VM, with nginx as the single public entrypoint.
- `app-vm-terraform`: Terraform provisioning of the application VM, including its isolated network, security group, public IP, and persistent data volume.
- `app-vm-secret-delivery`: Phase-separated delivery of SOPS-encrypted secrets to the VM, keeping credentials out of Terraform state and out of source control.

### Modified Capabilities
<!-- None. The existing `external-mongodb` requirements describe how the Kubernetes
     deployment reaches a MongoDB VM over the cluster VPC. That path stays in place and
     its behavior does not change, so its requirements are not modified by this change.
     The single-VM topology is captured entirely by the new `single-vm-compose-deploy`
     capability, which owns its own MongoDB placement requirements. -->
- None.

## Impact

- **New code**: `deploy/terraform/app-vm/`, `deploy/compose/`, `scripts/app-vm-*.sh`
- **Modified code**: root `Makefile` (new targets only, no existing target changed), `README.md` / `AGENTS.md` (additive documentation of the new path)
- **Untouched**: `deploy/helm/`, `deploy/terraform/k8s-cluster/`, `deploy/terraform/mongodbvm/`, `scripts/mongodb-vm-*.sh`, `tracker/`, `front/`
- **Systems**: Magalu Cloud VM, networking, block storage, and container registry; Docker Engine on the VM
- **Operational**: production becomes a single point of failure. Scheduled backups and TLS are deliberately out of scope for this change and remain open gaps.