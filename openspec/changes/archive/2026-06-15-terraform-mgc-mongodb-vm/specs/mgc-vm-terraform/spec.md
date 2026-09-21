## ADDED Requirements

### Requirement: Terraform provisions MGC VM
The system SHALL include a Terraform configuration that provisions a single VM instance on Magalu Cloud using the `MagaluCloud/mgc` provider.

#### Scenario: VM created with correct specs
- **WHEN** `terraform apply` is run with valid credentials
- **THEN** a `BV1-1-10` VM running `cloud-ubuntu-24.04 LTS` SHALL be created in MGC with a public IPv4 address assigned

#### Scenario: SSH key attached
- **WHEN** the VM is provisioned
- **THEN** the SSH key `k8s-ssh-key-my-cluster-my-pool-46d68` SHALL be attached, allowing SSH access

### Requirement: MongoDB bootstrapped via cloud-init
The Terraform configuration SHALL use `user_data` to run a cloud-init script that installs and starts MongoDB CE on the VM at first boot.

#### Scenario: MongoDB running after provisioning
- **WHEN** the VM boots for the first time
- **THEN** MongoDB CE SHALL be installed and the `mongod` service SHALL be running and enabled

### Requirement: Public IP exposed as output
The Terraform configuration SHALL output the VM's public IPv4 address after a successful `terraform apply`.

#### Scenario: Output available after apply
- **WHEN** `terraform apply` completes successfully
- **THEN** the public IP of the VM SHALL be printed as a Terraform output named `public_ip`

### Requirement: Credentials kept out of source control
The Terraform configuration SHALL use variables for all sensitive values (API key, region, SSH key name) and SHALL NOT hardcode credentials in any tracked file.

#### Scenario: No secrets in tracked files
- **WHEN** the repository is inspected
- **THEN** no MGC API keys or sensitive values SHALL appear in any committed file

#### Scenario: tfvars and state files ignored
- **WHEN** a `.gitignore` exists inside `deploy/terraform/`
- **THEN** `*.tfvars`, `*.tfstate`, `*.tfstate.backup`, and `.terraform/` SHALL be listed as ignored
