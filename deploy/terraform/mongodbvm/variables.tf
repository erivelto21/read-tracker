variable "api_key" {
  type        = string
  sensitive   = true
  description = "Magalu Cloud API key"
}

variable "region" {
  type        = string
  default     = "br-se1"
  description = "MGC region where the VM will be created"
}

variable "availability_zone" {
  type        = string
  default     = "br-se1-c"
  description = "MGC availability zone where the MongoDB VM will be created"
}

variable "ssh_key_name" {
  type        = string
  default     = "my-study-key"
  description = "Name of the SSH key registered in MGC to attach to the VM"
}

variable "vpc_id" {
  type        = string
  default     = "8dd43656-145b-4b9c-94f5-f2d3211d74ab"
  description = "ID of the Kubernetes cluster VPC used by the MongoDB VM"
}

variable "subnet_id" {
  type        = string
  default     = "df8d100a-0dd2-46ad-baae-bba788975587"
  description = "ID of the subnet that will host the MongoDB VM interface"
}

variable "mongodb_private_ip" {
  type        = string
  default     = "172.18.34.72"
  description = "Fixed private IPv4 address assigned to the MongoDB VM interface"
}

variable "mongodb_allowed_source" {
  type        = string
  default     = "172.18.0.0/18"
  description = "CIDR allowed to reach MongoDB on TCP 27017 from the Kubernetes cluster nodes"
}

variable "mongodb_reserved_public_ip_id" {
  type        = string
  default     = "7b555df7-faec-47d7-8d8b-a268d41d1467"
  description = "ID of the reserved Magalu Cloud public IP attached to the MongoDB VM for SSH access"
}

variable "mongo_password" {
  type        = string
  sensitive   = true
  description = "Password for the readtracker MongoDB user created at VM boot"
}

variable "mongodb_data_volume_size" {
  type        = number
  default     = 10
  description = "Size in GB of the persistent MongoDB data volume"
}

variable "mongodb_data_volume_type" {
  type        = string
  default     = "cloud_nvme1k"
  description = "Magalu Cloud block storage type for the MongoDB data volume; defaults to the lowest-cost published tier"
}
