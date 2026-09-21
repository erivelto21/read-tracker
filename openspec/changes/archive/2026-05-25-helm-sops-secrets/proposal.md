## Why

The `values.secret.yaml` file contains real credentials (MongoDB URI, nginx htpasswd) and is intended to be gitignored, but the `.gitignore` path is wrong (`helm/tracker/` vs `deploy/helm/tracker/`), leaving secrets unprotected. Beyond fixing this bug, encrypting secrets with SOPS + age allows the file to be safely committed, versioned, and reviewed — aligning with the community gold standard for Helm secrets management.

## What Changes

- Fix `.gitignore` to use the correct path `deploy/helm/tracker/values.secret.yaml`
- Add `.sops.yaml` at the repo root to configure encryption rules for secret value files
- Encrypt `values.secret.yaml` using SOPS + age so the encrypted file can be committed
- Update `.gitignore` to ignore the age private key and any plaintext secret overrides
- Update the `helm-chart` spec requirement: secrets are now encrypted-in-git, not gitignored

## Capabilities

### New Capabilities
- `sops-secrets`: SOPS + age encryption for Helm secret values — defines how secrets are encrypted, committed, decrypted locally, and used in CI/CD pipelines

### Modified Capabilities
- `helm-chart`: The "Secrets are not committed to git" requirement changes — `values.secret.yaml` will now be committed in encrypted form rather than being gitignored

## Impact

- `deploy/helm/tracker/values.secret.yaml` — encrypted and committed
- `.sops.yaml` — new file at repo root
- `.gitignore` — path fix + age key exclusion
- `openspec/specs/helm-chart/spec.md` — updated secrets requirement
- Makefile `helm-apply` target may need updating to use `helm secrets upgrade`
- CI/CD pipelines will need the age private key injected as a secret
