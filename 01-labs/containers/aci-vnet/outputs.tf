output "container_subnet_id" {
  description = "ID of the container subnet"
  value       = azurerm_subnet.containers.id
}

output "container_subnet_cidr" {
  description = "CIDR of the container subnet"
  value       = azurerm_subnet.containers.address_prefixes[0]
}

output "private_api_ip" {
  description = "Private IP address of the API container"
  value       = azurerm_container_group.private_api.ip_address
}

output "private_api_dns" {
  description = "DNS name for the private API"
  value       = "api.${azurerm_private_dns_zone.containers.name}"
}

output "nsg_name" {
  description = "NSG protecting the container subnet"
  value       = azurerm_network_security_group.containers.name
}

output "dns_zone_name" {
  description = "Private DNS zone name"
  value       = azurerm_private_dns_zone.containers.name
}


output "useful_commands" {
  description = "Useful AZ CLI commands"
  value = {
    view_container   = "az container show -g ${data.azurerm_resource_group.containers.name} -n ${azurerm_container_group.private_api.name} -o table"
    view_logs        = "az container logs -g ${data.azurerm_resource_group.containers.name} -n ${azurerm_container_group.private_api.name}"
    check_dns_record = "az network private-dns record-set a show -g ${data.azurerm_resource_group.containers.name} -z ${azurerm_private_dns_zone.containers.name} -n api"
  }
}
