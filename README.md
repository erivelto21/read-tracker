# read-tracker

A monorepo for tracking reading progress and fetching new chapters.

## TODO

- [ ] Create a dns serve.
- [ ] Separe each "resource" in a terraform's folder.
- [ ] Create a terraform for the kubernets.
- [ ] Create the GitLab as a Kubernetes resource.
- [ ] Structure a pipeline for each workload.
- [ ] Implement the crawler.

## Workloads

| Workload | Path | Description |
|---|---|---|
| **tracker** (API) | `tracker/` | Git submodule — Go REST API that saves and retrieves reading progress |
| **nightcrawler** | `nightcrawler/` | Git submodule — Go crawler that fetches newly released chapters |
| **front** | `front/` | Git submodule — frontend UI application |

## Project Structure

```
read-tracker/
├── tracker/           # Go API source
├── nightcrawler/      # Go crawler source
├── front/             # Frontend UI application
├── deploy/            # All deployment artifacts
│   ├── docker/        # Dockerfiles for every workload
│   │   ├── Dockerfile.api
│   │   ├── Dockerfile.crawler
│   │   └── Dockerfile.front
│   ├── helm/          # Helm chart(s)
│   ├── old-k8s/       # Legacy kubectl manifests (deprecated)
│   └── terraform/     # Terraform stacks for MGC infrastructure
│       ├── k8s-cluster/
│       └── mongodbvm/
├── openspec/          # Architecture specs and change 
```

## Makefile Targets

## Cloning

Clone the meta-repository together with its workload submodules:

```bash
git clone --recurse-submodules <repo-url>
```

If you already cloned it without submodules:

```bash
git submodule update --init --recursive
```

### API

| Target | Description |
|---|---|
| `make build-api` | Build the `read-tracker-api` Docker image |
| `make load-api` | Load the image into the local Kind cluster |
| `make push-api` | Build and push the image to the remote registry |

### Crawler

| Target | Description |
|---|---|
| `make build-crawler` | Build the `read-tracker-crawler` Docker image |
| `make load-crawler` | Load the image into the local Kind cluster |
| `make push-crawler` | Build and push the image to the remote registry |

### Front

| Target | Description |
|---|---|
| `make build-front` | Build the `read-tracker-front` Docker image |
| `make load-front` | Load the image into the local Kind cluster |
| `make push-front` | Build and push the image to the remote registry |

### Cluster

| Target | Description |
|---|---|
| `make registry-login` | Authenticate against the container registry |
| `make deploy-cluster` | Install / upgrade the Helm release in the cluster |
| `make helm-down` | Uninstall the Helm release from the cluster |

### Terraform

| Target | Description |
|---|---|
| `make tf-mongodbvm-apply` | Provision the MongoDB VM Terraform stack |
| `make tf-mongodbvm-destroy` | Back up and tear down the MongoDB VM Terraform stack |
| `make tf-k8s-apply` | Provision the MGC Kubernetes cluster Terraform stack |
| `make tf-k8s-destroy` | Tear down the MGC Kubernetes cluster Terraform stack |
| `make tf-apply` | Provision both Terraform stacks in dependency order (`k8s` then `mongodbvm`) |
| `make tf-destroy` | Tear down both Terraform stacks in dependency order (`mongodbvm` then `k8s`) |

## Local Development

Start the database dependency:

```bash
docker compose up -d
```

Run the API locally:

```bash
make -C tracker run
```

Run the API tests:

```bash
make -C tracker test
```

## Helm Chart

The Helm chart lives at `deploy/helm/tracker`. Secret values are encrypted with [SOPS](https://github.com/getsops/sops) + [age](https://github.com/FiloSottile/age) and committed to the repository as `deploy/helm/tracker/values.secret.yaml`.

### Prerequisites

Install the required tools once:

```bash
# age — encryption key management
sudo apt install age          # Debian/Ubuntu
brew install age              # macOS

# sops — encrypts/decrypts structured files
# Download from https://github.com/getsops/sops/releases
# or: brew install sops

# helm-secrets — decrypts secrets transparently during helm deploy
helm plugin install https://github.com/jkroepke/helm-secrets
```

### First-time setup

Generate your age key pair and store it at the SOPS default path:

```bash
mkdir -p ~/.config/sops/age
age-keygen -o ~/.config/sops/age/keys.txt
# Public key is printed to stdout — keep it, you'll need it if rotating keys
```

> ⚠️ Back up `~/.config/sops/age/keys.txt` in a password manager. If you lose it, encrypted secrets are unrecoverable.

### Working with secrets

**Edit secrets** (opens decrypted in `$EDITOR`, saves re-encrypted):

```bash
sops deploy/helm/tracker/values.secret.yaml
```

**View decrypted content without editing:**

```bash
sops --decrypt deploy/helm/tracker/values.secret.yaml
```

**Encrypt a new `*.secret.yaml` file from scratch:**

```bash
sops --encrypt --in-place path/to/new.secret.yaml
```

> Never manually decrypt → edit → re-encrypt. Always use `sops <file>` to edit in place.

### Deploying

`make deploy-cluster` uses `helm secrets upgrade` under the hood — it decrypts `values.secret.yaml` transparently at deploy time. No manual step required as long as your age key is present at `~/.config/sops/age/keys.txt`.

```bash
make deploy-cluster
```

### CI/CD

Inject the age private key as a secret (e.g., `AGE_PRIVATE_KEY` in GitHub Actions) and write it to the expected path before deploying:

```yaml
- name: Set up age key
  run: |
    mkdir -p ~/.config/sops/age
    echo "${{ secrets.AGE_PRIVATE_KEY }}" > ~/.config/sops/age/keys.txt
    chmod 600 ~/.config/sops/age/keys.txt
```
