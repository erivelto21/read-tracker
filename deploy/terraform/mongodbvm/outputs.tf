output "private_ip" {
  description = "Private IPv4 address of the MongoDB VM (within the K8s VPC)"
  value       = mgc_virtual_machine_instances.mongodb.local_ipv4
}

output "public_ip" {
  description = "Reserved public IPv4 address attached to the MongoDB VM for SSH access"
  value       = data.mgc_network_public_ip.mongodb_reserved.public_ip
}
