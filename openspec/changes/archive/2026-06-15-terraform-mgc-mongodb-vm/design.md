## Context

The project currently runs MongoDB as a pod inside a Kubernetes cluster on Magalu Cloud. This change introduces a Terraform configuration under `deploy/terraform/` to provision a standalone VM on MGC and bootstrap MongoDB on it via cloud-init. The primary goal is educational: learning how to manage infrastructure-as-code for MGC VMs.

## Goals / Non-Goals

**Goals:**
- Provision a `BV1-1-10` Ubuntu 24.04 VM on MGC with a public IPv4 address
- Bootstrap MongoDB on first boot via `user_data` (cloud-init shell script)
- Output the VM's public IP after `terraform apply` for manual verification
- Keep the configuration minimal and readable for study purposes

**Non-Goals:**
- Migrating the production MongoDB from Kubernetes to this VM
- Configuring VPC-level private networking between the VM and the K8s cluster (future step)
- High availability or replica sets
- Automated backups or monitoring

## Decisions

### Folder location: `deploy/terraform/`
Following the existing convention (`deploy/docker/`, `deploy/helm/`), all deployment artifacts live under `deploy/`. The `terraform/` subfolder keeps infrastructure-as-code alongside other deployment artifacts.

**Alternatives considered:** repo root `terraform/` — rejected to keep the layout consistent with the existing project structure.

### Provider: `MagaluCloud/mgc`
The official Terraform provider for Magalu Cloud. Credentials are passed via variables (`api_key`) and kept out of source control using a `.tfvars` file (gitignored).

### File structure
```
deploy/terraform/
├── provider.tf       # provider + terraform block
├── main.tf           # mgc_virtual_machine_instances resource
├── variables.tf      # api_key, region, ssh_key_name
├── outputs.tf        # public IP output
└── cloud-init.sh     # MongoDB bootstrap script
```
Single flat folder is sufficient for this study configuration. No modules.

### MongoDB bootstrap via cloud-init
`user_data = filebase64("cloud-init.sh")` installs MongoDB CE on first boot. This avoids any manual SSH step and makes the provisioning fully declarative.

### `allocate_public_ipv4 = true`
Since VPC/private networking between the VM and the K8s cluster is out of scope for now, a public IP is the simplest way to reach the VM for verification.

### SSH key: existing MGC key `k8s-ssh-key-my-cluster-my-pool-46d68`
Reuses the key already registered in MGC — no need to manage a new key pair.

## Risks / Trade-offs

- **MongoDB exposed on public IP** → acceptable for study; should never be used in production without a firewall rule or VPC isolation
- **`BV1-1-10` (1GB RAM) may be tight for MongoDB** → sufficient for a minimal study instance; not suitable for real workloads
- **cloud-init failures are silent at `terraform apply`** → SSH into the VM and check `/var/log/cloud-init-output.log` to verify MongoDB installed correctly

## Migration Plan

1. Run `terraform init` inside `deploy/terraform/`
2. Create a `terraform.tfvars` file with MGC credentials (gitignored)
3. Run `terraform plan` to review what will be created
4. Run `terraform apply` to provision the VM
5. Check output for public IP; SSH in and verify MongoDB is running
6. Run `terraform destroy` to tear down when done studying

## Open Questions

- Which MGC region to use: `br-se1` (consistent with existing infra) or another?
- Should a `.gitignore` be added inside `deploy/terraform/` to exclude `.tfstate` and `.tfvars`?
