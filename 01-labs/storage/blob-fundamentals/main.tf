data "azurerm_resource_group" "project" {
  name = "rg-moshstaq-lab-project"
}

data "azurerm_client_config" "current" {}

resource "random_string" "storage_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_storage_account" "lab" {
  name                     = "stmoshstaqlab${random_string.storage_suffix.result}"
  resource_group_name      = data.azurerm_resource_group.project.name
  location                 = data.azurerm_resource_group.project.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  # Security defaults (we'll configure firewall in Lab 5.3)
  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false # No anonymous access

  # Enable blob versioning for data protection
  blob_properties {
    versioning_enabled = true

    # Soft delete protects against accidental deletion
    delete_retention_policy {
      days = 7
    }

    container_delete_retention_policy {
      days = 7
    }
  }

  tags = {
    Environment = "Lab"
    Project     = "azure-learning"
    Lab         = "5.1-storage-fundamentals"
  }
}

resource "azurerm_role_assignment" "user_blob_contributor" {
  scope                = azurerm_storage_account.lab.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}


# Container for blobs
resource "azurerm_storage_container" "hot_data" {
  name                  = "hot-data"
  storage_account_name  = azurerm_storage_account.lab.name
  container_access_type = "private" # No anonymous access
}

# Container for Cool tier data
resource "azurerm_storage_container" "cool_data" {
  name                  = "cool-data"
  storage_account_name  = azurerm_storage_account.lab.name
  container_access_type = "private"
}

# Container for Archive tier data
resource "azurerm_storage_container" "archive_data" {
  name                  = "archive-data"
  storage_account_name  = azurerm_storage_account.lab.name
  container_access_type = "private"
}

# Upload a sample blob to demonstrate tiers
resource "azurerm_storage_blob" "sample_hot" {
  name                   = "sample-hot-data.txt"
  storage_account_name   = azurerm_storage_account.lab.name
  storage_container_name = azurerm_storage_container.hot_data.name
  type                   = "Block"
  source_content         = "This is sample data in the Hot tier - frequently accessed."
  access_tier            = "Hot"
}

resource "azurerm_storage_blob" "sample_cool" {
  name                   = "sample-cool-data.txt"
  storage_account_name   = azurerm_storage_account.lab.name
  storage_container_name = azurerm_storage_container.cool_data.name
  type                   = "Block"
  source_content         = "This is sample data in the Cool tier - infrequently accessed."
  access_tier            = "Cool"
}

# Note: Archive tier blobs cannot be read directly - must rehydrate first
resource "azurerm_storage_blob" "sample_archive" {
  name                   = "sample-archive-data.txt"
  storage_account_name   = azurerm_storage_account.lab.name
  storage_container_name = azurerm_storage_container.archive_data.name
  type                   = "Block"
  source_content         = "This is sample data in the Archive tier - rarely accessed, compliance/backup."
  access_tier            = "Archive"
}
