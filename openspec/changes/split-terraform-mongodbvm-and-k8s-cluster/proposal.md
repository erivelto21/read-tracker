## Why

The repository currently keeps the MongoDB VM Terraform stack in a single flat `deploy/terraform/` folder, which makes it hard to add a second Terraform stack for reproducing the current Magalu Cloud Kubernetes cluster without mixing unrelated state, variables, and commands. This change separates the MongoDB VM stack from a new Kubernetes cluster stack so the project can manage both infrastructures clearly and apply or destroy each one independently.

## What Changes

- Split the current MongoDB VM Terraform stack into `deploy/terraform/mongodbvm/` without changing its existing MongoDB provisioning behavior.
- Add a new `deploy/terraform/k8s-cluster/` Terraform stack that provisions an MGC Kubernetes cluster matching the current cluster defaults, including Kubernetes version, network ranges, three control-plane zones, and a fixed-size worker pool using `BV2-2-40`.
- Add dedicated Makefile commands for each Terraform stack so operators can run apply and destroy flows independently for MongoDB VM and Kubernetes cluster infrastructure.
- Update Terraform-related documentation and workflow expectations to reference the new stack layout and commands.

## Capabilities

### New Capabilities
- `mgc-k8s-terraform`: Terraform configuration for provisioning an MGC Kubernetes cluster that mirrors the current cluster baseline and exposes dedicated apply/destroy commands.

### Modified Capabilities
- `mgc-vm-terraform`: The MongoDB VM Terraform workflow moves into a dedicated stack directory and uses dedicated Makefile commands instead of the shared root Terraform commands.

## Impact

- Affected code: `deploy/terraform/`, `Makefile`, and Terraform support files for the MongoDB VM and new Kubernetes cluster stack
- Affected systems: Magalu Cloud Terraform provider usage for VM and Kubernetes resources
- Operational impact: Terraform state, variables, and apply/destroy commands become stack-specific
