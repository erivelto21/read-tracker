## MODIFIED Requirements

### Requirement: VM attaches to K8s cluster VPC
The MongoDB VM (`mongodb-study`) SHALL be provisioned on the Kubernetes cluster VPC using an explicit network interface in the target subnet, with fixed private IP `172.18.34.72`, enabling private-network reachability from within cluster pods and nodes.

#### Scenario: VM joins cluster VPC with fixed IP
- **WHEN** `terraform apply` completes
- **THEN** the VM SHALL be attached to the Kubernetes cluster VPC
- **THEN** the VM SHALL be assigned the fixed private IP `172.18.34.72`
- **THEN** the VM SHALL be reachable from within the K8s cluster by private-network path

### Requirement: Port 27017 restricted to the Kubernetes node pool subnet
A security group SHALL be attached to the MongoDB VM network interface that allows TCP ingress on port `27017` only from the Kubernetes node pool subnet `172.18.32.0/20`. All other ingress on port `27017` SHALL be denied.

#### Scenario: Approved Kubernetes source can reach MongoDB
- **WHEN** a TCP connection to `mongodb-study:27017` originates from the Kubernetes node pool subnet `172.18.32.0/20`
- **THEN** the connection SHALL be accepted by the VM security group

#### Scenario: Other private-cluster addresses are blocked
- **WHEN** a TCP connection to port `27017` originates from a private address outside `172.18.32.0/20`
- **THEN** the security group SHALL deny the connection

#### Scenario: External access is blocked
- **WHEN** a TCP connection to port `27017` originates from outside the approved private source `172.18.32.0/20`
- **THEN** the security group SHALL deny the connection
