output "resource_group_name" {
  description = "Name of the connectivity resource group"
  value       = azurerm_resource_group.connectivity.name
}

output "vnet_hub_name" {
  description = "Name of the hub virtual network"
  value       = azurerm_virtual_network.hub.name
}

output "vnet_hub_id" {
  description = "ID of the hub virtual network"
  value       = azurerm_virtual_network.hub.id
}

output "snet_shared_services_id" {
  description = "ID of the shared services subnet"
  value       = azurerm_subnet.shared_services.id
}

output "snet_appgw_id" {
  description = "Application Gateway subnet ID"
  value       = azurerm_subnet.appgw.id
}
