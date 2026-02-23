data "terraform_remote_state" "networking" {
  backend = "azurerm"

  config = {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate7tcl"
    container_name       = "tfstate"
    key                  = "landing-zone-app-dev-networking.tfstate"
  }
}

data "azurerm_log_analytics_workspace" "platform" {
  name                = "law-platform"
  resource_group_name = "rg-platform-management"
}

data "terraform_remote_state" "connectivity" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate7tcl"
    container_name       = "tfstate"
    key                  = "platform-connectivity.tfstate"
  }
}
data "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  virtual_network_name = "vnet-hub"
  resource_group_name  = "rg-platform-connectivity"
}

data "azurerm_resource_group" "connectivity" {
  name = "rg-platform-connectivity"
}

data "azurerm_client_config" "current" {}
