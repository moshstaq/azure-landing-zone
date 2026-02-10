#--------------------------------------------------------------
# Random suffix for globally unique Key Vault name
#--------------------------------------------------------------
resource "random_string" "kv_suffix" {
  length  = 6
  special = false
  upper   = false
}

#--------------------------------------------------------------
# Key Vault
#--------------------------------------------------------------
resource "azurerm_key_vault" "main" {
  name                = "${var.keyvault_name_prefix}-${random_string.kv_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.keyvault_sku


  enable_rbac_authorization = true

  # Soft delete settings (required by Azure)
  soft_delete_retention_days = 7
  purge_protection_enabled   = false # False for learning (allows full cleanup)

  # CRITICAL: Disable public access - only Private Endpoint allowed
  public_network_access_enabled = false


  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = [var.deployment_ip] # Allow Terraform IP for deployment, but no other public access
  }

  tags = {
    Environment = var.environment
  }
}


resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

#--------------------------------------------------------------
# Test Secret (to verify access works)
#--------------------------------------------------------------
resource "azurerm_key_vault_secret" "test" {
  name         = "test-secret"
  value        = "Hello-from-Week9-KeyVault"
  key_vault_id = azurerm_key_vault.main.id

  # Must wait for RBAC to propagate
  depends_on = [azurerm_role_assignment.kv_admin]

  tags = {
    Environment = var.environment
    Purpose     = "testing"
  }
}

#--------------------------------------------------------------
# Private Endpoint for Key Vault
#--------------------------------------------------------------
resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-${azurerm_key_vault.main.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.data.id

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }

  tags = {
    Environment = var.environment
  }
}

#--------------------------------------------------------------
# Private DNS Zone for Key Vault
#--------------------------------------------------------------
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name

  tags = {
    Environment = var.environment
  }
}

#--------------------------------------------------------------
# Link Private DNS Zone to VNet
#--------------------------------------------------------------
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "link-vnet-app-dev"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = data.azurerm_virtual_network.app_dev.id
  registration_enabled  = false # Only for private endpoint resolution

  tags = {
    Environment = var.environment
  }
}
