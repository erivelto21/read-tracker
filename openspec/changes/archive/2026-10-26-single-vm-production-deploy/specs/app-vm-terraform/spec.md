## Purpose

Defines the Terraform capability that provisions the single application VM on Magalu Cloud — its isolated network, security group, public IP, persistent data volume, and bootstrap — independently from the existing MongoDB VM and Kubernetes cluster stacks.

## ADDED Requirements

### Requirement: Application VM Terraform stack is isolated

The application VM SHALL be provisioned by its own root Terraform stack under `deploy/terraform/app-vm/`, with state, variables, and lifecycle separate from the `mongodbvm` and `k8s-cluster` stacks.

#### Scenario: Stack lives in a dedicated directory

- **WHEN** the repository is inspected
- **THEN** the application VM Terraform files SHALL live under `deploy/terraform/app-vm/`
- **THEN** the stack SHALL have its own provider, variables, resources, outputs, and local `.gitignore`

#### Scenario: Dedicated Make targets exist

- **WHEN** repository operators need to provision or tear down the application VM
- **THEN** the repository SHALL provide a Make target named `tf-app-vm-apply`
- **THEN** the repository SHALL provide a Make target named `tf-app-vm-destroy`
- **THEN** both targets SHALL run Terraform against `deploy/terraform/app-vm/` only

#### Scenario: Existing stacks are unaffected

- **WHEN** the application VM stack is added
- **THEN** the `mongodbvm` and `k8s-cluster` stacks SHALL continue to operate through their existing Make targets without modification

### Requirement: VM is provisioned on its own network

The stack SHALL provision the application VM on a VPC and subnet owned by the stack, so that the VM does not depend on the Kubernetes cluster's networking and survives the cluster being destroyed.

#### Scenario: Dedicated VPC and subnet are created

- **WHEN** `terraform apply` completes
- **THEN** a VPC and subnet SHALL exist for the application VM
- **THEN** the VM SHALL be attached through an explicit network interface in that subnet
- **THEN** destroying the Kubernetes cluster SHALL NOT remove the application VM's network

#### Scenario: Private IP is fixed

- **WHEN** the VM network interface is created
- **THEN** the interface SHALL be assigned a configurable fixed private IPv4 address
- **THEN** the assigned address SHALL be exposed as a Terraform output

### Requirement: Security group restricts ingress to HTTP and SSH

A security group SHALL be attached to the VM network interface with default rules disabled, allowing inbound TCP on port `80` from `0.0.0.0/0`, inbound TCP on port `22` only from a configurable operator CIDR, and outbound traffic. No other inbound port SHALL be allowed.

#### Scenario: HTTP is publicly reachable

- **WHEN** a TCP connection to the VM public IP on port `80` is made from the internet
- **THEN** the security group SHALL allow the connection

#### Scenario: SSH is restricted to the operator CIDR

- **WHEN** a TCP connection to the VM public IP on port `22` is made from outside the configured operator CIDR
- **THEN** the security group SHALL deny the connection

#### Scenario: Workload ports are not reachable from the internet

- **WHEN** a TCP connection to the VM public IP is attempted on port `8080` or port `27017`
- **THEN** the security group SHALL deny the connection

### Requirement: Reserved public IP is attached to the VM

The stack SHALL attach a reserved public IPv4 address owned by the stack to the VM network interface, so the SSH and HTTP endpoint remains stable across VM recreation.

#### Scenario: Public IP is stable across recreation

- **WHEN** the VM is destroyed and recreated through the Terraform workflow
- **THEN** the public IP SHALL remain the same address
- **THEN** operators SHALL NOT need to discover a new address to reconnect
- **THEN** the public IP SHALL be exposed as a Terraform output

### Requirement: VM bootstrap installs the container runtime without secrets

The stack SHALL use `user_data` to run a cloud-init script that installs Docker Engine and the Compose plugin, enables the Docker service, hardens SSH, and mounts the persistent data volume. The bootstrap script SHALL NOT contain any secret value.

#### Scenario: Container runtime is available after boot

- **WHEN** the VM finishes booting for the first time
- **THEN** Docker Engine SHALL be installed, running, and enabled
- **THEN** the Docker Compose plugin SHALL be available
- **THEN** the VM SHALL be able to pull images from the Magalu Cloud container registry

#### Scenario: Bootstrap contains no secret material

- **WHEN** the cloud-init script and the Terraform stack are inspected
- **THEN** no database password, application credential, registry credential, or Basic Auth hash SHALL appear in any tracked file
- **THEN** the cloud-init script SHALL NOT accept secret values as template parameters

### Requirement: Persistent data volume is provisioned and mounted

The stack SHALL provision a separate block-storage volume for application data and attach it to the VM, and the bootstrap SHALL mount it at a fixed path before any data-consuming service starts.

#### Scenario: Volume is attached to the VM

- **WHEN** `terraform apply` completes
- **THEN** a block-storage volume SHALL exist and be attached to the application VM
- **THEN** the volume size and type SHALL be configurable through Terraform variables

#### Scenario: Volume is formatted only when empty

- **WHEN** the bootstrap runs on a VM with an attached volume that already contains a filesystem
- **THEN** the bootstrap SHALL mount the existing filesystem without reformatting it
- **THEN** the bootstrap SHALL persist the mount so it survives a reboot

#### Scenario: Mount happens before services consume data

- **WHEN** the VM boots with the data volume attached
- **THEN** the bootstrap SHALL wait for the device to become available
- **THEN** the device SHALL be mounted at the data path before the deployment phase is expected to start services

### Requirement: Application VM credentials stay out of source control

The Terraform stack SHALL receive the Magalu Cloud API key, region, SSH key name, and all environment-specific values through variables, and SHALL NOT hardcode credentials in any tracked file.

#### Scenario: No secrets in tracked files

- **WHEN** the repository is inspected
- **THEN** no Magalu Cloud API key or other credential SHALL appear in any committed file

#### Scenario: Local Terraform files are ignored

- **WHEN** a `.gitignore` exists inside `deploy/terraform/app-vm/`
- **THEN** `*.tfvars`, `*.tfstate`, `*.tfstate.backup`, `*.tfstate.*`, and `.terraform/` SHALL be listed as ignored

#### Scenario: Example variables file is provided

- **WHEN** an operator needs to configure the stack
- **THEN** a `terraform.tfvars.example` SHALL document every required variable with empty or placeholder values
- **THEN** the example file SHALL NOT contain real credentials