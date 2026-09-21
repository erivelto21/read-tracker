## 1. Project Scaffolding

- [x] 1.1 Create `deploy/terraform/` directory
- [x] 1.2 Add `.gitignore` inside `deploy/terraform/` ignoring `*.tfvars`, `*.tfstate`, `*.tfstate.backup`, and `.terraform/`

## 2. Terraform Configuration

- [x] 2.1 Create `deploy/terraform/provider.tf` with the `MagaluCloud/mgc` provider block and `terraform` required_providers
- [x] 2.2 Create `deploy/terraform/variables.tf` with variables: `api_key` (sensitive), `region`, `ssh_key_name`
- [x] 2.3 Create `deploy/terraform/main.tf` with the `mgc_virtual_machine_instances` resource (`BV1-1-10`, `cloud-ubuntu-24.04 LTS`, public IPv4, user_data from cloud-init.sh)
- [x] 2.4 Create `deploy/terraform/outputs.tf` exposing the VM's public IP as `public_ip`

## 3. MongoDB Bootstrap

- [x] 3.1 Create `deploy/terraform/cloud-init.sh` with a shell script that installs MongoDB CE on Ubuntu 24.04 and enables the `mongod` service

## 4. Validation

- [x] 4.1 Run `terraform init` inside `deploy/terraform/` and confirm no errors
- [x] 4.2 Run `terraform plan` with a `terraform.tfvars` file and confirm the plan shows 1 resource to create
