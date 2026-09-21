## ADDED Requirements

### Requirement: VM attaches to K8s cluster VPC
The MongoDB VM (`mongodb-study`) SHALL be provisioned with an explicit `vpc_id` and `subnet_id` matching the Kubernetes cluster VPC (`8dd43656-145b-4b9c-94f5-f2d3211d74ab`) and node subnet (AZ-c, `172.18.32.0/20`), enabling MGC internal DNS resolution from within cluster pods.

#### Scenario: VM joins cluster VPC
- **WHEN** `terraform apply` completes
- **THEN** the VM is assigned a private IP in the `172.18.32.0/20` subnet and is reachable by the hostname `mongodb-study` from within the K8s cluster

### Requirement: Port 27017 restricted to K8s node subnets
A security group SHALL be attached to the MongoDB VM that allows TCP ingress on port `27017` only from the CIDR `172.18.0.0/18` (covering all K8s node subnets: AZ-a `172.18.0.0/20`, AZ-b `172.18.16.0/20`, AZ-c `172.18.32.0/20`). All other ingress on port `27017` SHALL be denied.

#### Scenario: K8s pods can reach MongoDB
- **WHEN** a pod in the cluster initiates a TCP connection to `mongodb-study:27017`
- **THEN** the connection is accepted by the VM security group

#### Scenario: External access is blocked
- **WHEN** a TCP connection to port `27017` originates from outside `172.18.0.0/18`
- **THEN** the security group denies the connection

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
