# Reference existing resources
data "azurerm_storage_account" "lab" {
  name                = var.storage_account_name
  resource_group_name = "rg-moshstaq-lab-project"
}

data "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-dev"
  resource_group_name = "rg-spoke-dev"
}

data "azurerm_subnet" "data" {
  name                 = "snet-data"
  virtual_network_name = "vnet-spoke-dev"
  resource_group_name  = "rg-spoke-dev"
}


# Private DNS Zone for Storage (blob)
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = "rg-spoke-dev"

  tags = {
    Environment = "Lab"
    Project     = "azure-learning"
    Lab         = "5.3-storage-security"
  }
}

# Link DNS zone to spoke VNet
resource "azurerm_private_dns_zone_virtual_network_link" "blob_spoke" {
  name                  = "blob-spoke-link"
  resource_group_name   = "rg-spoke-dev"
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = data.azurerm_virtual_network.spoke.id
  registration_enabled  = false

  tags = {
    Environment = "Lab"
    Project     = "azure-learning"
    Lab         = "5.3-storage-security"
  }
}

# Private Endpoint for Storage Account
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-${var.storage_account_name}"
  location            = data.azurerm_storage_account.lab.location
  resource_group_name = "rg-spoke-dev"
  subnet_id           = data.azurerm_subnet.data.id

  private_service_connection {
    name                           = "psc-storage"
    private_connection_resource_id = data.azurerm_storage_account.lab.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage-dns-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.blob.id]
  }

  tags = {
    Environment = "Lab"
    Project     = "azure-learning"
    Lab         = "5.3-storage-security"
  }
}


# Lifecycle Management Policy
resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = data.azurerm_storage_account.lab.id

  rule {
    name    = "logs-lifecycle"
    enabled = true

    filters {
      prefix_match = ["hot-data/logs/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_creation_greater_than    = 30
        tier_to_archive_after_days_since_creation_greater_than = 90
        delete_after_days_since_creation_greater_than          = 365
      }
      snapshot {
        delete_after_days_since_creation_greater_than = 30
      }
      version {
        delete_after_days_since_creation = 90
      }
    }
  }

  rule {
    name    = "temp-files-cleanup"
    enabled = true

    filters {
      prefix_match = ["uploads/temp/"]
      blob_types   = ["blockBlob"]
    }

    actions {
      base_blob {
        delete_after_days_since_creation_greater_than = 7
      }
    }
  }
}


# Container for logs (to test lifecycle policy)
resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = data.azurerm_storage_account.lab.name
  container_access_type = "private"
}
