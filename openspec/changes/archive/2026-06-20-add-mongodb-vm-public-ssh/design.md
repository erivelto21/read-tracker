## Context

The existing Terraform capability provisions a single MongoDB VM in Magalu Cloud with a fixed private IP and a security group that only permits MongoDB access from the Kubernetes node CIDR. The VM currently has no public IPv4 address and stores MongoDB data on the instance root disk, which means operators cannot SSH directly from the internet and recreated VMs risk losing database state. This change spans Terraform networking, security groups, block storage, outputs, and cloud-init bootstrap behavior.

## Goals / Non-Goals

**Goals:**
- Preserve the current fixed private IP design used by in-cluster clients.
- Add a public IPv4 path for SSH administration without opening MongoDB to the public internet.
- Persist MongoDB data on a reusable Magalu Cloud block storage volume.
- Make bootstrap idempotent so a recreated VM can reuse an existing data volume safely.
- Install `conntrack` during bootstrap to satisfy operational requirements on the VM.

**Non-Goals:**
- Changing the MongoDB application authentication model beyond what is needed for idempotent bootstrap.
- Allowing public access to MongoDB on port 27017.
- Introducing backups, replication, or high-availability behavior.
- Reworking Kubernetes or Helm configuration outside of the Terraform-managed VM contract.

## Decisions

### Keep the explicit private network interface and attach a public IP resource

The VM will continue to use the existing `mgc_network_vpcs_interfaces` resource with the fixed private IP so current consumers keep the same internal address. Public access will be added with `mgc_network_public_ips` plus `mgc_network_public_ips_attach` targeting that interface.

This approach is preferred over `allocate_public_ipv4 = true` because the Magalu provider does not allow `allocate_public_ipv4` together with `network_interface_id`. Keeping the explicit interface also avoids changing the current private-network topology.

### Allow SSH from public IPv4 sources while keeping MongoDB private

The security group will gain a dedicated ingress rule for TCP 22 from `0.0.0.0/0`. The existing MongoDB ingress rule on TCP 27017 will remain restricted to `var.mongodb_allowed_source`.

This matches the requested access model: SSH is allowed for anyone with the configured SSH key, while the database port continues to accept connections only from the private source CIDR.

### Use a separate persistent block storage volume for MongoDB data

Terraform will provision a `mgc_block_storage_volumes` resource and attach it to the VM with `mgc_block_storage_volume_attachment`. The volume type will default to `cloud_nvme1k`, which is the lowest-cost block storage tier identified for Magalu Cloud among the published NVMe options.

Using an attached volume decouples MongoDB data from the VM lifecycle so the VM can be recreated without discarding database files. Keeping the volume type configurable by variable preserves flexibility if Magalu Cloud later introduces a cheaper tier or if performance requirements change.

### Mount the attached volume by UUID before MongoDB starts

Cloud-init will wait for the attached disk to appear, create a filesystem only if none exists, record its UUID in `/etc/fstab`, and mount it at MongoDB's data directory before starting `mongod`. Mounting by UUID avoids device-name instability across reboots or recreations.

This is preferred over mounting by `/dev/*` name because attached-disk device names are less stable and can vary across boots. Formatting only when the disk has no filesystem prevents accidental data loss when the VM is recreated.

### Make bootstrap safe to rerun against an existing data volume

The bootstrap script will only create the MongoDB application user when it does not already exist. MongoDB configuration changes such as enabling auth and binding to all interfaces will be applied idempotently.

This avoids failures on a recreated VM where the reused data volume already contains a populated database and an existing user definition.

### Publish both private and public IP outputs

Terraform outputs will continue to expose the private IP and will also expose the allocated public IP so operators can discover the SSH endpoint after apply.

## Risks / Trade-offs

- **[SSH exposed to the internet]** → Mitigation: only port 22 is public, access still requires the configured SSH key, and MongoDB remains restricted to the private CIDR.
- **[Cheapest storage tier may provide limited IOPS]** → Mitigation: keep volume size and type configurable so the default can remain low-cost while allowing overrides if MongoDB workload grows.
- **[Bootstrap may race the attached volume]** → Mitigation: cloud-init should explicitly wait for the block device before formatting or mounting it.
- **[Reusing existing MongoDB files can fail if mount order is wrong]** → Mitigation: mount the persistent volume before starting `mongod` and enable the service only after filesystem setup is complete.
- **[Public IP may persist and incur charges after VM replacement]** → Mitigation: manage the public IP explicitly in Terraform so its lifecycle is visible and output to operators.

## Migration Plan

1. Apply Terraform changes to create the public IP, SSH ingress rule, persistent volume, and attachment.
2. On first rollout, cloud-init formats and mounts the new volume, then bootstraps MongoDB onto it.
3. After apply, operators use the new `public_ip` output for SSH and the existing `private_ip` output for private-network clients.
4. On VM recreation, Terraform reuses the existing private IP, public IP attachment, and data volume; cloud-init remounts the volume and skips destructive initialization steps.
5. Rollback consists of removing the new Terraform resources and bootstrap logic, with the caveat that data migration off the attached volume must be handled before detaching or deleting storage.

## Open Questions

- None at this time.
