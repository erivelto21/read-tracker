resource "mgc_network_security_groups_rules" "mongodb_ingress" {
  description       = "Allow MongoDB from the Kubernetes node pool subnet"
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_min    = 27017
  port_range_max    = 27017
  protocol          = "tcp"
  remote_ip_prefix  = var.mongodb_allowed_source
  security_group_id = mgc_network_security_groups.mongodb.id
}

resource "mgc_network_security_groups_rules" "mongodb_ssh_ingress" {
  description       = "Allow SSH from public IPv4 sources"
  direction         = "ingress"
  ethertype         = "IPv4"
  port_range_min    = 22
  port_range_max    = 22
  protocol          = "tcp"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = mgc_network_security_groups.mongodb.id
}

resource "mgc_network_security_groups_rules" "mongodb_egress_ipv4" {
  description       = "Allow outbound IPv4 traffic from the MongoDB VM"
  direction         = "egress"
  ethertype         = "IPv4"
  remote_ip_prefix  = "0.0.0.0/0"
  security_group_id = mgc_network_security_groups.mongodb.id
}

resource "mgc_network_security_groups" "mongodb" {
  name                  = "mongodb-study-sg"
  description           = "Allow public SSH access and restrict MongoDB access to the Kubernetes source IP"
  disable_default_rules = true
}

resource "mgc_network_security_groups_attach" "mongodb" {
  security_group_id = mgc_network_security_groups.mongodb.id
  interface_id      = mgc_network_vpcs_interfaces.mongodb.id
}

resource "mgc_network_vpcs_interfaces" "mongodb" {
  name       = "mongodb-study-primary"
  vpc_id     = var.vpc_id
  subnet_ids = [var.subnet_id]
  ip_address = var.mongodb_private_ip
}

data "mgc_network_public_ip" "mongodb_reserved" {
  id = var.mongodb_reserved_public_ip_id
}

resource "mgc_network_public_ips_attach" "mongodb" {
  public_ip_id = data.mgc_network_public_ip.mongodb_reserved.id
  interface_id = mgc_network_vpcs_interfaces.mongodb.id
}

resource "mgc_virtual_machine_instances" "mongodb" {
  name                 = "mongodb-study"
  machine_type         = "BV1-1-10"
  image                = "cloud-ubuntu-24.04 LTS"
  ssh_key_name         = var.ssh_key_name
  network_interface_id = mgc_network_vpcs_interfaces.mongodb.id
  availability_zone    = var.availability_zone
  user_data = base64encode(templatefile("${path.module}/cloud-init.sh", {
    mongo_password = var.mongo_password
  }))

  lifecycle {
    ignore_changes = [user_data]
  }
}

resource "mgc_block_storage_volumes" "mongodb_data" {
  name              = "mongodb-study-data"
  availability_zone = var.availability_zone
  size              = var.mongodb_data_volume_size
  type              = var.mongodb_data_volume_type
}

resource "mgc_block_storage_volume_attachment" "mongodb_data" {
  block_storage_id   = mgc_block_storage_volumes.mongodb_data.id
  virtual_machine_id = mgc_virtual_machine_instances.mongodb.id
}
