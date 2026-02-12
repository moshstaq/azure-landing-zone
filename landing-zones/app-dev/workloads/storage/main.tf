#--------------------------------------------------------------
# Data Sources
#--------------------------------------------------------------

# Get subnet for Private Endpoint

data "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = var.resource_group_name
}


data "azurerm_subnet" "data" {
  name                 = var.subnet_name
  virtual_network_name = var.vnet_name
  resource_group_name  = var.resource_group_name
}

# Get VM state for Managed Identity principal_id
data "terraform_remote_state" "vm" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate7tcl"
    container_name       = "tfstate"
    key                  = "lz-app-dev-vm.tfstate"
  }
}

#--------------------------------------------------------------
# Random Suffix (Storage account names must be globally unique)
#--------------------------------------------------------------

resource "random_string" "storage_suffix" {
  length  = 6
  special = false
  upper   = false # Storage accounts: lowercase only!
}

#--------------------------------------------------------------
# Storage Account
#--------------------------------------------------------------

resource "azurerm_storage_account" "main" {
  name                = "stappdev${random_string.storage_suffix.result}"
  resource_group_name = var.resource_group_name
  location            = var.location

  # Standard tier, Locally Redundant (cheapest option)
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security settings
  min_tls_version            = "TLS1_2"
  https_traffic_only_enabled = true


  allow_nested_items_to_be_public = false


  tags = var.tags
}

#--------------------------------------------------------------
# Blob Container
#--------------------------------------------------------------

resource "azurerm_storage_container" "uploads" {
  name                 = var.container_name
  storage_account_name = azurerm_storage_account.main.name

  container_access_type = "private" # No anonymous access
}
