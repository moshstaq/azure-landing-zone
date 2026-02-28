# Generate random suffix for globally unique storage account name
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Resource group for Terraform state
resource "azurerm_resource_group" "tfstate" {
  name     = "rg-tfstate"
  location = var.location

  tags = {
    purpose    = "terraform-state"
    managed_by = "terraform-bootstrap"
  }
}

# Storage account for Terraform state
resource "azurerm_storage_account" "tfstate" {
  name                     = "sttfstate${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = azurerm_resource_group.tfstate.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security settings
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false


  blob_properties {
    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }

    versioning_enabled = true
  }



  tags = {
    environment = "platform"
    purpose     = "terraform-state"
    managed_by  = "terraform-bootstrap"
  }
}

# Container for state files
resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

resource "azurerm_management_lock" "tfstate" {
  name       = "lock-tfstate-rg"
  scope      = azurerm_resource_group.tfstate.id
  lock_level = "CanNotDelete"
  notes      = "Protects Terraform state storage from accidental deletion"
}
