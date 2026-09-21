## Why

The current Magalu Cloud MongoDB VM is reachable only on its private network and stores data only on the VM root disk, which makes direct SSH administration harder and increases the risk of data loss when the VM is recreated. This change is needed to allow SSH access through a public IP while preserving the current private MongoDB access pattern and persisting MongoDB data on a reusable disk.

## What Changes

- Add Terraform-managed public IPv4 allocation and attachment for the MongoDB VM so SSH access can be performed from the internet with the configured SSH key.
- Add a security-group rule that allows SSH traffic from public IPv4 sources while keeping MongoDB traffic restricted to the private source CIDR.
- Add a persistent Magalu Cloud block storage volume for MongoDB data and attach it to the VM.
- Update cloud-init bootstrap to install `conntrack`, mount the persistent volume for MongoDB data, and handle VM recreation without reformatting or losing existing data.
- Add Terraform outputs and variables needed to operate the public IP and the low-cost persistent storage configuration.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `mgc-vm-terraform`: Extend the Terraform-managed MongoDB VM requirements to support public SSH access, persistent block storage, and idempotent bootstrap behavior on recreated VMs.

## Impact

- Affected code: `deploy/terraform/main.tf`, `deploy/terraform/variables.tf`, `deploy/terraform/outputs.tf`, `deploy/terraform/cloud-init.sh`
- Affected systems: Magalu Cloud networking, security groups, public IP allocation, block storage, VM bootstrap
- Operational impact: SSH access model changes for the MongoDB VM; MongoDB data moves to a persistent external volume using the cheapest supported storage tier
