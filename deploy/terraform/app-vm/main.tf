# Application VM for the single-VM production deployment.
#
# This stack is deliberately self-contained: it owns its own network so that
# destroying the Kubernetes cluster (and its VPC) cannot take production with it.
# It carries no secret values — bootstrap is infrastructure-only, and application
# secrets are delivered later by scripts/app-vm-deploy.sh over SSH.

# ── Network ───────────────────────────────────────────────────────────────────
resource "mgc_network_subnetpools" "app" {
  name        = var.subnetpool_name
  description = "Subnetpool for the read-tracker application VM network"
  cidr        = var.subnetpool_cidr
}

resource "mgc_network_vpcs" "app" {
  name        = var.vpc_name
  description = "VPC dedicated to the read-tracker application VM"
}

resource "mgc_network_vpcs_subnets" "app" {
  name              = var.subnet_name
  description       = "Subnet hosting the read-tracker application VM interface"
  vpc_id            = mgc_network_vpcs.app.id
  subnetpool_id     = mgc_network_subnetpools.app.id
  cidr_block        = var.subnet_cidr_block
  ip_version        = "IPv4"
  availability_zone = var.availability_zone
}

# ── Security group ────────────────────────────────────────────────────────────
resource "mgc_network_security_groups" "app" {
  name                  = "read-tracker-app-sg"
  description           = "Allow public HTTP, restrict SSH to the operator CIDR, and block every other inbound port"
  disable_default_rules = true
}

resource "mgc_network_security_groups_rules" "app_http_ingress" {
  description       = "Allow HTTP to the frontend nginx"
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_min    = 80
  port_range_max    = 80
  protocol          = "tcp"
  remote_ip_prefix  = var.http_allowed_cidr
  security_group_id = mgc_network_security_groups.app.id
}

resource "mgc_network_security_groups_rules" "app_ssh_ingress" {
  description       = "Allow SSH only from the operator CIDR"
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_min    = 22
  port_range_max    = 22
  protocol          = "tcp"
  remote_ip_prefix  = var.ssh_allowed_cidr
  security_group_id = mgc_network_security_groups.app.id
}

resource "mgc_network_security_groups_rules" "app_egress_ipv4" {
  description       = "Allow outbound IPv4 traffic so the VM can pull images and reach the registry"
  direction         = "egress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = mgc_network_security_groups.app.id
}

# ── Interface and public IP ───────────────────────────────────────────────────
resource "mgc_network_vpcs_interfaces" "app" {
  name       = "read-tracker-app-primary"
  vpc_id     = mgc_network_vpcs.app.id
  subnet_ids = [mgc_network_vpcs_subnets.app.id]
  ip_address = var.private_ip
}

resource "mgc_network_security_groups_attach" "app" {
  security_group_id = mgc_network_security_groups.app.id
  interface_id      = mgc_network_vpcs_interfaces.app.id
}

# Owned by this stack rather than referencing a pre-existing reserved IP, so the
# address stays stable across VM recreation and the stack is independently destroyable.
resource "mgc_network_public_ips" "app" {
  description = "Reserved public IPv4 for the read-tracker application VM"
  vpc_id      = mgc_network_vpcs.app.id
}

resource "mgc_network_public_ips_attach" "app" {
  public_ip_id = mgc_network_public_ips.app.id
  interface_id = mgc_network_vpcs_interfaces.app.id
}

# ── VM ────────────────────────────────────────────────────────────────────────
resource "mgc_virtual_machine_instances" "app" {
  name                 = var.vm_name
  machine_type         = var.machine_type
  image                = var.vm_image
  ssh_key_name         = var.ssh_key_name
  network_interface_id = mgc_network_vpcs_interfaces.app.id
  availability_zone    = var.availability_zone

  # Bootstrap installs Docker, mounts the data volume, and hardens SSH.
  # It receives no secret: application credentials arrive in the deploy phase.
  user_data = base64encode(file("${path.module}/cloud-init.sh"))

  # Editing the bootstrap script must not force a VM rebuild.
  lifecycle {
    ignore_changes = [user_data]
  }
}

# ── Persistent data volume ────────────────────────────────────────────────────
resource "mgc_block_storage_volumes" "app_data" {
  name              = "read-tracker-app-data"
  availability_zone = var.availability_zone
  size              = var.data_volume_size
  type              = var.data_volume_type
}

resource "mgc_block_storage_volume_attachment" "app_data" {
  block_storage_id   = mgc_block_storage_volumes.app_data.id
  virtual_machine_id = mgc_virtual_machine_instances.app.id
}