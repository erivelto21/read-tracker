## 1. Terraform networking model

- [x] 1.1 Refactor `deploy/terraform/main.tf` so the MongoDB VM uses an explicit `mgc_network_vpcs_interfaces` resource with fixed private IP `172.18.34.72`
- [x] 1.2 Update the VM resource to use `network_interface_id` and ensure no public IPv4 is allocated
- [x] 1.3 Attach the MongoDB security group to the explicit network interface and add the outbound rules needed for VM responses and bootstrap traffic

## 2. Terraform security and outputs

- [x] 2.1 Update the MongoDB security group rule so TCP `27017` is allowed only from the Kubernetes node pool subnet `172.18.32.0/20`
- [x] 2.2 Remove or replace any Terraform output that exposes `public_ip`, and ensure `private_ip` is the canonical output with value `172.18.34.72`
- [x] 2.3 Review related Terraform variables or examples so they match the fixed-private-IP, private-only VM design

## 3. Validation and spec alignment

- [x] 3.1 Run targeted Terraform validation/plan commands to confirm the configuration is valid under the new interface-based model
- [x] 3.2 Verify the updated Terraform matches the OpenSpec deltas for `mgc-vm-terraform` and `external-mongodb`
- [x] 3.3 Confirm the change artifacts remain coherent after implementation, especially around ingress scope and private-only access
