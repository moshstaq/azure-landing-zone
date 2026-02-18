# Resource group for app-dev landing zone
resource "azurerm_resource_group" "app_dev" {
  name     = "rg-app-dev"
  location = var.location

  tags = {
    Environment = "dev"
    workload    = "app"
    managed_by  = "terraform"
  }
}

# Spoke Virtual Network
resource "azurerm_virtual_network" "app_dev" {
  name                = "vnet-app-dev"
  location            = azurerm_resource_group.app_dev.location
  resource_group_name = azurerm_resource_group.app_dev.name
  address_space       = ["10.1.0.0/16"]

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# Application subnet
resource "azurerm_subnet" "app" {
  name                 = "snet-app"
  resource_group_name  = azurerm_resource_group.app_dev.name
  virtual_network_name = azurerm_virtual_network.app_dev.name
  address_prefixes     = ["10.1.1.0/24"]
}

# Data subnet
resource "azurerm_subnet" "data" {
  name                 = "snet-data"
  resource_group_name  = azurerm_resource_group.app_dev.name
  virtual_network_name = azurerm_virtual_network.app_dev.name
  address_prefixes     = ["10.1.2.0/24"]
}

# Containers subnet (with delegation for ACI)
resource "azurerm_subnet" "containers" {
  name                 = "snet-containers"
  resource_group_name  = azurerm_resource_group.app_dev.name
  virtual_network_name = azurerm_virtual_network.app_dev.name
  address_prefixes     = ["10.1.3.0/24"]

  delegation {
    name = "aci-delegation"

    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

# NSG for containers subnet
resource "azurerm_network_security_group" "containers" {
  name                = "nsg-app-dev-containers"
  location            = azurerm_resource_group.app_dev.location
  resource_group_name = azurerm_resource_group.app_dev.name

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# Associate NSG with containers subnet
resource "azurerm_subnet_network_security_group_association" "containers" {
  subnet_id                 = azurerm_subnet.containers.id
  network_security_group_id = azurerm_network_security_group.containers.id
}

# Peering: Spoke to Hub
resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  name                      = "peer-appdev-to-hub"
  resource_group_name       = azurerm_resource_group.app_dev.name
  virtual_network_name      = azurerm_virtual_network.app_dev.name
  remote_virtual_network_id = local.hub_vnet_id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# Peering: Hub to Spoke
resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  name                      = "peer-hub-to-appdev"
  resource_group_name       = local.hub_resource_group_name
  virtual_network_name      = local.hub_vnet_name
  remote_virtual_network_id = azurerm_virtual_network.app_dev.id

  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# AKS subnet (larger for Azure CNI - 1 IP per pod)
resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.app_dev.name
  virtual_network_name = azurerm_virtual_network.app_dev.name
  address_prefixes     = ["10.1.4.0/22"]
}

# NSG for AKS subnet
resource "azurerm_network_security_group" "aks" {
  name                = "nsg-app-dev-aks"
  location            = azurerm_resource_group.app_dev.location
  resource_group_name = azurerm_resource_group.app_dev.name

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# Associate NSG with AKS subnet
resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}
