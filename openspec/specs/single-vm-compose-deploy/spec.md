# single-vm-compose-deploy Specification

## Purpose
Defines how the front, API, and MongoDB workloads run together on a single production VM using Docker Compose, with the frontend nginx as the only public entrypoint and the API and database reachable only on an internal container network.

## Requirements

### Requirement: All three workloads run as Compose services on one VM

The production deployment SHALL run the frontend, the tracker API, and MongoDB as Docker Compose services on a single Magalu Cloud VM, replacing the current Kubernetes deployment for production traffic.

#### Scenario: All services reach running state

- **WHEN** the production Compose file is applied on a provisioned VM
- **THEN** the `front`, `api`, and `mongodb` services SHALL all reach a running state
- **THEN** no Kubernetes cluster SHALL be required for the deployment to serve production traffic

#### Scenario: Front and API images come from the existing registry

- **WHEN** the Compose file resolves its image references
- **THEN** the front image SHALL be `read-tracker-front` from the Magalu Cloud container registry
- **THEN** the API image SHALL be `read-tracker` from the Magalu Cloud container registry

### Requirement: Image tags are pinned to a source revision

The production Compose file SHALL reference front and API images by an explicit tag derived from the source revision they were built from, supplied as a deployment value, and SHALL NOT use the `latest` tag. Pulling images SHALL never change what production runs without a deliberate edit.

#### Scenario: No floating tag in the production file

- **WHEN** the production Compose file is inspected
- **THEN** every application image reference SHALL carry a tag supplied from a deployment value
- **THEN** no application image reference SHALL resolve to `latest`

#### Scenario: Tag identifies the source revision

- **WHEN** an operator needs to know which code production is running
- **THEN** the running image tag SHALL identify the source revision it was built from
- **THEN** that revision SHALL be resolvable back to a commit

#### Scenario: Tag change is an explicit action

- **WHEN** an operator deploys a new application version
- **THEN** the version SHALL be changed by editing the tag value in the deployment environment file
- **THEN** the running containers SHALL NOT change version as a side effect of pulling

### Requirement: Only the frontend port is published to the host

The Compose deployment SHALL publish exactly one port to the host — the frontend nginx on port `80`. The API and MongoDB services SHALL NOT publish any port to the host and SHALL be reachable only over the internal Compose network.

#### Scenario: Frontend is reachable from the internet

- **WHEN** a request is made to the VM public IP on port `80`
- **THEN** the frontend nginx SHALL accept the connection

#### Scenario: API port is not exposed on the host

- **WHEN** a TCP connection is attempted against the VM public IP on port `8080`
- **THEN** the connection SHALL be refused
- **THEN** the API SHALL still be reachable from the frontend service over the internal network

#### Scenario: MongoDB port is not exposed on the host

- **WHEN** a TCP connection is attempted against the VM public IP on port `27017`
- **THEN** the connection SHALL be refused
- **THEN** MongoDB SHALL still be reachable from the API service over the internal network

### Requirement: nginx serves the SPA and proxies the API

The frontend nginx configuration SHALL serve the built React application at `/` using SPA fallback routing, and SHALL proxy requests under `/api/` to the API service with the `/api/` prefix stripped, preserving the behavior the cluster deployment provides today.

#### Scenario: SPA deep links resolve

- **WHEN** a request is made to `GET /some/deep/route` with valid credentials
- **THEN** nginx SHALL return the React application HTML with status `200` instead of a `404`

#### Scenario: API call reaches the API service

- **WHEN** an authenticated request is made to `GET /api/titles`
- **THEN** nginx SHALL forward it as `GET /titles` to the API service on port `8080`
- **THEN** the JSON response from the API SHALL be returned to the client

### Requirement: HTTP Basic Auth protects the entire entrypoint

The nginx configuration SHALL apply HTTP Basic Auth at the server block level so that both static file serving at `/` and the API proxy at `/api/` require credentials. The credentials file SHALL be supplied at deploy time and SHALL NOT be stored in the Compose file or in source control.

#### Scenario: Unauthenticated request is rejected

- **WHEN** a request is made to `GET /` without an `Authorization` header
- **THEN** the response status SHALL be `401`

#### Scenario: Unauthenticated API request is rejected

- **WHEN** a request is made to `GET /api/titles` without an `Authorization` header
- **THEN** the response status SHALL be `401`

#### Scenario: Authenticated request succeeds

- **WHEN** a request is made to `GET /` with valid Basic Auth credentials
- **THEN** the response status SHALL be `200`

### Requirement: Rate limiting applies to the API proxy only

The nginx configuration SHALL apply `limit_req` to the `/api/` location using a rate limit zone of `10r/s` with a burst of `20`, and SHALL NOT rate limit static file serving at `/`.

#### Scenario: Rate limit zone defined

- **WHEN** the rendered nginx configuration is inspected
- **THEN** a `limit_req_zone` directive SHALL define a zone with rate `10r/s`
- **THEN** `limit_req` SHALL be present in the `/api/` location
- **THEN** `limit_req` SHALL be absent from the `/` location

### Requirement: MongoDB runs with authentication enabled

MongoDB SHALL run as a container on the internal network with authentication enabled, bound to the container network rather than to a public interface, and SHALL expose a `readtracker` user with `readWrite` access to the `read_tracker` database.

#### Scenario: Unauthenticated connection is rejected

- **WHEN** a client connects to MongoDB on the internal network without credentials
- **THEN** MongoDB SHALL return an authentication failure

#### Scenario: API authenticates successfully

- **WHEN** the API service starts with a `MONGO_URI` containing valid credentials
- **THEN** the API SHALL establish an authenticated connection to MongoDB
- **THEN** the API SHALL serve requests from the `read_tracker` database

### Requirement: MongoDB data persists on a dedicated volume

MongoDB data SHALL be stored on a dedicated block-storage volume attached to the VM and mounted at a fixed path, so that database files survive container recreation and VM replacement.

#### Scenario: Data survives container recreation

- **WHEN** the `mongodb` service is recreated
- **THEN** the previously written database files SHALL still be present

#### Scenario: Data volume is mounted from the VM block storage

- **WHEN** the VM is inspected after provisioning
- **THEN** the dedicated data volume SHALL be mounted at the MongoDB data path
- **THEN** the mount SHALL be persisted so it survives a VM reboot

### Requirement: Services restart automatically after failure or reboot

Each Compose service SHALL be configured to restart automatically, so that the workload recovers without operator intervention after a process crash or a VM reboot.

#### Scenario: Service recovers after reboot

- **WHEN** the VM is rebooted
- **THEN** the frontend, API, and MongoDB services SHALL start again automatically
- **THEN** the frontend SHALL serve requests on port `80` without manual intervention
