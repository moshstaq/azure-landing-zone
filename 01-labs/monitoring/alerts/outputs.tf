output "action_group_id" {
  description = "Action group for VM alerts"
  value       = azurerm_monitor_action_group.vm_alerts.id
}

output "cpu_alert_id" {
  description = "CPU high alert rule"
  value       = azurerm_monitor_metric_alert.cpu_high.id
}

output "memory_alert_id" {
  description = "Memory high alert rule"
  value       = azurerm_monitor_scheduled_query_rules_alert_v2.memory_high.id
}

output "alerts_summary" {
  description = "Summary of alerts created"
  value = {
    cpu_alert = {
      name      = azurerm_monitor_metric_alert.cpu_high.name
      threshold = "80%"
      severity  = "Warning"
    }
    memory_alert = {
      name      = azurerm_monitor_scheduled_query_rules_alert_v2.memory_high.name
      threshold = "85%"
      severity  = "Warning"
    }
  }
}
