## Why

Study how to provision a VM on Magalu Cloud via Terraform and understand how to configure communication between that VM and the existing Kubernetes cluster. MongoDB is used as the workload to make the exercise concrete and realistic.

## What Changes

- Add `deploy/terraform/` folder with a complete Terraform configuration
- Provision a `BV1-1-10` Ubuntu 24.04 VM on MGC with a public IPv4
- Bootstrap MongoDB on the VM at first boot via `cloud-init`
- Expose outputs (public IP) for manual validation after `terraform apply`

## Capabilities

### New Capabilities
- `mgc-vm-terraform`: Terraform configuration that provisions a VM on Magalu Cloud and bootstraps MongoDB via cloud-init

### Modified Capabilities
<!-- none -->

## Impact

- New folder: `deploy/terraform/`
- No changes to existing code (`tracker/`, `nightcrawler/`, Helm charts)
- Requires MGC API credentials and an existing SSH key (`k8s-ssh-key-my-cluster-my-pool-46d68`)
- Depends on `MagaluCloud/mgc` Terraform provider
