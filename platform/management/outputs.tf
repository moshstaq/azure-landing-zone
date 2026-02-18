output "resource_group_name" {
  description = "Name of the management resource group"
  value       = azurerm_resource_group.management.name
}

output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.platform.id
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = azurerm_log_analytics_workspace.platform.name
}

output "action_group_id" {
  description = "ID of the central platform action group"
  value       = azurerm_monitor_action_group.platform.id
}
