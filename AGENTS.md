# Copilot Coding Agent Instructions

This document provides instructions for AI coding agents working on this repository.

## Repository Layout

- `tracker/` — Go API that saves where you stop reading something.
- `nightcrawler/` — Go crawler that fetches newly released chapters.
- `front/` — Frontend UI application (coming soon).
- `deploy/` — All deployment-related artifacts:
  - `deploy/docker/` — Dockerfiles for every workload (`Dockerfile.api`, `Dockerfile.crawler`, `Dockerfile.front`).
  - `deploy/helm/` — Helm chart(s) for cluster deployments.
  - `deploy/compose/` — Single-VM production deployment (Docker Compose). New path, additive; the Helm charts remain valid.
  - `deploy/old-k8s/` — Legacy raw kubectl manifests (deprecated, kept for reference).
- `openspec/` — Architecture specs and change proposals.

## Repository Management

Treat all sub-repositories (e.g., `tracker`, `nightcrawler`, and `front`) as independent repositories.

### Scoped Changes

If it is necessary to update documentation or code that only impacts one repository, modify only that specific repository.

### Isolation

Do not touch or modify any other repositories during that specific task.

### Deploy Artifacts

- Dockerfiles live in `deploy/docker/`. Use `deploy/docker/Dockerfile.<workload>` naming convention.
- Helm charts live in `deploy/helm/`. There are two charts, one per workload: `deploy/helm/api` (backend + MongoDB) and `deploy/helm/front` (frontend nginx reverse proxy).
- The single-VM production deployment lives in `deploy/compose/`. Its nginx config is a **flattened copy** of the Helm chart's `nginx-configmap.yaml` with the `.Values.*` references inlined — the chart template is the source of truth, and both must stay behaviourally identical.
- Terraform stacks live in `deploy/terraform/<stack>/`. Every stack carries its own `.gitignore` for `*.tfvars` and state files; the root `.gitignore` patterns are anchored and do not cover nested stack paths.
- The root `Makefile` provides one target per workload for building, loading, and pushing images, as well as targets for cluster deployment.

### Rules

Never read, inspect, or search (e.g., via cat, grep, open) the `.env` file directly.

Never read, inspect, or search the age private key at `~/.config/sops/age/keys.txt`.

Secret values live in `deploy/helm/<chart>/values.secret.yaml`, encrypted with SOPS + age and **not tracked by git** (delivered to CI via the `values_file_b64` secret). To read a chart's secret values, use `sops --decrypt deploy/helm/<chart>/values.secret.yaml`. To edit secrets, use `sops deploy/helm/<chart>/values.secret.yaml` — never decrypt manually, edit, and re-encrypt.

The single-VM deployment uses the same mechanism: secrets live in `deploy/compose/.env.secret.yaml`, encrypted under the same root `.sops.yaml` age rule. They are decrypted locally and shipped to the VM over SSH by `scripts/app-vm-deploy.sh`, so they never enter Terraform state. Non-secret configuration lives in `deploy/compose/.env`.

### Known gaps (single-VM production)

- **No TLS.** Production serves HTTP with Basic Auth, matching the previous cluster deployment. Adding TLS later should be additive: a terminating proxy in front of nginx, with the published ports moved — not a restructure.
- **No scheduled MongoDB backups.** The single VM is a total single point of failure.
- **`nightcrawler` is not deployed.** It has no source code or working image yet.