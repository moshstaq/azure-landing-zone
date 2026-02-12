#--------------------------------------------------------------
# Blob Lifecycle Management Policy
#--------------------------------------------------------------

# Automatically delete old blobs to save costs
# This is especially important for test/dev environments!

resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "delete-old-blobs"
    enabled = true

    filters {

      blob_types = ["blockBlob"]
    }

    actions {
      base_blob {

        delete_after_days_since_modification_greater_than = var.lifecycle_delete_days
      }
    }
  }
}
