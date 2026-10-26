## 1. Application VM Terraform stack

- [x] 1.1 Create `deploy/terraform/app-vm/` with `provider.tf`, `variables.tf`, `main.tf`, `outputs.tf`, and a stack-local `.gitignore` covering `*.tfvars`, `*.tfstate`, `*.tfstate.backup`, `*.tfstate.*`, and `.terraform/`
- [x] 1.2 Declare the MGC provider pinned to the same version constraint the existing stacks use
- [x] 1.3 Define variables for API key, region, availability zone, SSH key name, VM name, machine type (default `BV2-2-40`), operator SSH CIDR, private IP, data volume size, and data volume type
- [x] 1.4 Provision a dedicated subnetpool, VPC, and subnet for the application VM so it does not depend on the Kubernetes cluster network
- [x] 1.5 Provision the network interface with a configurable fixed private IPv4 address, and attach a reserved public IP owned by the stack
- [x] 1.6 Provision a security group with `disable_default_rules = true` plus rules for inbound TCP `80` from `0.0.0.0/0`, inbound TCP `22` from the operator CIDR variable, and egress
- [x] 1.7 Provision the VM with `user_data` from the cloud-init script, and set `lifecycle { ignore_changes = [user_data] }` so a bootstrap edit does not force a rebuild
- [x] 1.8 Provision the block-storage data volume with configurable size and type, and attach it to the VM
- [x] 1.9 Add outputs for the private IP, the reserved public IP, the VM id, and the data volume id
- [x] 1.10 Add `terraform.tfvars.example` documenting every required variable with placeholder values and no real credentials
- [x] 1.11 Verify the machine type and volume parameters are changeable through variables alone, without editing resource definitions

## 2. VM bootstrap

- [x] 2.1 Create `deploy/terraform/app-vm/cloud-init.sh` following the structure of `deploy/terraform/mongodbvm/cloud-init.sh`, including the logging helpers and the `exec > >(tee -a "$LOG") 2>&1` pattern
- [x] 2.2 Install Docker Engine and the Docker Compose plugin from the official repository, and enable and start the Docker service
- [x] 2.3 Verify the bootstrap script accepts no secret parameters and contains no credential values
- [x] 2.4 Wait for the data volume device, format it only when no filesystem is present, mount it at a fixed path, and persist the mount in `/etc/fstab` with `nofail`
- [x] 2.5 Harden SSH by disabling password authentication and restricting access to the operator CIDR through the security group
- [x] 2.6 Confirm the resulting `user_data` payload contains no secret and that the stack requires no secret variable

## 3. Production Compose deployment

- [x] 3.1 Create `deploy/compose/docker-compose.prod.yml` with the `front`, `api`, and `mongodb` services on a dedicated internal bridge network
- [x] 3.2 Configure the `front` service to publish `80:80` on the host and bind-mount `nginx/default.conf`, `nginx/rate_limit.conf`, and the Basic Auth credentials file
- [x] 3.3 Configure the `api` service with no published ports, reading `MONGO_URI`, `DB_NAME`, and `PORT` from the environment file
- [x] 3.4 Configure the `mongodb` service with no published ports, authentication enabled, and its data directory bind-mounted from the mounted data volume
- [x] 3.5 Reference front and API images by the short commit SHA, supplied as `API_TAG` and `FRONT_TAG` from the environment file — no `latest` anywhere
- [x] 3.6 Set an automatic restart policy on every service so the workload recovers after a crash or VM reboot
- [x] 3.7 Add memory limits sized for the chosen VM flavor so MongoDB and the API do not starve each other
- [x] 3.8 Pin the MongoDB base image to an explicit version rather than a floating tag
- [x] 3.9 Do NOT add a `nightcrawler` service — it has no working image yet and is explicitly out of scope

## 4. Flattened nginx configuration

- [x] 4.1 Create `deploy/compose/nginx/default.conf` reproducing the behavior of `deploy/helm/front/templates/nginx-configmap.yaml` with all `.Values.*` references inlined
- [x] 4.2 Create `deploy/compose/nginx/rate_limit.conf` with the `limit_req_zone` definition using rate `10r/s` and a 10 MB zone
- [x] 4.3 Set the API upstream to the Compose service name and port `8080`, stripping the `/api/` prefix
- [x] 4.4 Keep `auth_basic` at the server block level so both `/` and `/api/` require credentials
- [x] 4.5 Keep `limit_req` on `/api/` with burst `20` and absent from `/`
- [x] 4.6 Verify the flattened config is a new file and that the Helm chart template remains unmodified

## 5. Secret delivery

- [x] 5.1 Create `deploy/compose/.env.example` documenting every variable the deployment needs — including the image tags — with placeholder values
- [x] 5.2 Create `deploy/compose/.env.secret.yaml` with the real values and encrypt it with SOPS under the existing root `.sops.yaml` age rule
- [x] 5.3 Create `scripts/app-vm-deploy.sh` following the conventions of `scripts/mongodb-vm-common.sh` — same logging helpers, same `.env` sourcing, same `terraform output` lookups
- [x] 5.4 Implement decryption of the SOPS secret file into a temporary local environment file and a temporary Basic Auth file, with cleanup on exit
- [x] 5.5 Implement transfer of both files to the VM over SSH with restrictive permissions
- [x] 5.6 Implement `docker compose up -d` on the VM over SSH and fail with a non-zero status naming the failing service when a service does not start
- [x] 5.7 Assert after startup that an unauthenticated request to `/` returns `401`, confirming both nginx and the auth file are active
- [x] 5.8 Confirm the script never writes plaintext secrets to a tracked file and never modifies the `mongodbvm` or `k8s-cluster` stacks

## 6. MongoDB restore script

- [x] 6.1 Create a new restore script that loads a MongoDB dump by running `mongorestore`/`mongosh` inside the MongoDB container via `docker exec`
- [x] 6.2 Read the container name, database name, and credentials from the deployment environment file rather than hardcoding them
- [x] 6.3 Accept the dump file path as an argument, defaulting to the existing dump location used by `scripts/mongodb-vm-dump.sh`
- [x] 6.4 Verify the script never requires port `27017` to be published on the host or opened in the security group
- [x] 6.5 Verify `scripts/mongodb-vm-dump.sh` and `scripts/mongodb-vm-restore.sh` remain unmodified

## 7. Make targets and documentation

- [x] 7.1 Add `tf-app-vm-apply` and `tf-app-vm-destroy` targets that run Terraform against `deploy/terraform/app-vm/` only
- [x] 7.2 Add an `app-vm-deploy` target that runs `scripts/app-vm-deploy.sh`
- [x] 7.3 Add the new targets to the `.PHONY` list without altering any existing target or its behavior
- [x] 7.4 Document the single-VM production path in `README.md` as an additive section, explicitly noting that the Helm and `k8s-cluster` paths remain valid and unmodified, and that production is HTTP-only for now
- [x] 7.5 Document the new layout in `AGENTS.md` under the existing deploy-artifacts conventions
- [x] 7.6 Document that TLS and scheduled MongoDB backups are known gaps and not covered by this change
- [x] 7.7 Add push targets that tag images with the short commit SHA, without modifying the existing `push-api` and `push-front` targets or their `latest` behavior
- [x] 7.8 Verify the SHA-tagged images produced by 7.7 are pullable by the exact tag the Compose file references

## 8. Verification

- [x] 8.1 Run `terraform validate` and `terraform fmt -check` in `deploy/terraform/app-vm/`
- [x] 8.2 Confirm `git status` shows no tracked file under `deploy/helm/`, `deploy/terraform/k8s-cluster/`, `deploy/terraform/mongodbvm/`, or `scripts/mongodb-vm-*.sh` as modified
- [x] 8.3 Confirm `git check-ignore` covers tfvars, state files, and `.terraform/` inside `deploy/terraform/app-vm/`
- [x] 8.4 Confirm no plaintext secret appears in any tracked file, and that `deploy/compose/.env.secret.yaml` is encrypted
- [x] 8.5 Confirm no application image reference in the production Compose file resolves to `latest`
- [x] 8.6 Apply the stack and verify over SSH that Docker is running and the data volume is mounted and persisted in `/etc/fstab`
- [x] 8.7 Verify from outside the VM that ports `8080` and `27017` are refused and that port `80` returns `401` without credentials
- [x] 8.8 Verify the SPA loads at `/` and `GET /api/titles` returns JSON with valid credentials
- [x] 8.9 Reboot the VM and confirm all three services come back automatically and the entrypoint serves requests again
- [x] 8.10 Verify the existing `tf-mongodbvm-*` and `tf-k8s-*` targets still run unchanged
- [ ] 8.11 Migrate the MongoDB data with the new container-based restore script and verify the API returns the migrated titles
- [ ] 8.12 Confirm the flavor, volume tier, and monthly cost against the current Magalu Cloud catalog before keeping the stack applied
