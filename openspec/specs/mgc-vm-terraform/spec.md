# Spec: MGC VM Terraform

## Purpose

Defines the Terraform capability for provisioning a MongoDB-ready VM on Magalu Cloud, including infrastructure, bootstrap, outputs, and credential handling.

---

## Requirements

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

---

### Requirement: MongoDB bootstrapped via cloud-init
The Terraform configuration SHALL use `user_data` to run a cloud-init script that installs MongoDB CE, installs `conntrack`, mounts the persistent MongoDB data volume, and starts MongoDB safely on first boot and on recreated VMs.

#### Scenario: MongoDB running after provisioning
- **WHEN** the VM boots for the first time
- **THEN** MongoDB CE SHALL be installed and the `mongod` service SHALL be running and enabled
- **THEN** `conntrack` SHALL be installed on the VM

#### Scenario: Persistent volume mounted before MongoDB starts
- **WHEN** the VM boots with an attached MongoDB data volume
- **THEN** the cloud-init process SHALL wait for the disk to become available
- **THEN** the disk SHALL be formatted only if it does not already contain a filesystem
- **THEN** the disk SHALL be mounted persistently at MongoDB's data directory before `mongod` starts

#### Scenario: Recreated VM reuses existing MongoDB data safely
- **WHEN** a new VM is created and reattaches an existing MongoDB data volume
- **THEN** the bootstrap process SHALL remount the existing volume without reformatting it
- **THEN** the bootstrap process SHALL avoid failing when the MongoDB application user already exists

---

### Requirement: Private IP exposed as output
The Terraform configuration SHALL output the VM's private IPv4 address and reserved public IPv4 address after a successful `terraform apply`.

#### Scenario: Outputs available after apply
- **WHEN** `terraform apply` completes successfully
- **THEN** the private IP of the VM SHALL be printed as a Terraform output named `private_ip`
- **THEN** the output value for `private_ip` SHALL be `172.18.34.72`
- **THEN** the public IP of the VM SHALL be printed as a Terraform output named `public_ip`
- **THEN** the output value for `public_ip` SHALL be `169.150.1.49`

---

### Requirement: MongoDB data persists across VM recreation
The system SHALL provision a separate Magalu Cloud block storage volume for MongoDB data and attach it to the MongoDB VM so database files survive VM replacement.

#### Scenario: Volume created with low-cost default tier
- **WHEN** `terraform apply` provisions the MongoDB storage volume
- **THEN** the volume SHALL use the cheapest supported default tier configured by the Terraform module
- **THEN** the default volume type SHALL be configurable through a Terraform variable

#### Scenario: Volume attached to MongoDB VM
- **WHEN** the MongoDB VM is created
- **THEN** the persistent MongoDB data volume SHALL be attached to that VM

---

### Requirement: Credentials kept out of source control
The Terraform configuration SHALL use variables for all sensitive values (API key, region, SSH key name) and SHALL NOT hardcode credentials in any tracked file.

#### Scenario: No secrets in tracked files
- **WHEN** the repository is inspected
- **THEN** no MGC API keys or sensitive values SHALL appear in any committed file

#### Scenario: tfvars and state files ignored
- **WHEN** a `.gitignore` exists inside `deploy/terraform/`
- **THEN** `*.tfvars`, `*.tfstate`, `*.tfstate.backup`, and `.terraform/` SHALL be listed as ignored
