## 1. Terraform — VM Networking & Security

- [x] 1.1 Add `vpc_id` variable (default: `8dd43656-145b-4b9c-94f5-f2d3211d74ab`) to `variables.tf`
- [x] 1.2 Add `subnet_id` variable (default: `df8d100a-0dd2-46ad-baae-bba788975587`, AZ-c) to `variables.tf`
- [x] 1.3 Add `mongo_password` sensitive variable to `variables.tf`
- [x] 1.4 Attach `mongodb-study` VM to the K8s VPC by setting `vpc_id` and `subnet_id` on the `mgc_virtual_machine_instances` resource in `main.tf`
- [x] 1.5 Add `mgc_network_security_groups` resource `mongodb-sg` with `disable_default_rules = true` in `main.tf`
- [x] 1.6 Add `mgc_network_security_groups_rules` resource allowing TCP port `27017` ingress from `172.18.0.0/18` in `main.tf`
- [x] 1.7 Add `private_ip` output to `outputs.tf`

## 2. Terraform — MongoDB Auth via cloud-init

- [x] 2.1 Update `cloud-init.sh` to change MongoDB `bindIp` from `127.0.0.1` to `0.0.0.0` in `/etc/mongod.conf`
- [x] 2.2 Update `cloud-init.sh` to enable `security.authorization` in `/etc/mongod.conf`
- [x] 2.3 Update `cloud-init.sh` to create the `readtracker` MongoDB user with `readWrite` on `read_tracker` using `mongosh` after service start
- [x] 2.4 Copy `deploy/terraform/terraform.tfvars.example` → `terraform.tfvars`, fill in `mongo_password`, then run `make tf-apply`. Verify VM boots with auth enabled and is reachable at `mongodb-study` from a cluster pod

## 3. Helm — Conditional Flag & Templates

- [x] 3.1 Add `mongodb.external.enabled` (bool, default `false`) and `mongodb.external.host` (string, default `"mongodb-study"`) to `values.yaml`
- [x] 3.2 Wrap `db-statefulset.yaml` in `{{- if not .Values.mongodb.external.enabled }}` … `{{- end }}`
- [x] 3.3 Update `db-service.yaml` to conditionally render headless Service (when `external.enabled = false`) or `ExternalName` Service pointing to `mongodb.external.host` (when `external.enabled = true`)
- [x] 3.4 Deploy chart with `mongodb.external.enabled = false` and verify no behavior change (in-cluster StatefulSet still works)

## 4. Helm Secrets — Switch to External MongoDB

- [x] 4.1 Decrypt `values.secret.yaml` with SOPS and set `mongodb.external.enabled: true`
- [x] 4.2 Update `secrets.mongodbUri` to `mongodb://readtracker:<password>@mongodb-study:27017/read_tracker` in `values.secret.yaml`
- [x] 4.3 Re-encrypt and save `values.secret.yaml` with SOPS
- [x] 4.4 Run `helm upgrade` and verify all `tracker` API pods reconnect to the VM MongoDB successfully

## 5. Decommission In-Cluster MongoDB

- [x] 5.1 Confirm API is stable on VM MongoDB (check logs, `/healthz` probe)
- [x] 5.2 Delete the in-cluster PVC `mongo-data-mongo-0` in namespace `read-tracker`
