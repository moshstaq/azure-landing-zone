#--------------------------------------------------------------
# Outputs
#--------------------------------------------------------------

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "primary_blob_endpoint" {
  description = "Primary blob endpoint URL"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "container_name" {
  description = "Name of the blob container"
  value       = azurerm_storage_container.uploads.name
}

output "private_endpoint_ip" {
  description = "Private IP address of the blob Private Endpoint"
  value       = azurerm_private_endpoint.blob.private_service_connection[0].private_ip_address
}

output "private_dns_zone_name" {
  description = "Name of the Private DNS zone"
  value       = azurerm_private_dns_zone.blob.name
}
