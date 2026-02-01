data "azurerm_client_config" "current" {}


resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  upper   = false
}

resource "azurerm_resource_group" "security" {
  name     = "rg-moshstaq-lab-security"
  location = var.location

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
    Lab         = "4.1-keyvault"
  }
}

resource "azurerm_key_vault" "main" {
  name                = "kv-${var.project}-${random_string.kv_suffix.result}"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  tenant_id           = data.azurerm_client_config.current.tenant_id

  # SKU: standard (software-protected) vs premium (HSM-backed)
  sku_name = "standard"

  # RBAC Authorization (not access policies!)
  enable_rbac_authorization = true

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  public_network_access_enabled = false # Disable public access

  # Soft delete protection
  soft_delete_retention_days = var.soft_delete_retention_days
  purge_protection_enabled   = false # Set true in production!

  # Network rules (default: allow all - we'll lock down in Lab 4.2)
  # network_acls will be configured with Private Endpoints

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
    Lab         = "4.1-keyvault"
  }
}


#----------------------------------------------------------------------
# RBAC Role Assignments
#----------------------------------------------------------------------


resource "azurerm_role_assignment" "kv_admin_current" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id


}


resource "azurerm_role_assignment" "kv_secrets_user_vm" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.vm_principal_id

  # Depends on admin assignment being in place first
  depends_on = [azurerm_role_assignment.kv_admin_current]
}


#----------------------------------------------------------------------
# Sample Secrets
#----------------------------------------------------------------------

# Example: Database connection string (simulated)
resource "azurerm_key_vault_secret" "db_connection" {
  name         = "db-connection-string"
  value        = "Server=sql-server.database.windows.net;Database=appdb;Authentication=Managed Identity"
  key_vault_id = azurerm_key_vault.main.id

  # Wait for RBAC to propagate
  depends_on = [azurerm_role_assignment.kv_admin_current]

  tags = {
    Purpose = "Database connection"
    Lab     = "4.1-keyvault"
  }
}

resource "azurerm_key_vault_secret" "api_key" {
  name         = "external-api-key"
  value        = "sk_live_example_${random_string.kv_suffix.result}_notreal"
  key_vault_id = azurerm_key_vault.main.id

  # Content type helps identify what the secret is
  content_type = "API Key"

  # Expiration date (optional but recommended)
  expiration_date = timeadd(timestamp(), "8760h") # 1 year from now

  depends_on = [azurerm_role_assignment.kv_admin_current]

  tags = {
    Purpose = "External API authentication"
    Lab     = "4.1-keyvault"
  }

  lifecycle {
    ignore_changes = [expiration_date] # Don't update on every apply
  }
}
