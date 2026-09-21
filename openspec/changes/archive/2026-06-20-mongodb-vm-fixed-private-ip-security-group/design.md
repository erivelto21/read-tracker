## Context

The repository already contains Terraform for a Magalu Cloud MongoDB VM and an external MongoDB spec path that moved the database off-cluster. However, the current baseline still assumes or documents a public-IP-oriented VM shape and broader ingress rules than the current cluster integration needs. The target topology is a private-only MongoDB VM on the cluster VPC, using a fixed private IP (`172.18.34.72`) and allowing MongoDB traffic only from the Kubernetes node pool subnet `172.18.32.0/20`.

This change is primarily about correcting and tightening the infrastructure contract so the implementation, outputs, and specs all describe the same network model.

## Goals / Non-Goals

**Goals:**
- Provision the MongoDB VM without public IPv4 exposure.
- Reserve and attach the fixed private IP `172.18.34.72` to the VM.
- Restrict TCP `27017` ingress to `172.18.32.0/20`.
- Update the Terraform and external MongoDB specs to reflect the new private-only topology.
- Preserve MongoDB bootstrap and application connectivity assumptions already established by the external MongoDB setup.

**Non-Goals:**
- Changing MongoDB authentication behavior or credentials format.
- Introducing TLS, replica sets, backups, or monitoring.
- Redesigning the Helm-side `ExternalName` integration unless required by spec alignment.
- Broadening ingress to all cluster nodes or subnets.

## Decisions

### Decision 1: Use a pre-created network interface for the fixed private IP

**Chosen**: Create an `mgc_network_vpcs_interfaces` resource with `ip_address = "172.18.34.72"` and attach it to the VM using `network_interface_id`.

**Alternatives considered**:
- Keep using the VM-managed primary interface with `vpc_id` only — rejected because it does not guarantee the exact private IP assignment.
- Use a dynamic private IP and rely only on hostname/DNS — rejected because the requested requirement is an explicit fixed IP.

**Rationale**: In the Magalu Cloud provider, fixed private IP allocation belongs to the interface resource. Modeling the interface explicitly makes the desired address part of Terraform state and keeps the IP reservation tied to infrastructure code.

### Decision 2: Keep the VM private-only

**Chosen**: The VM will not allocate a public IPv4 address.

**Alternatives considered**:
- Preserve a public IP for SSH or manual validation — rejected because it violates the desired security posture and is no longer needed for the target architecture.

**Rationale**: The MongoDB host is intended to be reachable only from the private cluster network. Removing public IPv4 closes an unnecessary exposure path and aligns the infrastructure with the proposal.

### Decision 3: Attach the security group to the network interface

**Chosen**: Attach the MongoDB security group directly to the explicit interface used by the VM.

**Alternatives considered**:
- Use `creation_security_groups` on the VM resource — rejected because the fixed-IP design uses `network_interface_id`, and provider guidance treats those networking paths as mutually exclusive.

**Rationale**: Once the interface is modeled as a first-class resource, the security boundary should be attached there as well. This keeps ownership of both address and filtering rules on the same object.

### Decision 4: Restrict ingress to the node pool subnet `172.18.32.0/20`

**Chosen**: Allow TCP `27017` only from `172.18.32.0/20`.

**Alternatives considered**:
- Allow only a single host IP (`172.18.33.211/32`) — rejected because pod/node egress is not guaranteed to originate from one stable address.
- Allow the full node CIDR (`172.18.0.0/18`) — rejected because it is broader than needed for the current pool.

**Rationale**: The MongoDB VM only needs to be reachable from the current Kubernetes node pool, not from a single ephemeral source IP. Using the pool subnet keeps access narrow enough for the current cluster while avoiding connection failures when traffic originates from different nodes in that pool.

### Decision 5: Add explicit outbound security group rules

**Chosen**: Add allow-all IPv4 and IPv6 egress rules to the MongoDB security group.

**Alternatives considered**:
- Rely on default rules — rejected because `disable_default_rules = true` removes those assumptions.
- Restrict egress to a smaller set of destinations — rejected for now because MongoDB responses, DNS, package installation, and bootstrap traffic need broader outbound access.

**Rationale**: With default rules disabled, the VM still needs to send MongoDB responses and complete bootstrap/package traffic. Explicit egress rules preserve the tight inbound posture without breaking connectivity.

### Decision 6: Modify existing capabilities rather than add a new one

**Chosen**: Update `mgc-vm-terraform` and `external-mongodb`.

**Alternatives considered**:
- Create a new capability just for fixed-IP networking — rejected because the behavior being changed already belongs to the existing Terraform and external MongoDB capabilities.

**Rationale**: This is a refinement of current infrastructure behavior, not a distinct new feature surface.

## Risks / Trade-offs

- **[Risk] The node pool may later expand beyond `172.18.32.0/20`** → **Mitigation**: keep `mongodb_allowed_source` configurable and widen it to the full node CIDR or a new pool subnet if the cluster topology changes.
- **[Risk] Fixed private IP may already be in use or unavailable in the target subnet** → **Mitigation**: confirm `172.18.34.72` is free in the selected subnet before apply.
- **[Risk] Switching from VM-managed networking to explicit interface management may require Terraform state or resource replacement** → **Mitigation**: document the expected replacement behavior and plan rollout during a maintenance window.
- **[Risk] No public IPv4 makes ad hoc troubleshooting harder** → **Mitigation**: rely on private-cluster reachability, bastion/jump access, or console-based diagnostics instead of direct public access.

## Migration Plan

1. Update the `mgc-vm-terraform` and `external-mongodb` specs to codify the fixed-IP and `/32` ingress requirements.
2. Refactor Terraform to create the private interface, attach the security group to that interface, and instantiate the VM through `network_interface_id`.
3. Run `terraform plan` and confirm whether the VM or interface will be replaced.
4. Apply the Terraform changes and verify the VM receives `172.18.34.72` with no public IPv4.
5. Validate connectivity from the Kubernetes side using the expected source path and confirm MongoDB accepts connections only from `172.18.32.0/20`.

**Rollback**: revert Terraform to the prior networking model and re-apply. If the rollback depends on replacing the interface or VM, expect the private IP guarantee to be lost when returning to the old model.

## Open Questions

- Which exact subnet resource in Magalu Cloud should own `172.18.34.72` for this VM?
- Does the existing live Terraform state already manage the VM in a way that will force recreation when switching to `network_interface_id`?
