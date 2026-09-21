## ADDED Requirements

### Requirement: Terraform provisions an MGC Kubernetes cluster baseline
The system SHALL include a Terraform configuration under `deploy/terraform/k8s-cluster/` that provisions a Magalu Cloud Kubernetes cluster matching the current cluster baseline used by the project.

#### Scenario: Cluster created with current baseline defaults
- **WHEN** `terraform apply` is run in `deploy/terraform/k8s-cluster/` with valid credentials
- **THEN** the stack SHALL create an MGC Kubernetes cluster named `my-cluster` in region `br-se1`
- **THEN** the cluster SHALL use Kubernetes version `v1.35.2`
- **THEN** the cluster SHALL use `calico` as the CNI
- **THEN** the cluster SHALL use cluster IPv4 CIDR `192.168.0.0/16`
- **THEN** the cluster SHALL use services IPv4 CIDR `10.96.0.0/12`

### Requirement: Cluster topology matches the current MGC layout
The Terraform configuration SHALL define the Kubernetes cluster topology so it reproduces the current control-plane and worker-pool layout.

#### Scenario: Control plane spans the current availability zones
- **WHEN** the cluster is provisioned from the Terraform stack
- **THEN** the control plane SHALL span availability zones `br-se1-a`, `br-se1-b`, and `br-se1-c`

#### Scenario: Worker pool uses the current fixed-size flavor
- **WHEN** the default worker pool is provisioned
- **THEN** the worker pool SHALL be named `my-pool`
- **THEN** the worker pool SHALL use flavor `BV2-2-40`
- **THEN** the worker pool SHALL use a 40 GB local disk
- **THEN** the worker pool SHALL run with fixed-size scaling at 1 replica
- **THEN** the worker pool SHALL run in availability zone `br-se1-c`

### Requirement: Kubernetes stack is operated independently
The Kubernetes cluster Terraform stack SHALL provide stack-specific workflows and MUST NOT share apply or destroy entrypoints with the MongoDB VM stack.

#### Scenario: Dedicated Make apply target exists
- **WHEN** repository operators need to provision the Kubernetes cluster stack
- **THEN** the repository SHALL provide a Make target named `tf-k8s-apply`
- **THEN** that target SHALL run Terraform against `deploy/terraform/k8s-cluster/`

#### Scenario: Dedicated Make destroy target exists
- **WHEN** repository operators need to tear down the Kubernetes cluster stack
- **THEN** the repository SHALL provide a Make target named `tf-k8s-destroy`
- **THEN** that target SHALL run Terraform destroy against `deploy/terraform/k8s-cluster/`

### Requirement: Kubernetes stack keeps credentials and state out of source control
The Kubernetes Terraform stack SHALL keep credentials and local state untracked in the repository.

#### Scenario: Sensitive local Terraform files are ignored
- **WHEN** a `.gitignore` exists inside `deploy/terraform/k8s-cluster/`
- **THEN** `*.tfvars`, `*.tfstate`, `*.tfstate.backup`, and `.terraform/` SHALL be listed as ignored
