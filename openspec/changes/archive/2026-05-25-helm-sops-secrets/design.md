## Context

The repo uses a Helm chart at `deploy/helm/tracker/` to deploy the tracker stack. Secret values (MongoDB URI, nginx htpasswd) were placed in `values.secret.yaml` and intended to be gitignored — but the `.gitignore` entry points to `helm/tracker/values.secret.yaml` (wrong path), leaving the file unprotected. The goal is to encrypt the file with SOPS + age so it can be safely committed, versioned, and used in CI/CD without manual out-of-band secret sharing.

## Goals / Non-Goals

**Goals:**
- Fix the `.gitignore` path bug immediately
- Adopt SOPS + age as the encryption layer for `values.secret.yaml`
- Allow `values.secret.yaml` (encrypted) to be committed to git
- Enable local decryption with an age key and CI/CD decryption via injected key
- Update the Makefile `helm-apply` target to use `helm secrets upgrade`

**Non-Goals:**
- External secret stores (Vault, AWS SSM) — overkill for this project scope
- Rotating or multi-recipient key management — single developer project
- Encrypting non-Helm secrets (e.g., `.env` files) in this change

## Decisions

### Decision: age over GPG for key management
`age` is chosen over GPG because it has no keyring ceremony, no expiry/trust complexity, and produces a single portable key file. For a single-developer project, this is strictly simpler with no trade-off.

**Alternatives considered:**
- GPG: mature, widely supported, but notoriously complex to manage
- Cloud KMS (AWS, GCP): excellent for teams, but introduces cloud infra dependency

### Decision: `helm-secrets` plugin as the integration layer
`helm-secrets` is the de-facto Helm plugin for SOPS integration. It transparently decrypts `*.secret.yaml` files at `helm upgrade` time, requiring no changes to chart templates or values structure.

**Alternatives considered:**
- Manual `sops -d` before helm: works but error-prone, no CI/CD integration path
- Sealed Secrets (Kubernetes): cluster-side decryption, requires controller install, heavier

### Decision: `.sops.yaml` at repo root with path regex rule
A `.sops.yaml` at repo root with `path_regex: .*\.secret\.yaml$` auto-applies the age public key to any file matching the pattern. This is extensible — future secret files get encrypted automatically without extra config.

### Decision: age private key stored at `~/.config/sops/age/keys.txt` (SOPS default)
Using the SOPS default path means no extra env vars needed locally. In CI/CD, the key is injected as a GitHub Actions secret and written to this path before deploy.

## Risks / Trade-offs

- **[Risk] Key loss = permanent secret loss** → Mitigation: back up the age private key in a password manager (1Password, Bitwarden)
- **[Risk] New contributor onboarding friction** → Mitigation: document key sharing step in README; key only needed for secret changes or deploys
- **[Risk] `helm-secrets` plugin must be installed** → Mitigation: add install step to Makefile and document in README
- **[Risk] Existing `.gitignore` path is wrong** → Mitigation: fix as first task before any other work

## Migration Plan

1. Fix `.gitignore` path (`helm/tracker/` → `deploy/helm/tracker/`)
2. Install `age` and `helm-secrets` plugin locally
3. Generate age key pair, store private key at `~/.config/sops/age/keys.txt`
4. Add `.sops.yaml` at repo root with the public key
5. Encrypt `values.secret.yaml` in-place with `sops --encrypt --in-place`
6. Verify decryption works: `helm secrets view deploy/helm/tracker/values.secret.yaml`
7. Commit encrypted `values.secret.yaml` and `.sops.yaml`
8. Update Makefile `helm-apply` target to use `helm secrets upgrade`
9. Add age key injection step to any CI/CD pipeline that deploys

**Rollback**: remove `values.secret.yaml` from git, restore gitignore rule, remove `.sops.yaml`

## Open Questions

- Should the age public key be documented in the README for transparency? (Recommended: yes, public keys are safe to share)
- Does the project have a CI/CD pipeline today that needs updating? (Check `.github/workflows/`)
