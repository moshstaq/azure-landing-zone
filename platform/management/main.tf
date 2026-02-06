# Resource group for platform management
resource "azurerm_resource_group" "management" {
  name     = "rg-platform-management"
  location = var.location

  tags = {
    purpose    = "platform-management"
    managed_by = "terraform"
  }
}

# Log Analytics Workspace for centralized logging
resource "azurerm_log_analytics_workspace" "platform" {
  name                = "law-platform"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    purpose    = "centralized-logging"
    managed_by = "terraform"
  }
}
