variable "api_key" {
  type        = string
  sensitive   = true
  description = "Magalu Cloud API key"
}

variable "region" {
  type        = string
  default     = "br-se1"
  description = "MGC region where the application VM will be created"
}

variable "availability_zone" {
  type        = string
  default     = "br-se1-c"
  description = "MGC availability zone where the application VM and its data volume will be created"
}

variable "ssh_key_name" {
  type        = string
  default     = "my-study-key"
  description = "Name of the SSH key registered in MGC to attach to the VM; defaults to the same key used by the MongoDB VM"
}

# ── VM ────────────────────────────────────────────────────────────────────────
variable "vm_name" {
  type        = string
  default     = "read-tracker-app"
  description = "Name of the application VM that runs the production workloads"
}

variable "machine_type" {
  type        = string
  default     = "BV2-2-40"
  description = "MGC flavor for the application VM; sized to hold the MongoDB working set plus the API and nginx"
}

variable "vm_image" {
  type        = string
  default     = "cloud-ubuntu-24.04 LTS"
  description = "OS image used by the application VM"
}

# ── Networking ────────────────────────────────────────────────────────────────
variable "vpc_name" {
  type        = string
  default     = "read-tracker-app-vpc"
  description = "Name of the VPC owned by this stack, kept separate from the Kubernetes cluster network"
}

variable "subnetpool_name" {
  type        = string
  default     = "read-tracker-app-subnetpool"
  description = "Name of the subnetpool backing the application VM subnet"
}

variable "subnetpool_cidr" {
  type        = string
  default     = "172.20.0.0/16"
  description = "CIDR of the subnetpool; deliberately distinct from the cluster VPC CIDR so both can coexist during migration"
}

variable "subnet_name" {
  type        = string
  default     = "read-tracker-app-subnet"
  description = "Name of the subnet that will host the application VM interface"
}

variable "subnet_cidr_block" {
  type        = string
  default     = "172.20.0.0/24"
  description = "CIDR of the application VM subnet; must fall inside subnetpool_cidr"
}

variable "private_ip" {
  type        = string
  default     = "172.20.0.10"
  description = "Fixed private IPv4 address assigned to the application VM interface"
}

variable "ssh_allowed_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR allowed to reach SSH on the application VM; defaults to the same open access the MongoDB VM uses. Narrow this to the operator network to harden production."
}

variable "http_allowed_cidr" {
  type        = string
  default     = "0.0.0.0/0"
  description = "CIDR allowed to reach the frontend nginx on port 80"
}

# ── Persistent data volume ────────────────────────────────────────────────────
variable "data_volume_size" {
  type        = number
  default     = 20
  description = "Size in GB of the persistent data volume mounted by the workloads"
}

variable "data_volume_type" {
  type        = string
  default     = "cloud_nvme1k"
  description = "MGC block storage type for the data volume; defaults to the lowest-cost published tier"
}