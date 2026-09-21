## ADDED Requirements

### Requirement: MongoDB VM Terraform stack is isolated
The MongoDB VM Terraform capability SHALL live in its own root stack under `deploy/terraform/mongodbvm/` so it can be operated independently from other Terraform-managed infrastructure in the repository.

#### Scenario: MongoDB VM files live in a dedicated stack directory
- **WHEN** the repository is inspected
- **THEN** the MongoDB VM Terraform files SHALL live under `deploy/terraform/mongodbvm/`
- **THEN** the root `deploy/terraform/` directory SHALL act as a parent container for stack-specific subdirectories rather than as the MongoDB VM root stack

#### Scenario: Dedicated MongoDB VM make targets exist
- **WHEN** repository operators need to provision the MongoDB VM stack
- **THEN** the repository SHALL provide a Make target named `tf-mongodbvm-apply`
- **THEN** that target SHALL run Terraform against `deploy/terraform/mongodbvm/`

#### Scenario: Dedicated MongoDB VM destroy target exists
- **WHEN** repository operators need to tear down the MongoDB VM stack
- **THEN** the repository SHALL provide a Make target named `tf-mongodbvm-destroy`
- **THEN** that target SHALL run Terraform destroy against `deploy/terraform/mongodbvm/`

## MODIFIED Requirements

### Requirement: Credentials kept out of source control
The Terraform configuration SHALL use variables for all sensitive values (API key, region, SSH key name) and SHALL NOT hardcode credentials in any tracked file.

#### Scenario: No secrets in tracked files
- **WHEN** the repository is inspected
- **THEN** no MGC API keys or sensitive values SHALL appear in any committed file

#### Scenario: tfvars and state files ignored
- **WHEN** a `.gitignore` exists inside `deploy/terraform/mongodbvm/`
- **THEN** `*.tfvars`, `*.tfstate`, `*.tfstate.backup`, and `.terraform/` SHALL be listed as ignored
