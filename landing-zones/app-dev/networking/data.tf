# landing-zones/app-dev/networking/data.tf
# -----------------------------------------------------------------------------
# Remote State: Read hub networking outputs
# This creates a dependency chain: hub must exist before spoke can be deployed
# -----------------------------------------------------------------------------

data "terraform_remote_state" "connectivity" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate7tcl"
    container_name       = "tfstate"
    key                  = "platform-connectivity.tfstate"
  }
}

# -----------------------------------------------------------------------------
# Local values: Map remote state outputs to readable names
# This provides a single place to manage the interface between modules
# -----------------------------------------------------------------------------

locals {
  hub_vnet_id             = data.terraform_remote_state.connectivity.outputs.vnet_hub_id
  hub_vnet_name           = data.terraform_remote_state.connectivity.outputs.vnet_hub_name
  hub_resource_group_name = data.terraform_remote_state.connectivity.outputs.resource_group_name
}
