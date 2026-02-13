# -----------------------------------------------------
# RBAC: Contributor on app-dev resource group
# -----------------------------------------------------
resource "azurerm_role_assignment" "app_dev_contributor" {
  scope                = data.azurerm_resource_group.app_dev.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# -----------------------------------------------------
# RBAC: Access to Terraform state storage
# -----------------------------------------------------
resource "azurerm_role_assignment" "tfstate_blob_contributor" {
  scope                = data.azurerm_resource_group.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}
