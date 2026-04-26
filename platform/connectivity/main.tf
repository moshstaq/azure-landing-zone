# Resource group for platform connectivity
resource "azurerm_resource_group" "connectivity" {
  name     = "rg-platform-connectivity"
  location = var.location

  tags = {
    Environment = "platform"
    purpose     = "platform-connectivity"
    managed_by  = "terraform"
  }
}

# Hub Virtual Network
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub"
  location            = azurerm_resource_group.connectivity.location
  resource_group_name = azurerm_resource_group.connectivity.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "platform"
    purpose     = "hub-network"
    managed_by  = "terraform"
  }
}

# ── Hub Subnets ──────────────────────────────────────────────────────
# Shared services subnet (future: Azure Firewall, Bastion, etc.)
resource "azurerm_subnet" "shared_services" {
  name                 = "snet-shared-services"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/24"]
}


resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "nva" {
  name                 = "snet-nva"
  resource_group_name  = azurerm_resource_group.connectivity.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = [var.nva_subnet_cidr]

  # No NSG — intentional. NSG evaluation occurs before NVA forwarding.
  # Traffic policy on this subnet is enforced at the OS level on the NVA.
}
