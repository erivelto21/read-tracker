## Context

The repository currently exposes `tf-apply` and `tf-destroy` directly from the root `Makefile`, and both targets shell out to Terraform inside `deploy/terraform`. The MongoDB VM is reachable over SSH through a Terraform output (`public_ip`), and its MongoDB server is bootstrapped by `cloud-init.sh` with a persistent data volume and an authenticated `readtracker` user on the `read_tracker` database. The requested change adds an operator-facing safety workflow: save a local MongoDB dump before tearing the VM down and restore that dump as part of bringing the VM back.

## Goals / Non-Goals

**Goals:**
- Add an automated pre-destroy dump step to the `tf-destroy` workflow
- Add an automated post-apply restore step to the `tf-apply` workflow
- Keep dump artifacts in a repository-level `dump/` directory outside `deploy/terraform`
- Reuse the existing Terraform state and VM connectivity model rather than introducing a second deployment system

**Non-Goals:**
- Changing the Terraform resources that provision the VM, disk, or security groups
- Introducing remote backup storage, retention policies, or encryption management
- Changing application-level MongoDB schemas or migrating data between databases

## Decisions

### Decision 1: Wrap Terraform operations with repository-managed helper scripts

**Chosen**: Keep Terraform as the infrastructure engine, but move backup/restore orchestration into helper scripts invoked by `make tf-apply` and `make tf-destroy`.

**Alternatives considered**:
- *Terraform provisioners / destroy hooks*: Hard to reason about, fragile for local operator workflows, and awkward for storing artifacts in a repository directory.
- *Manual runbook only*: Leaves the data protection step optional and easy to miss during destructive operations.

**Rationale**: The backup and restore flow is an operational concern around Terraform, not a Terraform-managed resource. Wrapper scripts keep the behavior explicit, allow normal shell error handling, and make it easy to write into the top-level `dump/` directory.

### Decision 2: Use a top-level `dump/` directory as the single local backup location

**Chosen**: Reserve a repository-level `dump/` directory for MongoDB dump artifacts, with the MongoDB backup flow owning its contents.

**Alternatives considered**:
- *Store dumps under `deploy/terraform/`*: Rejected by the requested constraint and mixes data artifacts with Terraform state/config.
- *Store dumps in `/tmp` or a home-directory path*: Harder to discover, less reproducible across operators, and detached from the repository workflow.

**Rationale**: A top-level `dump/` directory is predictable, visible to operators, and clearly separate from Terraform internals.

### Decision 3: Execute dump and restore through SSH on the MongoDB VM

**Chosen**: Use the VM's Terraform-managed public IP and SSH access to run `mongodump` and `mongorestore` on the VM, copying dump artifacts between the VM and the local `dump/` directory as needed.

**Alternatives considered**:
- *Connect directly from the operator machine with a local MongoDB client*: Assumes local tooling, credentials, and network reachability that may not exist on every workstation.
- *Expose MongoDB publicly for direct client access*: Expands the attack surface and conflicts with the current network restrictions on port `27017`.

**Rationale**: SSH access already exists and the VM already contains MongoDB tooling from `mongodb-org`. This keeps the data path aligned with existing infrastructure and avoids broadening database exposure.

### Decision 4: Fail closed on backup errors and restore conditionally on dump presence

**Chosen**: `tf-destroy` stops if the backup step fails. `tf-apply` restores when a dump exists and skips with a visible message on first-time or empty-dump setups.

**Alternatives considered**:
- *Always continue even if dump or restore fails*: Fast, but unsafe for the destructive path and misleading for operators.
- *Require a dump for every apply*: Breaks first-time provisioning and recovery cases where no local backup exists yet.

**Rationale**: Destroy is the high-risk path and must protect data by default. Apply needs to support both recovery and first-time provisioning, so conditional restore is the safest practical behavior.

## Risks / Trade-offs

- **[Risk] Large dumps make `tf-destroy` slower** → Mitigation: Accept the longer runtime as the cost of safety; keep the workflow explicit so operators understand the delay.
- **[Risk] Local dump artifacts may contain sensitive data** → Mitigation: Keep dumps in a dedicated directory that can be ignored from version control and documented as operator-managed data.
- **[Risk] Restore may start before MongoDB is fully ready after provisioning** → Mitigation: The restore helper should wait for SSH and MongoDB readiness before running `mongorestore`.
- **[Risk] SSH-based workflow depends on correct key availability in the operator environment** → Mitigation: Reuse the same SSH expectations already required to access the VM and surface clear failures when credentials are missing.

## Migration Plan

1. Add helper scripts for MongoDB dump and restore orchestration, using Terraform outputs to resolve the current VM address.
2. Update `make tf-destroy` to call the dump helper before `terraform destroy`.
3. Update `make tf-apply` to run `terraform init` and `terraform apply`, then call the restore helper if a local dump exists.
4. Add repository ignore rules for local dump artifacts as needed.
5. Validate the workflow by taking a dump, recreating the VM, and restoring the database into the new instance.

**Rollback**: Revert the Makefile wiring and helper scripts, then resume using the direct Terraform targets. Existing local dump artifacts can remain in `dump/` without affecting Terraform.

## Open Questions

- _None. The workflow can proceed with repository-local dumps, SSH orchestration, and conditional restore behavior._
