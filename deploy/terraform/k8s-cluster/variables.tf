variable "api_key" {
  type        = string
  sensitive   = true
  description = "Magalu Cloud API key"
}

variable "region" {
  type        = string
  default     = "br-se1"
  description = "MGC region where the Kubernetes cluster will be created"
}

variable "cluster_name" {
  type        = string
  default     = "my-cluster"
  description = "Name of the MGC Kubernetes cluster"
}

variable "cluster_description" {
  type        = string
  default     = "my-cluster"
  description = "Description of the MGC Kubernetes cluster"
}

variable "kubernetes_version" {
  type        = string
  default     = "v1.35.2"
  description = "Kubernetes version for the control plane and default node pool"
}

variable "cluster_ipv4_cidr" {
  type        = string
  default     = "192.168.0.0/16"
  description = "Pod CIDR used by the Kubernetes cluster"
}

variable "services_ipv4_cidr" {
  type        = string
  default     = "10.96.0.0/12"
  description = "Service CIDR used by the Kubernetes cluster"
}

variable "allowed_cidrs" {
  type        = list(string)
  default     = []
  description = "Allowed CIDRs for Kubernetes API server access"
}

variable "enabled_server_group" {
  type        = bool
  default     = true
  description = "Enable server-group anti-affinity during cluster creation"
}

variable "cluster_subnet_ids" {
  type        = list(string)
  default     = ["6c6f85dc-a41e-4949-a2d6-1c2ecfe801c0", "0113275d-ca8b-4152-8d44-f0efa5d84c86", "df8d100a-0dd2-46ad-baae-bba788975587"]
  description = "One subnet per availability zone for the control plane and default cluster networking"
}

variable "nodepool_name" {
  type        = string
  default     = "my-pool"
  description = "Name of the default worker node pool"
}

variable "nodepool_flavor_name" {
  type        = string
  default     = "BV2-2-40"
  description = "MGC flavor used by the default worker node pool"
}

variable "nodepool_replicas" {
  type        = number
  default     = 1
  description = "Initial number of worker nodes in the default node pool"
}

variable "nodepool_min_replicas" {
  type        = number
  default     = 1
  description = "Minimum number of worker nodes for the default node pool autoscaling bounds"
}

variable "nodepool_max_replicas" {
  type        = number
  default     = 1
  description = "Maximum number of worker nodes for the default node pool autoscaling bounds"
}

variable "nodepool_max_pods_per_node" {
  type        = number
  default     = 110
  description = "Maximum number of pods per worker node"
}

variable "nodepool_subnet_ids" {
  type        = list(string)
  default     = ["df8d100a-0dd2-46ad-baae-bba788975587"]
  description = "Subnet IDs used by the default worker node pool"
}
