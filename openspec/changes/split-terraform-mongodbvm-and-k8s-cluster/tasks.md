## 1. Split the MongoDB VM Terraform stack

- [x] 1.1 Move the existing MongoDB VM Terraform files into `deploy/terraform/mongodbvm/` and update any path-sensitive references
- [x] 1.2 Add or update stack-local `.gitignore` rules in `deploy/terraform/mongodbvm/` for tfvars, state files, and `.terraform/`
- [x] 1.3 Replace the generic MongoDB Terraform Make targets with `tf-mongodbvm-apply` and `tf-mongodbvm-destroy`, preserving the existing dump and restore hooks

## 2. Add the Kubernetes cluster Terraform stack

- [x] 2.1 Create `deploy/terraform/k8s-cluster/` with provider, variables, and resource definitions for the MGC Kubernetes cluster baseline
- [x] 2.2 Configure the cluster defaults to match the current live baseline for region, Kubernetes version, CNI, cluster CIDR, and service CIDR
- [x] 2.3 Configure the default worker pool to use name `my-pool`, flavor `BV2-2-40`, 40 GB local disk, fixed-size scaling, and zone `br-se1-c`
- [x] 2.4 Add outputs and stack-local `.gitignore` rules for the Kubernetes Terraform stack

## 3. Wire the operational workflow

- [x] 3.1 Add `tf-k8s-apply` and `tf-k8s-destroy` Make targets that run Terraform only against `deploy/terraform/k8s-cluster/`
- [x] 3.2 Update Terraform usage documentation and command references to describe the new stack layout and explicit Make targets
- [x] 3.3 Validate that both Terraform stacks can be initialized independently and that the Make targets point to the correct directories
