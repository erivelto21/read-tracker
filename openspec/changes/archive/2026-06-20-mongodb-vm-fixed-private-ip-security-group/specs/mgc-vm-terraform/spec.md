## MODIFIED Requirements

### Requirement: Terraform provisions MGC VM
The system SHALL include a Terraform configuration that provisions a single VM instance on Magalu Cloud using the `MagaluCloud/mgc` provider, attached through an explicit VPC network interface with fixed private IP `172.18.34.72` and without any public IPv4 address assigned.

#### Scenario: VM created with correct specs
- **WHEN** `terraform apply` is run with valid credentials
- **THEN** a `BV1-1-10` VM running `cloud-ubuntu-24.04 LTS` SHALL be created in MGC
- **THEN** the VM SHALL use the fixed private IP `172.18.34.72`
- **THEN** the VM SHALL NOT have a public IPv4 address assigned

#### Scenario: SSH key attached
- **WHEN** the VM is provisioned
- **THEN** the SSH key `k8s-ssh-key-my-cluster-my-pool-46d68` SHALL be attached, allowing SSH access

## ADDED Requirements

### Requirement: Private IP exposed as output
The Terraform configuration SHALL output the VM's private IPv4 address after a successful `terraform apply`.

#### Scenario: Output available after apply
- **WHEN** `terraform apply` completes successfully
- **THEN** the private IP of the VM SHALL be printed as a Terraform output named `private_ip`
- **THEN** the output value SHALL be `172.18.34.72`

## REMOVED Requirements

### Requirement: Public IP exposed as output
**Reason**: The MongoDB VM is now required to be private-only and must not expose or depend on a public IPv4 address.

**Migration**: Replace any use of the `public_ip` Terraform output with the `private_ip` output and access the VM only through the private network path.
