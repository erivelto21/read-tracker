## Context

Production runs today on a Magalu Cloud managed Kubernetes cluster: a `front` nginx Deployment behind a `LoadBalancer` Service, an `api` Deployment behind a `ClusterIP` Service, and a MongoDB instance on a separate VM reached over the cluster VPC. The cluster is sized for availability rather than for the actual traffic — three control-plane nodes plus a worker pool — and its cost is disproportionate to a single low-traffic API.

Two facts about the existing code shape the design more than anything else:

1. **The frontend nginx is already the single entrypoint.** `deploy/helm/front/templates/nginx-configmap.yaml` serves the SPA at `/`, proxies `/api/` to the API with the prefix stripped, enforces `auth_basic` at the server block, and applies `limit_req` to the API location only. The API has no public Service.
2. **The frontend build does not know where the API lives.** `front/.env.production` sets `VITE_API_URL=/api`, a relative URL, and `front/src/api/client.ts` applies it as the axios `baseURL`. The frontend is already correct for a single-entrypoint topology and needs no change.

The API itself is equally portable: `tracker/config/config.go` requires only `MONGO_URI`, `DB_NAME`, and `PORT`, all read from the environment. Nothing in the application is Kubernetes-aware.

The repository is organized as a parent repo with three submodules (`tracker`, `front`, `nightcrawler`), each treated as an independent repository, and `deploy/` holds all deployment artifacts. `AGENTS.md` establishes the conventions this change must follow: Dockerfiles in `deploy/docker/`, one Helm chart per workload, per-stack Terraform directories under `deploy/terraform/`, and secrets in SOPS-encrypted files never tracked by git.

## Goals / Non-Goals

**Goals:**

- Serve production traffic from a single Magalu Cloud VM at a fraction of the current cluster cost
- Preserve the observable production behavior: single public entrypoint, SPA at `/`, API at `/api/`, Basic Auth, API rate limiting
- Keep secrets out of Terraform state and out of source control
- Add the new path without modifying the existing Kubernetes path, so the migration is reversible
- Make credential rotation possible without recreating infrastructure
- Keep the VM size and storage easy to change as real usage becomes known
- Ship without any external prerequisite — no domain, no certificate authority, no DNS dependency

**Non-Goals:**

- Decommissioning the Kubernetes cluster, the Helm charts, or the `k8s-cluster` Terraform stack in this change
- Changing application code in `tracker/`, `front/`, or `nightcrawler/`
- **TLS, a domain name, or a certificate authority** — production serves HTTP with Basic Auth in this first step, exactly as the cluster deployment does today
- Deploying `nightcrawler`, which has no source code yet (`nightcrawler/` contains only `.gitkeep` and `deploy/docker/Dockerfile.crawler` carries a `TODO`)
- Scheduled MongoDB backups — deliberately deferred, and called out as a known gap
- High availability — a single VM is an accepted single point of failure for this cost target
- Replacing the existing MongoDB VM or its dump/restore scripts

## Decisions

### Run Docker Compose on the VM instead of k3s

The workloads run as Docker Compose services on a plain Docker Engine host.

```text
┌─────────────────────────────────────────────────────────────┐
│  VM  read-tracker-app                                       │
│                                                             │
│  network: rtk-internal (bridge, internal)                   │
│                                                             │
│   ┌──────────────────┐    ┌──────────────────┐              │
│   │ front (nginx)    │    │ api (Go)         │              │
│   │ 80:80 ◀── host   │───▶│ 8080 (no host    │              │
│   │ /   → static     │    │      binding)    │              │
│   │ /api/ → proxy    │    └────────┬─────────┘              │
│   └──────────────────┘             │ 27017                 │
│                          ┌─────────▼─────────┐              │
│                          │ mongodb           │              │
│                          │ no host binding   │              │
│                          └─────────┬─────────┘              │
│                                    │                        │
│                         block storage volume                │
└─────────────────────────────────────────────────────────────┘
```

**Alternatives considered:**

- **k3s with the existing Helm charts** — would reuse `deploy/helm/api` and `deploy/helm/front` almost verbatim and give native probes and secrets, but adds roughly 400–800 MB of control-plane and Traefik overhead on a VM whose whole purpose is cost reduction, and reintroduces the orchestration complexity being removed.
- **Podman with Quadlet units** — systemd-native and rootless by default, but adds friction with the private Magalu Cloud registry and is less familiar to the operators running this repository.

### The frontend nginx remains the single entrypoint, with a flattened config

`deploy/helm/front/templates/nginx-configmap.yaml` is a Helm template: it interpolates `.Values.api.host`, `.Values.api.port`, and the rate limit values, and it is stored under a key that Helm projects into a ConfigMap. Compose cannot consume that file directly.

The new deployment therefore carries a flattened, non-templated copy at `deploy/compose/nginx/default.conf` plus `deploy/compose/nginx/rate_limit.conf`, with the values inlined and the API upstream pointing at the Compose service name. **This is a new file, not an edit** — the Helm chart keeps rendering its own copy untouched.

**Alternatives considered:**

- **Parameterizing the Helm config for both runtimes** — rejected: it would require editing a chart that must stay as it is, and Helm's ConfigMap projection has no Compose equivalent anyway.
- **Generating the nginx config at deploy time from the chart template** — rejected: it adds a templating step and a new failure mode for a config that changes rarely.

### Serve HTTP without TLS in this first step

Production serves plain HTTP with Basic Auth, matching the current cluster deployment where the frontend Service is also HTTP. This removes every external prerequisite from the migration: no domain to register, no DNS record to create before deploying, no certificate authority to depend on, and no certificate issuance failure mode.

The trade-off is explicit: Basic Auth credentials are transmitted base64-encoded, not encrypted, so anyone able to observe the traffic can read them. This is not a regression — it is the same exposure the current deployment has.

The design keeps the TLS path open without committing to it. Because nginx is the only published service and the API and MongoDB never leave the internal network, adding a TLS-terminating proxy later means inserting a container in front of nginx and moving the published ports — not restructuring the Compose file or touching the application images.

**Alternatives considered:**

- **Caddy as a TLS edge in front of nginx** — automatic certificates, HTTP-to-HTTPS redirect, and the original scheme preserved via `X-Forwarded-Proto`. Rejected for this step because it makes a public domain and working DNS a hard prerequisite for the migration to work at all, which is a large dependency to take on for a cost-reduction change.
- **TLS terminated by nginx itself with certbot** — keeps one proxy, but adds a second process, a renewal timer, and a reload hook, and still requires the domain.

### Pin application image tags to the short commit SHA

The existing charts default to `tag: latest`, which means a `docker compose pull` could silently change what production runs. The production Compose file references front and API images by a tag supplied from the deployment environment file, and the tag is the **short commit SHA** of the revision the image was built from.

This was chosen over a date counter or semver because it is the only scheme that is both unambiguous and derivable without human judgement: `git rev-parse --short HEAD` produces it, and it resolves back to the exact source revision. The existing `push-api` and `push-front` targets already build and push; they can tag with the SHA instead of `latest`.

**Alternatives considered:**

- **Inherit `latest` for consistency with the charts** — rejected: silent production drift is a worse trade than the small friction of editing a tag.
- **Date plus counter** — readable and chronologically sortable, but requires manual discipline to number and does not identify the source revision.
- **Semver** — communicates release intent, but requires someone to decide and maintain project versioning, which is more process than this project needs.

### Give the application VM its own VPC and subnet

The `mongodbvm` stack attaches its VM to the Kubernetes cluster VPC via hardcoded `vpc_id` and `subnet_id` values described as cluster networking. Reusing that VPC would keep the application VM coupled to the infrastructure being retired: destroying the cluster could take the VPC — and therefore production — with it.

The new stack creates its own VPC, subnetpool, and subnet, so it is independently destroyable and survives the cluster's removal. This requires a `mgc_network_subnetpools` resource plus `mgc_network_vpcs` and `mgc_network_vpcs_subnets`, all confirmed present in the MGC provider schema.

**Alternatives considered:**

- **Reuse the cluster VPC with hardcoded IDs** — rejected: couples production to infrastructure slated for removal.
- **Accept an externally managed VPC as an input variable** — rejected as premature; it adds a required external dependency for a stack that should be self-contained.

### Separate provisioning from configuration to keep secrets out of state

The existing `mongodbvm` stack passes `mongo_password` into `user_data` through `templatefile`, and works around the consequence with `lifecycle { ignore_changes = [user_data] }` — the password is written to `terraform.tfstate` in plaintext, and the ignore rule exists so a password change does not force a VM rebuild.

Repeating that pattern would put the MongoDB password, the full `MONGO_URI`, the Basic Auth hash, and the registry credential into state. Instead:

```text
PHASE 1 — make tf-app-vm-apply
  SG + rules · VPC + subnet · interface + reserved public IP
  VM + data volume · cloud-init (Docker, mount, SSH hardening)
  └─ no secret in user_data

PHASE 2 — make app-vm-deploy
  sops --decrypt → .env + nginx/.htpasswd (local)
  scp → VM
  docker compose up -d
```

This satisfies two requirements at once: secrets never enter state, and rotating a credential re-runs only the cheap second phase.

**Alternatives considered:**

- **Secret in `user_data` with `ignore_changes`, as today** — rejected: it puts live production credentials in a state file that is local, unencrypted, and excluded from git only by a `.gitignore` pattern.
- **Instance profile / metadata service** — rejected: it adds an IAM surface for a single-VM deployment and still needs a bootstrap path for the first secret.

### Secrets ride the existing SOPS + age mechanism

The root `.sops.yaml` already applies an age key to `.*\.secret\.yaml$`, and `scripts/mongodb-vm-common.sh` already demonstrates the environment-file pattern: read a file, `set -a`, source it. The new deployment adds `deploy/compose/.env.secret.yaml` under the same rule and a `scripts/app-vm-deploy.sh` that follows the conventions of the existing `mongodb-vm-*.sh` scripts — same logging helpers, same `terraform output` lookups, same SSH handling.

**Alternatives considered:**

- **A new secret store** — rejected: an existing, working mechanism already covers this, and adding a second one splits the operational story for no benefit.
- **SOPS on the VM** — rejected: it would require the age private key on the VM, widening the blast radius of a key compromise. Decryption stays local.

### Restore MongoDB data through the container, with a new script

The existing `scripts/mongodb-vm-dump.sh` and `mongodb-vm-restore.sh` assume `mongosh` installed on the host and a database reachable at `127.0.0.1:27017`. Neither holds once MongoDB runs as a Compose service with no published port.

A new script performs the restore by streaming the dump into `mongorestore` (or `mongosh`) executed **inside** the MongoDB container via `docker exec`. This avoids publishing `27017` at any point, including during cutover, and leaves the existing scripts untouched.

**Alternatives considered:**

- **Publish `27017` temporarily during cutover** — works with the existing scripts, but requires opening a database port on the security group and remembering to close it. Rejected in favor of a path that never exposes the port.
- **Modify the existing scripts to detect the container runtime** — rejected: it would change scripts that must stay as they are.

### Fix the private IP and reserve the public IP

The interface is created with an explicit `ip_address`, and a reserved public IP owned by the stack is attached to it. This mirrors what the `mongodbvm` stack does, and the `mgc-vm-terraform` spec already records the motivation: a stable endpoint means operators do not have to rediscover an address after a recreate. It also means clients can be pointed at a fixed address, and a future DNS record would not need to change.

### SSH access mirrors the existing MongoDB VM

The SSH key name and the allowed SSH CIDR reuse the values the MongoDB VM already uses: key `my-study-key` and CIDR `0.0.0.0/0`. Both are variables with those defaults, so narrowing either is a one-line change.

This was a deliberate choice for continuity — the operator already has the matching private key and knows the access path — but it carries the same exposure the MongoDB VM has today: SSH open to the internet, with security resting entirely on key-based authentication and password login disabled. The `mgc-vm-terraform` spec records `0.0.0.0/0` SSH as accepted behaviour for that VM, so this is consistent rather than a new class of risk. Narrowing `ssh_allowed_cidr` to the operator network is the single highest-value hardening step available and requires no structural change.

**Alternatives considered:**

- **Restrict SSH to a known operator CIDR by default** — safer, but would break the "same access as the MongoDB VM" requirement the operator asked for, and a wrong CIDR locks the operator out of their own production VM.

### VM size and volume tier are variables, not hardcoded defaults

The VM must carry MongoDB's working set plus the API and nginx, and `mongod` competes for the same RAM and disk as the rest. `BV2-2-40` — the flavor the current Kubernetes worker pool uses — is the default, matching the agreed sizing, but the machine type, volume size, and volume type are all variables so the VM can be resized or its storage retiered without rewriting the stack.

**Assumption to validate:** the monthly cost of the default flavor and volume tier against the current Magalu Cloud catalog. The `mongodbvm` stack defaults to `BV1-1-10` for a VM running MongoDB alone; the application VM runs strictly more.

### Additive Make targets, no existing target touched

New targets `tf-app-vm-apply`, `tf-app-vm-destroy`, and `app-vm-deploy` are added alongside the existing ones. `tf-apply` and `tf-destroy` keep their current composition. Nothing in `deploy/helm/`, `deploy/terraform/k8s-cluster/`, or `deploy/terraform/mongodbvm/` changes.

## Risks / Trade-offs

- **HTTP without TLS** → Basic Auth credentials are transmitted base64-encoded, so anyone able to observe the traffic can read them. This is deliberate parity with the current deployment, not a regression, but it is a real exposure that should not be forgotten once the migration is done. Mitigation: the entrypoint design keeps TLS a drop-in addition later — one container in front of nginx and the published ports move.
- **Single point of failure across the whole stack** → Today MongoDB is already a SPOF, but this change makes the API and frontend share its fate. A VM reboot, host failure, or disk exhaustion takes production fully down. Mitigation: automatic restart policies and a persistent data volume.
- **No scheduled backups** → With the VM as a total SPOF, the absence of backups is the sharpest edge in this design. A host failure loses everything. Deliberately deferred, and recorded here and in the proposal as a known gap rather than an oversight.
- **MongoDB and the API contend for resources on one host** → `mongod` wants memory for its cache and sustained disk throughput. Without explicit resource limits, the API can be starved or the host can be pushed into swap. Mitigation: size the VM for MongoDB's working set, set container memory limits, and keep the data volume on dedicated block storage rather than the root disk.
- **Secrets rest in plaintext on the VM filesystem** → Phase 2 removes secrets from Terraform state, but the environment file and Basic Auth file still exist on disk. Mitigation: restrict file permissions to the deploying user, and treat VM compromise as equivalent to secret compromise. Not a regression — the cluster today holds the same values in Kubernetes Secrets, which are base64 rather than encrypted at rest by default.
- **The `front` image ships nginx defaults, not the production config** → `Dockerfile.front` copies only `dist/` into `nginx:1.27-alpine`; the config arrives as a mounted volume today and as a bind mount in Compose. If the mount is missing, nginx serves without auth and without the API proxy. Mitigation: the deploy step asserts that an unauthenticated request returns `401` before reporting success.
- **Terraform state remains local** → The new stack inherits the repository's local-state convention, consistent with the other two stacks. Fine for a single operator, risky for anything more. Mitigation: out of scope here, but worth a follow-up if more than one person operates production.
- **Block-storage volume tier choice affects cost and IOPS** → The `mongodbvm` stack defaults to `cloud_nvme1k` described as the lowest-cost published tier. Whether that is adequate for production MongoDB load is unverified.

## Migration Plan

1. Provision the application VM stack: `make tf-app-vm-apply`, then verify Docker, the mounted data volume, and SSH hardening over the reserved public IP.
2. Build and push the `read-tracker` and `read-tracker-front` images to the Magalu Cloud registry using the existing `make push-api` and `make push-front` targets, then record the resulting version tags in the Compose file.
3. Create and encrypt `deploy/compose/.env.secret.yaml`, and generate the Basic Auth hash for the nginx credentials file.
4. Run `make app-vm-deploy` and verify the entrypoint returns `401` unauthenticated and serves the SPA and API when authenticated.
5. Migrate MongoDB data using the new container-based restore script, and verify the API returns the migrated titles.
6. Cut clients over to the application VM's reserved public IP. The cluster's existing frontend LoadBalancer address stays available throughout.
7. Observe the VM before decommissioning anything. Only after a stable period should the Kubernetes cluster be scaled down or destroyed, using the existing `tf-k8s-destroy` target.

**Rollback strategy:** point clients back at the cluster's existing frontend LoadBalancer address. Because the cluster, charts, and MongoDB VM remain fully intact throughout this change, rollback requires no infrastructure work — only reverting the address clients use.

## Open Questions

- Should TLS be the immediate next change, or is HTTP with Basic Auth acceptable for longer? The design is deliberately shaped so that adding TLS later is additive.
- Should the production Compose file pin the base image versions too (nginx, MongoDB), or only the application images built from this repository?
- Is a scheduled MongoDB dump on the VM in scope for the next change, given the VM is a total single point of failure?
- What VM flavor and data volume tier are actually required to hold MongoDB's working set plus the API without contention, and what do they cost per month?