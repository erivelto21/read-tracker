## Why

The current MongoDB VM Terraform/spec history still reflects an earlier public-IP-oriented setup and does not guarantee the exact private-network shape now required for the cluster integration. This change is needed to lock the VM to a fixed private IP (`172.18.34.72`), remove public exposure, and restrict MongoDB access to the Kubernetes node/pool private IP (`172.18.33.211`).

## What Changes

- Update Terraform requirements for the MongoDB VM to use a pre-created Magalu Cloud network interface with fixed private IP `172.18.34.72`.
- Require the VM to run without any public IPv4 assignment.
- Require MongoDB ingress on TCP `27017` to be allowed only from the Kubernetes node pool subnet CIDR `172.18.32.0/20`, denying all other sources.
- Align the external MongoDB integration requirements with the new fixed-IP and private-only topology.

## Capabilities

### New Capabilities
- None.

### Modified Capabilities
- `mgc-vm-terraform`: change the VM networking requirement from public-IP-based provisioning to fixed private IP provisioning with no public IPv4.
- `external-mongodb`: tighten MongoDB network access requirements so only the Kubernetes node pool subnet `172.18.32.0/20` can reach port `27017`.

## Impact

- `deploy/terraform/`: VM networking model, interface attachment, security group resources, and outputs
- `openspec/specs/mgc-vm-terraform/spec.md`
- `openspec/specs/external-mongodb/spec.md`
- Magalu Cloud VM, VPC/subnet interface, and security group configuration for the external MongoDB host
