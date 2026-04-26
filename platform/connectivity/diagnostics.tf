# ── Remote State — Management ─────────────────────────────────────────────────
# Reads law-platform workspace ID from platform/management state.
# platform/management must be applied before platform/connectivity.

data "terraform_remote_state" "management" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate7tcl"
    container_name       = "tfstate"
    key                  = "platform-management.tfstate"
  }
}

locals {
  law_workspace_id = data.terraform_remote_state.management.outputs.log_analytics_workspace_id
}

# ── NSG Diagnostic Settings ───────────────────────────────────────────────────
# Routes NSG flow logs to centralised law-platform workspace.
# New NSGs added to connectivity must have a corresponding
# diagnostic setting added here.

resource "azurerm_monitor_diagnostic_setting" "nsg_containers" {
  name                       = "diag-nsg-containers"
  target_resource_id         = azurerm_network_security_group.containers.id
  log_analytics_workspace_id = local.law_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg_aks" {
  name                       = "diag-nsg-aks"
  target_resource_id         = azurerm_network_security_group.aks.id
  log_analytics_workspace_id = local.law_workspace_id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}
