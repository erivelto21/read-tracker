## 1. Terraform Reserved Public IP Contract

- [x] 1.1 Update `deploy/terraform` so the MongoDB VM public IP resource and outputs enforce the reserved SSH endpoint `169.150.1.49`
- [x] 1.2 Validate that Terraform apply/destroy/apply keeps the MongoDB VM reachable at `169.150.1.49`

## 2. Script Simplification

- [x] 2.1 Update the MongoDB VM helper scripts to use `169.150.1.49` as the default SSH host instead of resolving it dynamically from Terraform output
- [x] 2.2 Keep script behavior aligned with the reserved IP contract while preserving MongoDB readiness and credential handling

## 3. Contract Verification

- [x] 3.1 Validate that backup/restore flows still work with the fixed SSH host contract
- [x] 3.2 Verify the final operator-facing workflow no longer depends on discovering an arbitrary public IP after apply
