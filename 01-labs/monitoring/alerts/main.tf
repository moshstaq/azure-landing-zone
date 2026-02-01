#--------------------------------------------------------------
# Action Group (who to notify)
#--------------------------------------------------------------
resource "azurerm_monitor_action_group" "vm_alerts" {
  name                = "ag-vm-alerts"
  resource_group_name = data.azurerm_resource_group.monitoring.name
  short_name          = "vmalerts"

  tags = {
    Environment = var.environment
    Lab         = "3.3"
  }
}


#--------------------------------------------------------------
# CPU Alert - Fires when CPU > 80% for 5 minutes
#--------------------------------------------------------------

resource "azurerm_monitor_metric_alert" "cpu_high" {
  name                = "alert-cpu-high-vm-dev-001"
  resource_group_name = data.azurerm_resource_group.monitoring.name
  scopes              = [data.azurerm_virtual_machine.vm.id]
  description         = "Alert when CPU exceeds 80% for 5 minutes"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Compute/virtualMachines"
    metric_name      = "Percentage CPU"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 80
  }

  action {
    action_group_id = azurerm_monitor_action_group.vm_alerts.id
  }

  tags = {
    Environment = var.environment
    Lab         = "3.3"
  }
}

#--------------------------------------------------------------
# Memory Alert - Using Log Analytics query
#--------------------------------------------------------------


resource "azurerm_monitor_scheduled_query_rules_alert_v2" "memory_high" {
  name                = "alert-memory-high-vm-dev-001"
  resource_group_name = data.azurerm_resource_group.monitoring.name
  location            = var.location
  description         = "Alert when memory usage exceeds 85%"
  severity            = 2

  scopes               = [data.azurerm_log_analytics_workspace.main.id]
  evaluation_frequency = "PT5M"
  window_duration      = "PT5M"

  criteria {
    query = <<-KQL
      Perf
      | where ObjectName == "Memory" and CounterName == "% Used Memory"
      | where Computer contains "vm-dev-001"
      | summarize AvgMemory = avg(CounterValue) by bin(TimeGenerated, 5m), Computer
      | where AvgMemory > 85
    KQL

    time_aggregation_method = "Count"
    operator                = "GreaterThan"
    threshold               = 0

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.vm_alerts.id]
  }

  tags = {
    Environment = var.environment
    Lab         = "3.3"
  }
}
