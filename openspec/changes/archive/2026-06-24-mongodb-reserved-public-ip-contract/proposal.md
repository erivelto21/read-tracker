## Why

The MongoDB VM is currently treated as having a Terraform-discovered public SSH endpoint, but operations now depend on a reserved public IP that is intended to remain fixed across the VM lifecycle. We need to make that reserved IP an explicit infrastructure contract so Terraform behavior, outputs, and operational scripts all use the same stable SSH endpoint.

## What Changes

- Define the reserved public IP `169.150.1.49` as the required SSH endpoint for the MongoDB VM.
- Update the Terraform contract so the MongoDB VM public IP is not just dynamically discovered, but explicitly managed as a reserved address that remains attached across recreate flows.
- Update the operational backup/restore workflow assumptions so SSH access can rely on the fixed reserved IP contract.
- **BREAKING** Remove the assumption that operators and scripts should discover an arbitrary SSH public IP after apply.

## Capabilities

### New Capabilities

### Modified Capabilities
- `mgc-vm-terraform`: The MongoDB VM public SSH endpoint requirement changes from any Terraform-managed public IP to the reserved public IP `169.150.1.49`.

## Impact

- `deploy/terraform` public IP resources, variables, and outputs
- Root-level backup/restore helper scripts that currently resolve SSH access dynamically
- Operator workflow and documentation for connecting to the MongoDB VM
