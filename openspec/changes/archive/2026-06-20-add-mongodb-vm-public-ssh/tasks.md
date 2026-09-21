## 1. Terraform networking and storage

- [x] 1.1 Add Terraform resources for a public IP and attach it to the existing MongoDB network interface.
- [x] 1.2 Add a public SSH ingress rule while preserving the private-only MongoDB ingress rule.
- [x] 1.3 Add Terraform resources and variables for the persistent MongoDB block storage volume using the low-cost default volume type.
- [x] 1.4 Add Terraform outputs for the MongoDB VM public IP while keeping the private IP output.

## 2. VM bootstrap and MongoDB data persistence

- [x] 2.1 Update `cloud-init.sh` to install `conntrack` together with MongoDB dependencies.
- [x] 2.2 Update `cloud-init.sh` to detect, format if needed, and mount the attached block volume by UUID at the MongoDB data directory before `mongod` starts.
- [x] 2.3 Make MongoDB bootstrap idempotent so recreated VMs can reuse an existing data volume without reformatting or failing on existing users.

## 3. Validation and operator readiness

- [x] 3.1 Review the Terraform configuration to ensure the explicit private IP design remains intact and the public IP is attached through the existing interface.
- [x] 3.2 Verify the documented default storage tier and variable names align with the intended cheapest-volume behavior.
- [x] 3.3 Run the smallest existing Terraform validation or formatting commands used by this repository and confirm the changed files are ready for apply.
