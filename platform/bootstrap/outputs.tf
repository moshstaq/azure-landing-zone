output "resource_group_name" {
  description = "Name of the tfstate resource group"
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "Name of the tfstate storage account"
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "Name of the tfstate container"
  value       = azurerm_storage_container.tfstate.name
}
