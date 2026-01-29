terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-moshstaq-tfstate"
    storage_account_name = "stmoshstaqtfstm0n4"
    container_name       = "tfstate"
    key                  = "cicd-platform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

# =============================================================================
# DATA SOURCES
# =============================================================================
data "azurerm_client_config" "current" {}

# =============================================================================
# RESOURCE GROUPS (CI/CD can manage these)
# =============================================================================
resource "azurerm_resource_group" "platform_core" {
  name     = "rg-${var.your_name}-platform-core"
  location = var.location

  tags = {
    Environment = "platform"
    ManagedBy   = "terraform-cicd"
    Project     = "azure-learning"
  }
}

resource "azurerm_resource_group" "platform_networking" {
  name     = "rg-${var.your_name}-platform-networking"
  location = var.location

  tags = {
    Environment = "platform"
    ManagedBy   = "terraform-cicd"
    Project     = "azure-learning"
  }
}

# =============================================================================
# LOG ANALYTICS WORKSPACE
# =============================================================================
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.your_name}-main"
  location            = azurerm_resource_group.platform_core.location
  resource_group_name = azurerm_resource_group.platform_core.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = "platform"
    ManagedBy   = "terraform-cicd"
  }
}

# =============================================================================
# BUDGET ALERT
# =============================================================================
resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-${var.your_name}-monthly"
  subscription_id = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"

  amount     = 20
  time_grain = "Monthly"

  time_period {
    start_date = "2026-02-01T00:00:00Z"
    end_date   = "2028-12-31T00:00:00Z"
  }

  notification {
    enabled   = true
    threshold = 80.0
    operator  = "GreaterThan"

    contact_emails = [var.alert_email]
  }

  notification {
    enabled   = true
    threshold = 100.0
    operator  = "GreaterThan"

    contact_emails = [var.alert_email]
  }
}
