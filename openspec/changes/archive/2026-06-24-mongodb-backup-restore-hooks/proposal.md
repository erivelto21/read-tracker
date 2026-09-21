## Why

Destroying and recreating the MongoDB VM currently depends only on the attached data volume, which leaves no local recovery artifact when the operator wants to tear down infrastructure safely or recover from a failed recreation. We need an explicit dump-and-restore workflow around `make tf-destroy` and `make tf-apply` so MongoDB data can be preserved locally outside the Terraform directory.

## What Changes

- Add a local MongoDB backup and restore workflow for the Terraform-managed MongoDB VM.
- Update the `tf-destroy` flow to create a MongoDB dump before the VM destroy proceeds.
- Update the `tf-apply` flow to restore MongoDB data from the local dump as part of bringing the VM back into service.
- Define a repository-level `dump/` directory outside `deploy/terraform` as the local storage location for dump artifacts.

## Capabilities

### New Capabilities
- `mongodb-dump-restore-workflow`: Defines the required backup and restore behavior around the Terraform lifecycle for the MongoDB VM, including local dump storage and Makefile-driven execution.

### Modified Capabilities

## Impact

- Root `Makefile` Terraform targets and any helper scripts they invoke
- `deploy/terraform` operational entrypoints and connectivity assumptions for the MongoDB VM
- New top-level `dump/` directory handling and repository ignore rules
- Operator workflow for recreating the MongoDB VM on Magalu Cloud
