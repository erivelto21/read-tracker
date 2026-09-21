output "cluster_id" {
  description = "UUID of the provisioned MGC Kubernetes cluster"
  value       = mgc_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Name of the provisioned MGC Kubernetes cluster"
  value       = mgc_kubernetes_cluster.this.name
}

output "nodepool_id" {
  description = "UUID of the default worker node pool"
  value       = mgc_kubernetes_nodepool.default.id
}
