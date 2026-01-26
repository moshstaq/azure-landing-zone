# Data source: Get hub VNet info

data "azurerm_virtual_network" "hub" {
  name                = "vnet-moshstaq-hub"
  resource_group_name = "rg-moshstaq-platform-network"
}

# Resource Group for Dev Spoke
resource "azurerm_resource_group" "spoke_dev_rg" {
  name     = "rg-spoke-dev"
  location = "eastus2"
  tags = {
    Environment = "dev"
    Project     = "azure-landing-zone"
    ManagedBy   = "terraform"
  }
}

# Spoke VNet Module Call
module "spoke_dev_vnet" {
  source              = "../../../modules/spoke-vnet"
  spoke_name          = "dev"
  location            = azurerm_resource_group.spoke_dev_rg.location
  resource_group_name = azurerm_resource_group.spoke_dev_rg.name
  address_space       = ["10.1.0.0/16"]
  subnets = {
    app = {
      address_prefix = ["10.1.1.0/24"]
    }
    data = {
      address_prefix = ["10.1.2.0/24"]
    }
  }

  # hub peering details
  hub_vnet_id             = data.azurerm_virtual_network.hub.id
  hub_vnet_name           = data.azurerm_virtual_network.hub.name
  hub_resource_group_name = data.azurerm_virtual_network.hub.resource_group_name

  tags = {
    Environment = "dev"
    Project     = "azure-landing-zone"
    ManagedBy   = "terraform"
  }

}
