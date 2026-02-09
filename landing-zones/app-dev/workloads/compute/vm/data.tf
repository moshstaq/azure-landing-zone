# Reference existing subnet in app-dev spoke
data "azurerm_subnet" "app" {
  name                 = "snet-app"
  virtual_network_name = "vnet-app-dev"
  resource_group_name  = var.resource_group_name
}

# Reference existing Log Analytics workspace for monitoring (Phase 2)
data "azurerm_log_analytics_workspace" "platform" {
  name                = "law-platform"
  resource_group_name = "rg-platform-management"
}


data "azurerm_client_config" "current" {}
