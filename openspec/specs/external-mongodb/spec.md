# external-mongodb

Purpose

TBD — external MongoDB hosted on a VM outside the Kubernetes cluster. This spec defines requirements for provisioning, network placement, security, and Helm integration so the API can use an external MongoDB instance without application changes.

## Requirements

### Requirement: VM attaches to K8s cluster VPC
The MongoDB VM (`mongodb-study`) SHALL be provisioned on the Kubernetes cluster VPC using an explicit network interface in the target subnet, with fixed private IP `172.18.34.72`, enabling private-network reachability from within cluster pods and nodes.

#### Scenario: VM joins cluster VPC with fixed IP
- **WHEN** `terraform apply` completes
- **THEN** the VM SHALL be attached to the Kubernetes cluster VPC
- **THEN** the VM SHALL be assigned the fixed private IP `172.18.34.72`
- **THEN** the VM SHALL be reachable from within the K8s cluster by private-network path

### Requirement: Port 27017 restricted to the Kubernetes cluster node CIDR
A security group SHALL be attached to the MongoDB VM network interface that allows TCP ingress on port `27017` only from the Kubernetes cluster node CIDR `172.18.0.0/18`. All other ingress on port `27017` SHALL be denied.

#### Scenario: Approved Kubernetes source can reach MongoDB
- **WHEN** a TCP connection to `mongodb-study:27017` originates from the Kubernetes cluster node CIDR `172.18.0.0/18`
- **THEN** the connection SHALL be accepted by the VM security group

#### Scenario: Other private-cluster addresses are blocked
- **WHEN** a TCP connection to port `27017` originates from a private address outside `172.18.0.0/18`
- **THEN** the security group SHALL deny the connection

#### Scenario: External access is blocked
- **WHEN** a TCP connection to port `27017` originates from outside the approved private source `172.18.0.0/18`
- **THEN** the security group SHALL deny the connection

### Requirement: MongoDB authentication enabled at provisioning time
The `cloud-init.sh` script SHALL configure MongoDB to require authentication and create a user `readtracker` with `readWrite` role on the `read_tracker` database. MongoDB SHALL bind to `0.0.0.0` to accept connections from the private network interface.

#### Scenario: Auth user created on first boot
- **WHEN** the VM boots for the first time and `cloud-init` runs
- **THEN** a MongoDB user `readtracker` exists with `readWrite` access to `read_tracker`

#### Scenario: Unauthenticated connections are rejected
- **WHEN** a client connects to `mongodb-study:27017` without credentials
- **THEN** MongoDB returns an `AuthenticationFailed` error

### Requirement: Helm chart supports switchable MongoDB backend
The Helm chart SHALL expose a `mongodb.external.enabled` boolean flag in `values.yaml`. When `false` (default), the chart renders the existing in-cluster StatefulSet and headless Service. When `true`, the chart renders only an `ExternalName` Service pointing to the hostname defined in `mongodb.external.host` and omits the StatefulSet.

#### Scenario: Default mode — in-cluster MongoDB
- **WHEN** `mongodb.external.enabled` is `false`
- **THEN** the StatefulSet `mongo` and headless Service `mongo` (ClusterIP: None) are rendered
- **THEN** no ExternalName Service is rendered

#### Scenario: External mode — VM MongoDB
- **WHEN** `mongodb.external.enabled` is `true`
- **THEN** an ExternalName Service `mongo` pointing to `mongodb.external.host` is rendered
- **THEN** the StatefulSet `mongo` is NOT rendered

#### Scenario: API connects transparently
- **WHEN** `mongodb.external.enabled` is `true`
- **THEN** the `tracker` API connects to `mongo:27017` and routes to the VM MongoDB without any application code change

### Requirement: MONGO_URI includes credentials for external MongoDB
When `mongodb.external.enabled` is `true`, the `MONGO_URI` secret value in `values.secret.yaml` SHALL use the format `mongodb://<user>:<password>@mongodb-study:27017/<dbname>` and be encrypted with SOPS.

#### Scenario: API authenticates to external MongoDB
- **WHEN** the API pod starts with `mongodb.external.enabled = true`
- **THEN** the `MONGO_URI` env var contains valid credentials
- **THEN** the API successfully establishes an authenticated connection to the VM MongoDB
