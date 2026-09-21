## MODIFIED Requirements

### Requirement: Secrets are not committed to git
The file `deploy/helm/tracker/values.secret.yaml` SHALL be encrypted with SOPS and committed to git.
Real secret values (MongoDB URI, htpasswd) SHALL only exist in `values.secret.yaml` in encrypted form and never in `values.yaml` as plaintext.

#### Scenario: values.secret.yaml is tracked but encrypted
- **WHEN** `git ls-files deploy/helm/tracker/values.secret.yaml` is run
- **THEN** the file is listed as tracked by git

#### Scenario: values.secret.yaml contains no plaintext secrets
- **WHEN** `cat deploy/helm/tracker/values.secret.yaml` is run
- **THEN** secret values appear as `ENC[AES256_GCM,...]` ciphertext, not plaintext strings

#### Scenario: values.yaml has no real credentials
- **WHEN** `values.yaml` is inspected
- **THEN** secret fields (`mongodbUri`, `nginx.htpasswd`) are empty strings or placeholders
