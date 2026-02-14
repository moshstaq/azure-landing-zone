#--------------------------------------------------------------
# Data Sources
#--------------------------------------------------------------

data "azurerm_log_analytics_workspace" "platform" {
  name                = "law-platform"
  resource_group_name = "rg-platform-management"
}

#--------------------------------------------------------------
# Container Group with VNet Integration
#--------------------------------------------------------------
resource "azurerm_container_group" "this" {
  name                = var.container_group_name
  location            = var.location
  resource_group_name = local.resource_group_name # Changed from var.
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = [local.subnet_id] # Changed from var.

  container {
    name   = var.container_name
    image  = var.container_image
    cpu    = var.cpu_cores
    memory = var.memory_gb

    ports {
      port     = 80
      protocol = "TCP"
    }


  }

  #--------------------------------------------------------------
  # Observability - Send logs to Log Analytics
  #--------------------------------------------------------------
  diagnostics {
    log_analytics {
      workspace_id  = data.azurerm_log_analytics_workspace.platform.workspace_id
      workspace_key = data.azurerm_log_analytics_workspace.platform.primary_shared_key
    }
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
    Project     = "azure-learning-lab"
  }


}
