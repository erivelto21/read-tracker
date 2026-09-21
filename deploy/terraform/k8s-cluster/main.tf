resource "mgc_kubernetes_cluster" "this" {
  name                 = var.cluster_name
  description          = var.cluster_description
  version              = var.kubernetes_version
  cluster_ipv4_cidr    = var.cluster_ipv4_cidr
  services_ipv4_cidr   = var.services_ipv4_cidr
  allowed_cidrs        = var.allowed_cidrs
  enabled_server_group = var.enabled_server_group
  subnet_ids           = toset(var.cluster_subnet_ids)
}

resource "mgc_kubernetes_nodepool" "default" {
  cluster_id        = mgc_kubernetes_cluster.this.id
  name              = var.nodepool_name
  flavor_name       = var.nodepool_flavor_name
  replicas          = var.nodepool_replicas
  min_replicas      = var.nodepool_min_replicas
  max_replicas      = var.nodepool_max_replicas
  max_pods_per_node = var.nodepool_max_pods_per_node
  subnet_ids        = toset(var.nodepool_subnet_ids)
  version           = var.kubernetes_version
}
