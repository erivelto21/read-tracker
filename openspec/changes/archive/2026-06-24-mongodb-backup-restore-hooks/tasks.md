## 1. Backup/Restore Scaffolding

- [x] 1.1 Add the repository-level `dump/` convention and ignore local dump artifacts in version control as needed
- [x] 1.2 Add helper script logic for resolving Terraform outputs, SSH connectivity, and MongoDB readiness checks for the MongoDB VM

## 2. Pre-Destroy Backup Flow

- [x] 2.1 Implement the MongoDB dump helper that runs before destroy and saves the exported data into `dump/`
- [x] 2.2 Update `make tf-destroy` to invoke the backup helper and stop before `terraform destroy` when the dump step fails

## 3. Post-Apply Restore Flow

- [x] 3.1 Implement the MongoDB restore helper that detects an existing local dump and restores it into the provisioned VM
- [x] 3.2 Update `make tf-apply` to run Terraform first and then execute the conditional restore flow with visible no-dump messaging

## 4. Workflow Validation

- [x] 4.1 Validate that `make tf-apply` succeeds cleanly when `dump/` has no MongoDB dump
- [x] 4.2 Validate a full dump → destroy → apply → restore cycle against the MongoDB VM workflow
