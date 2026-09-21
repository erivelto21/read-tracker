## 1. Fix gitignore and tooling

- [x] 1.1 Fix `.gitignore`: change `helm/tracker/values.secret.yaml` to `deploy/helm/tracker/values.secret.yaml` and add `~/.config/sops/age/keys.txt` note in README (file is outside repo, no gitignore needed)
- [x] 1.2 Install `age` locally (`brew install age` / `apt install age` / download from releases)
- [x] 1.3 Install `helm-secrets` plugin: `helm plugin install https://github.com/jkroepke/helm-secrets`

## 2. Generate age key pair

- [x] 2.1 Create key directory: `mkdir -p ~/.config/sops/age`
- [x] 2.2 Generate key pair: `age-keygen -o ~/.config/sops/age/keys.txt`
- [x] 2.3 Copy the public key (printed to stdout) for use in the next step

## 3. Configure SOPS

- [x] 3.1 Create `.sops.yaml` at repo root with a `creation_rules` entry: `path_regex: .*\.secret\.yaml$` pointing to the age public key from step 2.3

## 4. Encrypt the secrets file

- [x] 4.1 Encrypt in-place: `sops --encrypt --in-place deploy/helm/tracker/values.secret.yaml`
- [x] 4.2 Verify encryption: `cat deploy/helm/tracker/values.secret.yaml` should show `ENC[AES256_GCM,...]` for all secret values
- [x] 4.3 Verify decryption works: `helm secrets view deploy/helm/tracker/values.secret.yaml`

## 5. Update deploy target

- [x] 5.1 Update Makefile `deploy-cluster` target: replace `helm upgrade` with `helm secrets upgrade` so secrets are decrypted transparently at deploy time

## 6. Commit and validate

- [x] 6.1 Stage and commit: `.sops.yaml`, encrypted `values.secret.yaml`, updated `.gitignore`, updated `Makefile`
- [x] 6.2 Run `git status` and confirm no plaintext secrets appear in the diff
- [x] 6.3 Run `helm secrets lint deploy/helm/tracker` (or `helm lint`) to confirm chart is still valid
