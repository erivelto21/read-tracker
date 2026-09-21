## ADDED Requirements

### Requirement: age key pair exists at the SOPS default path
The developer SHALL generate an age key pair and store it at `~/.config/sops/age/keys.txt`. The private key SHALL never be committed to the repository.

#### Scenario: age key file exists locally
- **WHEN** `cat ~/.config/sops/age/keys.txt` is run
- **THEN** the file contains a line starting with `AGE-SECRET-KEY-1`

#### Scenario: age private key is not in the repository
- **WHEN** `git ls-files ~/.config` is run
- **THEN** no results are returned

### Requirement: .sops.yaml configures encryption rules at repo root
The repository SHALL contain a `.sops.yaml` file at the root that applies the age public key to all files matching `.*\.secret\.yaml$`.

#### Scenario: .sops.yaml exists and is committed
- **WHEN** `git show HEAD:.sops.yaml` is run
- **THEN** the file exists and contains a `creation_rules` entry with a `path_regex` and an `age` public key

#### Scenario: Encrypting a secret file uses the correct key
- **WHEN** `sops --encrypt deploy/helm/tracker/values.secret.yaml` is run without extra flags
- **THEN** the output is encrypted using the age key specified in `.sops.yaml`

### Requirement: values.secret.yaml is stored encrypted in git
The file `deploy/helm/tracker/values.secret.yaml` SHALL be encrypted with SOPS and committed to the repository. Plaintext secret values SHALL NOT appear in git history.

#### Scenario: Encrypted file is tracked by git
- **WHEN** `git ls-files deploy/helm/tracker/values.secret.yaml` is run
- **THEN** the file is listed as tracked

#### Scenario: Secret values are not readable without the age key
- **WHEN** the raw file content is inspected (`cat deploy/helm/tracker/values.secret.yaml`)
- **THEN** secret values appear as `ENC[AES256_GCM,...]` ciphertext, not plaintext

#### Scenario: Decryption succeeds with the age key present
- **WHEN** `helm secrets view deploy/helm/tracker/values.secret.yaml` is run with a valid age key
- **THEN** the plaintext YAML is output with readable secret values

### Requirement: helm-secrets plugin is used for deployment
The Makefile `helm-apply` target SHALL use `helm secrets upgrade` (via the `helm-secrets` plugin) instead of plain `helm upgrade`, so secrets are decrypted transparently at deploy time.

#### Scenario: helm-apply uses helm secrets
- **WHEN** the Makefile `helm-apply` target is inspected
- **THEN** it calls `helm secrets upgrade` with the encrypted values file

#### Scenario: Deployment succeeds with encrypted values file
- **WHEN** `make helm-apply` is run with the age key present
- **THEN** helm deploys using the decrypted secret values without requiring manual decryption
