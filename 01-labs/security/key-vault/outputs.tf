output "resource_group_name" {
  description = "Name of the security resource group"
  value       = azurerm_resource_group.security.name
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_id" {
  description = "Resource ID of the Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "secret_names" {
  description = "Names of created secrets"
  value = [
    azurerm_key_vault_secret.db_connection.name,
    azurerm_key_vault_secret.api_key.name
  ]
}

output "rbac_assignments" {
  description = "RBAC role assignments on Key Vault"
  value = {
    admin_principal = data.azurerm_client_config.current.object_id
    admin_role      = "Key Vault Administrator"
    vm_principal    = var.vm_principal_id
    vm_role         = "Key Vault Secrets User"
  }
}

# Useful for testing - shows how to construct secret URI
output "secret_uri_example" {
  description = "Example of how to reference a secret"
  value       = "${azurerm_key_vault.main.vault_uri}secrets/${azurerm_key_vault_secret.db_connection.name}"
}

#----------------------------------------------------------------------
# Private Endpoint Outputs
#----------------------------------------------------------------------

output "private_endpoint_name" {
  description = "Name of the Private Endpoint"
  value       = azurerm_private_endpoint.keyvault.name
}

output "private_endpoint_ip" {
  description = "Private IP address of the Private Endpoint"
  value       = azurerm_private_endpoint.keyvault.private_service_connection[0].private_ip_address
}

output "private_dns_zone_name" {
  description = "Name of the Private DNS Zone"
  value       = azurerm_private_dns_zone.keyvault.name
}

output "dns_zone_links" {
  description = "VNets linked to the Private DNS Zone"
  value = [
    azurerm_private_dns_zone_virtual_network_link.keyvault_spoke.name,
    azurerm_private_dns_zone_virtual_network_link.keyvault_hub.name
  ]
}

output "key_vault_public_access" {
  description = "Public network access status"
  value       = azurerm_key_vault.main.public_network_access_enabled
}
