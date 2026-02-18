# LOG-BASED ALERTS (KQL queries against Log Analytics)
# ─────────────────────────────────────────────────────

# Alert: Azure Policy non-compliance detected
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "policy_noncompliance" {
  name                = "alert-policy-noncompliance"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location

  evaluation_frequency = "PT1H" # check every hour
  window_duration      = "PT1H" # look back 1 hour
  scopes               = [azurerm_log_analytics_workspace.platform.id]
  severity             = 2 # Warning

  criteria {
    query                   = <<-QUERY
      AzureActivity
      | where CategoryValue == "Policy"
      | where ActivityStatusValue == "Failure"
      | summarize count() by bin(TimeGenerated, 1h), ResourceGroup
      | where count_ > 0
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.platform.id]
  }

  tags = {
    Environment = "platform"
    managed_by  = "terraform"
  }
}

# Alert: Terraform apply failures (via GitHub Actions audit logs)
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "terraform_failures" {
  name                = "alert-terraform-apply-failure"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location

  evaluation_frequency = "PT1H"
  window_duration      = "PT1H"
  scopes               = [azurerm_log_analytics_workspace.platform.id]
  severity             = 1 # Error

  criteria {
    query                   = <<-QUERY
      AzureActivity
      | where OperationNameValue contains "deployments"
      | where ActivityStatusValue == "Failure"
      | project TimeGenerated, ResourceGroup, OperationNameValue, Properties
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.platform.id]
  }

  tags = {
    Environment = "platform"
    managed_by  = "terraform"
  }
}

# Alert: NSG deny events (unexpected blocked traffic)
resource "azurerm_monitor_scheduled_query_rules_alert_v2" "nsg_deny_spike" {
  name                = "alert-nsg-deny-spike"
  resource_group_name = azurerm_resource_group.management.name
  location            = azurerm_resource_group.management.location

  evaluation_frequency = "PT15M"
  window_duration      = "PT15M"
  scopes               = [azurerm_log_analytics_workspace.platform.id]
  severity             = 2

  criteria {
    query                   = <<-QUERY
      AzureDiagnostics
      | where Category == "NetworkSecurityGroupRuleCounter"
      | where type_s == "block"
      | summarize DenyCount = sum(matchedConnections_d) by bin(TimeGenerated, 15m)
      | where DenyCount > 100
    QUERY
    time_aggregation_method = "Count"
    threshold               = 0
    operator                = "GreaterThan"

    failing_periods {
      minimum_failing_periods_to_trigger_alert = 1
      number_of_evaluation_periods             = 1
    }
  }

  action {
    action_groups = [azurerm_monitor_action_group.platform.id]
  }

  tags = {
    Environment = "platform"
    managed_by  = "terraform"
  }
}
