locals {
  resource_group_name = "rg-app-dev"
}

# ─────────────────────────────────────────────────────
# Key Vault
# ─────────────────────────────────────────────────────
resource "azurerm_key_vault" "workload" {
  name                = "kv-aks-appdev"
  location            = local.location
  resource_group_name = local.resource_group_name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Workload identity uses RBAC not access policies
  enable_rbac_authorization = true

  # Soft delete required by Azure
  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# Real secret — replaces the dummy Kubernetes Secret from Week 15
resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = "real-secret-managed-by-keyvault"
  key_vault_id = azurerm_key_vault.workload.id

  depends_on = [
    azurerm_role_assignment.terraform_kv_admin
  ]
}

# ─────────────────────────────────────────────────────
# Managed Identity — one per workload, least privilege
# ─────────────────────────────────────────────────────
resource "azurerm_user_assigned_identity" "workload" {
  name                = "mi-aks-nginx-demo"
  location            = local.location
  resource_group_name = local.resource_group_name

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# ─────────────────────────────────────────────────────
# RBAC — managed identity can read secrets from Key Vault
# ─────────────────────────────────────────────────────
resource "azurerm_role_assignment" "workload_kv_reader" {
  scope                = azurerm_key_vault.workload.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}

# Terraform needs admin access to create the secret
resource "azurerm_role_assignment" "terraform_kv_admin" {
  scope                = azurerm_key_vault.workload.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# ─────────────────────────────────────────────────────
# Federated credential — links managed identity to
# Kubernetes service account in the cluster
# ─────────────────────────────────────────────────────
resource "azurerm_federated_identity_credential" "workload" {
  name                = "fed-aks-nginx-demo"
  resource_group_name = local.resource_group_name
  parent_id           = azurerm_user_assigned_identity.workload.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.this.oidc_issuer_url
  subject             = "system:serviceaccount:default:nginx-demo-sa"
}

