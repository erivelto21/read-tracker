## MODIFIED Requirements

### Requirement: Terraform provisions MGC VM
The system SHALL include a Terraform configuration that provisions a single VM instance on Magalu Cloud using the `MagaluCloud/mgc` provider, attached through an explicit VPC network interface with fixed private IP `172.18.34.72`, and with the reserved public IPv4 address `169.150.1.49` attached to that same interface for SSH access.

#### Scenario: VM created with correct specs
- **WHEN** `terraform apply` is run with valid credentials
- **THEN** a `BV1-1-10` VM running `cloud-ubuntu-24.04 LTS` SHALL be created in MGC
- **THEN** the VM SHALL use the fixed private IP `172.18.34.72`
- **THEN** the VM SHALL have the reserved public IPv4 address `169.150.1.49` attached to its primary network interface

#### Scenario: SSH key attached
- **WHEN** the VM is provisioned
- **THEN** the SSH key `k8s-ssh-key-my-cluster-my-pool-46d68` SHALL be attached, allowing SSH access

#### Scenario: SSH ingress exposed publicly
- **WHEN** the security group is created for the MongoDB VM
- **THEN** the VM SHALL allow inbound TCP traffic on port 22 from `0.0.0.0/0`
- **THEN** the VM SHALL keep inbound TCP traffic on port 27017 restricted to `mongodb_allowed_source`

#### Scenario: Reserved public IP preserved across recreate flows
- **WHEN** the MongoDB VM is destroyed and recreated through the Terraform workflow
- **THEN** the SSH endpoint SHALL remain `169.150.1.49`
- **THEN** operators SHALL NOT need to discover a different public IP to reconnect

### Requirement: Private IP exposed as output
The Terraform configuration SHALL output the VM's private IPv4 address and reserved public IPv4 address after a successful `terraform apply`.

#### Scenario: Outputs available after apply
- **WHEN** `terraform apply` completes successfully
- **THEN** the private IP of the VM SHALL be printed as a Terraform output named `private_ip`
- **THEN** the output value for `private_ip` SHALL be `172.18.34.72`
- **THEN** the public IP of the VM SHALL be printed as a Terraform output named `public_ip`
- **THEN** the output value for `public_ip` SHALL be `169.150.1.49`
