output "resource_group_name" {
  description = "Name of the app-dev resource group"
  value       = azurerm_resource_group.app_dev.name
}

output "vnet_app_dev_id" {
  description = "ID of the app-dev virtual network"
  value       = azurerm_virtual_network.app_dev.id
}

output "snet_app_id" {
  description = "ID of the app subnet"
  value       = azurerm_subnet.app.id
}

output "snet_data_id" {
  description = "ID of the data subnet"
  value       = azurerm_subnet.data.id
}

output "snet_containers_id" {
  description = "ID of the containers subnet"
  value       = azurerm_subnet.containers.id
}

output "location" {
  description = "Location of the app-dev resources"
  value       = azurerm_resource_group.app_dev.location
}
