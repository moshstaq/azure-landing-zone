# ─────────────────────────────────────────────────────
# Subscription Activity Log diagnostic setting
# Forwards all Azure Activity Logs to law-platform
# Feeds: alert-policy-noncompliance
#        alert-terraform-apply-failure
# ─────────────────────────────────────────────────────
data "azurerm_subscription" "current" {}

resource "azurerm_monitor_diagnostic_setting" "activity_logs" {
  name                       = "diag-activity-logs-to-law"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id

  enabled_log {
    category = "Administrative"
  }

  enabled_log {
    category = "Security"
  }

  enabled_log {
    category = "ServiceHealth"
  }

  enabled_log {
    category = "Alert"
  }

  enabled_log {
    category = "Recommendation"
  }

  enabled_log {
    category = "Policy"
  }

  enabled_log {
    category = "Autoscale"
  }

  enabled_log {
    category = "ResourceHealth"
  }
}
