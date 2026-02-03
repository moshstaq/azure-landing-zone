output "private_endpoint_ip" {
  description = "Private IP address of storage private endpoint"
  value       = azurerm_private_endpoint.storage.private_service_connection[0].private_ip_address
}

output "private_dns_zone" {
  description = "Private DNS zone for blob storage"
  value       = azurerm_private_dns_zone.blob.name
}

output "lifecycle_policy_rules" {
  description = "Lifecycle management rules configured"
  value = [
    "logs-lifecycle: Hot → Cool (30d) → Archive (90d) → Delete (365d)",
    "temp-files-cleanup: Delete after 7 days"
  ]
}
