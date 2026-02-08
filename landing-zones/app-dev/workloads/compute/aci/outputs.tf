output "container_group_id" {
  description = "The ID of the container group"
  value       = azurerm_container_group.this.id
}

output "container_group_name" {
  description = "The name of the container group"
  value       = azurerm_container_group.this.name
}

output "private_ip_address" {
  description = "Private IP address of the container group"
  value       = azurerm_container_group.this.ip_address
}

