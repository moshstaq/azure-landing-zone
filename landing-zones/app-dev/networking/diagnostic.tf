# ─────────────────────────────────────────────────────
# Diagnostic settings — NSG containers subnet
# Sends NSG flow logs to centralized Log Analytics
# ─────────────────────────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "nsg_containers" {
  name                       = "diag-nsg-app-dev-containers"
  target_resource_id         = azurerm_network_security_group.containers.id
  log_analytics_workspace_id = local.law_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

# ─────────────────────────────────────────────────────
# Diagnostic settings — NSG AKS subnet
# ─────────────────────────────────────────────────────
resource "azurerm_monitor_diagnostic_setting" "nsg_aks" {
  name                       = "diag-nsg-app-dev-aks"
  target_resource_id         = azurerm_network_security_group.aks.id
  log_analytics_workspace_id = local.law_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
