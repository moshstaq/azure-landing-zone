# Current client (your user) for RBAC
data "azurerm_client_config" "current" {}

# Reference existing VNet for DNS zone link
data "azurerm_virtual_network" "app_dev" {
  name                = "vnet-app-dev"
  resource_group_name = var.resource_group_name
}

# Reference existing subnet for Private Endpoint
data "azurerm_subnet" "data" {
  name                 = "snet-data"
  virtual_network_name = "vnet-app-dev"
  resource_group_name  = var.resource_group_name
}
