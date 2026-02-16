# Container Apps Environment - shared boundary for apps
resource "azurerm_container_app_environment" "this" {
  name                       = "cae-app-dev"
  location                   = data.terraform_remote_state.networking.outputs.location
  resource_group_name        = data.terraform_remote_state.networking.outputs.resource_group_name
  log_analytics_workspace_id = data.azurerm_log_analytics_workspace.platform.id

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}

# Container App - simple hello world
resource "azurerm_container_app" "hello" {
  name                         = "ca-hello"
  container_app_environment_id = azurerm_container_app_environment.this.id
  resource_group_name          = data.terraform_remote_state.networking.outputs.resource_group_name
  revision_mode                = "Single"

  template {
    min_replicas = 0
    max_replicas = 2

    container {
      name   = "hello"
      image  = "mcr.microsoft.com/azuredocs/containerapps-helloworld:latest"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
