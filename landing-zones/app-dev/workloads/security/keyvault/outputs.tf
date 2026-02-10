output "keyvault_id" {
  description = "ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "keyvault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "keyvault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "private_endpoint_ip" {
  description = "Private IP address of the Key Vault endpoint"
  value       = azurerm_private_endpoint.keyvault.private_service_connection[0].private_ip_address
}

output "private_dns_zone_name" {
  description = "Name of the Private DNS Zone"
  value       = azurerm_private_dns_zone.keyvault.name
}

output "test_secret_name" {
  description = "Name of the test secret"
  value       = azurerm_key_vault_secret.test.name
}
