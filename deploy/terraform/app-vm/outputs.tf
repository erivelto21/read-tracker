output "private_ip" {
  description = "Private IPv4 address of the application VM inside its own VPC"
  value       = mgc_virtual_machine_instances.app.local_ipv4
}

output "public_ip" {
  description = "Reserved public IPv4 address of the application VM, used for HTTP and SSH"
  value       = mgc_network_public_ips.app.public_ip
}

output "vm_id" {
  description = "UUID of the application VM"
  value       = mgc_virtual_machine_instances.app.id
}

output "data_volume_id" {
  description = "UUID of the persistent data volume attached to the application VM"
  value       = mgc_block_storage_volumes.app_data.id
}