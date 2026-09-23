# Copilot Coding Agent Instructions

This document provides instructions for AI coding agents working on this repository.

## Repository Layout

- `tracker/` — Go API that saves where you stop reading something.
- `nightcrawler/` — Go crawler that fetches newly released chapters.
- `front/` — Frontend UI application (coming soon).
- `deploy/` — All deployment-related artifacts:
  - `deploy/docker/` — Dockerfiles for every workload (`Dockerfile.api`, `Dockerfile.crawler`, `Dockerfile.front`).
  - `deploy/helm/` — Helm chart(s) for cluster deployments.
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
- The root `Makefile` provides one target per workload for building, loading, and pushing images, as well as targets for cluster deployment.

### Rules

Never read, inspect, or search (e.g., via cat, grep, open) the `.env` file directly.

Never read, inspect, or search the age private key at `~/.config/sops/age/keys.txt`.

Secret values live in `deploy/helm/<chart>/values.secret.yaml`, encrypted with SOPS + age and **not tracked by git** (delivered to CI via the `values_file_b64` secret). To read a chart's secret values, use `sops --decrypt deploy/helm/<chart>/values.secret.yaml`. To edit secrets, use `sops deploy/helm/<chart>/values.secret.yaml` — never decrypt manually, edit, and re-encrypt.