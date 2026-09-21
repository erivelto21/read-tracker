# Spec: MongoDB Dump Restore Workflow

## Purpose

Defines the repository-level backup and restore workflow for MongoDB dumps around Terraform lifecycle operations so operators can preserve data across VM destruction and recreation.

---

## Requirements

### Requirement: Terraform lifecycle stores MongoDB dumps outside the Terraform directory
The system SHALL store MongoDB dump artifacts in a repository-level `dump/` directory located outside `deploy/terraform` so backup files remain available across Terraform operations.

#### Scenario: Dump directory is repository-scoped
- **WHEN** the backup and restore workflow writes dump artifacts
- **THEN** the files SHALL be written under a top-level `dump/` directory in the repository
- **THEN** no dump artifact SHALL be written inside `deploy/terraform`

---

### Requirement: tf-destroy backs up MongoDB before destroying the VM
The `tf-destroy` workflow SHALL run a MongoDB dump against the current MongoDB VM and persist the resulting dump locally before Terraform destroys the VM.

#### Scenario: Successful destroy backup
- **WHEN** `make tf-destroy` is run and the MongoDB VM is reachable
- **THEN** the workflow SHALL execute a MongoDB dump using the VM's current connection settings
- **THEN** the workflow SHALL save the dump into the repository `dump/` directory before `terraform destroy` starts

#### Scenario: Backup failure blocks destroy
- **WHEN** `make tf-destroy` is run and the MongoDB dump step fails
- **THEN** the workflow SHALL stop before running `terraform destroy`
- **THEN** the operator SHALL receive a visible error indicating that the VM was not destroyed because the backup failed

---

### Requirement: tf-apply restores MongoDB data from the local dump
The `tf-apply` workflow SHALL restore MongoDB data from the local dump after the MongoDB VM has been provisioned and is reachable, as part of the same Make target execution.

#### Scenario: Restore runs after apply when a dump exists
- **WHEN** `make tf-apply` is run and a local MongoDB dump is present in `dump/`
- **THEN** the workflow SHALL provision the MongoDB VM with Terraform before attempting the restore
- **THEN** the workflow SHALL restore the dump into the provisioned MongoDB instance before the Make target completes

#### Scenario: First-time apply skips restore without failing
- **WHEN** `make tf-apply` is run and no local MongoDB dump exists in `dump/`
- **THEN** the Terraform apply step SHALL still complete successfully
- **THEN** the workflow SHALL skip the restore step and emit a visible message that no local dump was available
