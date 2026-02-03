output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.lab.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.lab.id
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.lab.primary_blob_endpoint
}

output "containers" {
  description = "Storage containers created"
  value = {
    hot     = azurerm_storage_container.hot_data.name
    cool    = azurerm_storage_container.cool_data.name
    archive = azurerm_storage_container.archive_data.name
  }
}
output "sample_blobs" {
  description = "Sample blobs created in different access tiers"
  value = {
    hot     = azurerm_storage_blob.sample_hot.name
    cool    = azurerm_storage_blob.sample_cool.name
    archive = azurerm_storage_blob.sample_archive.name
  }
}
