# Reference existing resource group

data "azurerm_resource_group" "labs" {
  name = "rg-${var.your_name}-lab-compute"

}

data "azurerm_resource_group" "rg-spoke-dev" {
  name = "rg-spoke-dev"
}



# Reference existing virtual network
data "azurerm_virtual_network" "spoke_dev" {
  name                = "vnet-spoke-dev"
  resource_group_name = data.azurerm_resource_group.rg-spoke-dev.name

}

# Reference existing subnet
data "azurerm_subnet" "app" {
  name                 = "snet-app"
  virtual_network_name = data.azurerm_virtual_network.spoke_dev.name
  resource_group_name  = data.azurerm_resource_group.rg-spoke-dev.name
}

# Reference existing Log Analytics Workspace
data "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.your_name}-main"
  resource_group_name = "rg-moshstaq-platform-core"
}

# Read SSH public key
data "local_file" "ssh_public_key" {
  filename = pathexpand(var.ssh_public_key_path)
}
