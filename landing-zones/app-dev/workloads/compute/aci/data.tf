# -----------------------------------------------------------------------------
# Remote State: Read networking outputs
# -----------------------------------------------------------------------------

data "terraform_remote_state" "networking" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate7tcl"
    container_name       = "tfstate"
    key                  = "landing-zone-app-dev-networking.tfstate"
  }
}

# -----------------------------------------------------------------------------
# Data source: Current subscription
# -----------------------------------------------------------------------------

data "azurerm_client_config" "current" {}

# -----------------------------------------------------------------------------
# Locals: Map remote state outputs
# -----------------------------------------------------------------------------

locals {
  subscription_id     = data.azurerm_client_config.current.subscription_id
  resource_group_name = data.terraform_remote_state.networking.outputs.resource_group_name
  subnet_id           = data.terraform_remote_state.networking.outputs.snet_containers_id
}
