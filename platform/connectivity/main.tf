# Resource group for platform connectivity
resource "azurerm_resource_group" "connectivity" {
  name     = "rg-platform-connectivity"
  location = var.location

  tags = {
    purpose    = "platform-connectivity"
    managed_by = "terraform"
  }
}

# Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    purpose    = "hub-network"
    managed_by = "terraform"
  }
}

# Shared services subnet (future: Azure Firewall, Bastion, etc.)
resource "azurerm_subnet" "shared_services" {
  name                 = "snet-shared-services"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/24"]
}
