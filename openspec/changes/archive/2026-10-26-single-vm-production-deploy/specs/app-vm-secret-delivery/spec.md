## Purpose

Defines how secrets reach the application VM without entering Terraform state or source control, by separating infrastructure provisioning from configuration and shipping SOPS-decrypted values over SSH at deploy time.

## ADDED Requirements

### Requirement: Provisioning and configuration are separate phases

Infrastructure provisioning SHALL NOT deliver any secret to the VM. Application secrets SHALL be delivered by a separate deploy step that runs after provisioning, so that rotating a credential does not require recreating the VM.

#### Scenario: Terraform apply requires no secret variable

- **WHEN** `terraform apply` runs for the application VM stack
- **THEN** no database password, application credential, or Basic Auth hash SHALL be required as a Terraform variable
- **THEN** the resulting Terraform state SHALL contain no secret value

#### Scenario: Credential rotation does not recreate the VM

- **WHEN** a secret value is rotated and the deploy step is re-run
- **THEN** the VM SHALL NOT be destroyed or recreated
- **THEN** the services SHALL pick up the new value

### Requirement: Secrets are stored encrypted with SOPS

All secrets consumed by the single-VM deployment SHALL be stored in files encrypted with SOPS and age, using the encryption rule already configured at the repository root, and SHALL be delivered to the VM decrypted at deploy time.

#### Scenario: Secret file is encrypted in the repository

- **WHEN** the tracked secret file for the single-VM deployment is inspected
- **THEN** secret values SHALL appear as SOPS ciphertext, not plaintext
- **THEN** the file SHALL match the age rule declared in the root `.sops.yaml`

#### Scenario: Decryption happens only at deploy time

- **WHEN** the deploy step runs with a valid age key present
- **THEN** the plaintext values SHALL be produced locally
- **THEN** no plaintext secret SHALL be written to a tracked file

### Requirement: Secret material is shipped to the VM over SSH

The deploy step SHALL transfer the decrypted environment file and the nginx Basic Auth credentials file to the VM over SSH, and SHALL restrict their permissions on the VM to the deploying user.

#### Scenario: Environment file reaches the VM

- **WHEN** the deploy step completes successfully
- **THEN** the VM SHALL contain an environment file with the API and MongoDB connection settings
- **THEN** the file SHALL be readable only by the deploying user

#### Scenario: Basic Auth file reaches the VM

- **WHEN** the deploy step completes successfully
- **THEN** the VM SHALL contain the nginx Basic Auth credentials file
- **THEN** the frontend nginx SHALL load that file and enforce authentication

### Requirement: Deploy step starts the workload on the VM

The deploy step SHALL, after transferring configuration, start the Compose workload on the VM and report whether the services became healthy.

#### Scenario: Workload starts after deploy

- **WHEN** the deploy step completes
- **THEN** the frontend, API, and MongoDB services SHALL be running on the VM
- **THEN** the frontend SHALL answer on port `80` with a `401` for unauthenticated requests, confirming both nginx and the auth file are active

#### Scenario: Deploy fails loudly on a broken configuration

- **WHEN** a service fails to start during the deploy step
- **THEN** the deploy step SHALL exit with a non-zero status
- **THEN** the failure SHALL be reported to the operator with the failing service name

### Requirement: Deploy step does not modify existing infrastructure stacks

The deploy step and its supporting scripts SHALL operate only on the application VM and SHALL NOT modify, reconfigure, or depend on the `mongodbvm` or `k8s-cluster` stacks.

#### Scenario: Existing stacks remain operable

- **WHEN** the deploy step has run
- **THEN** the `mongodbvm` and `k8s-cluster` Terraform stacks SHALL remain in their previous state
- **THEN** their existing Make targets SHALL continue to work unchanged