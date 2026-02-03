
# Reference existing storage account from Lab 5.1
data "azurerm_storage_account" "lab" {
  name                = var.storage_account_name
  resource_group_name = "rg-moshstaq-lab-project"
}

# Reference existing VM's managed identity for Entra ID access
data "azurerm_virtual_machine" "dev" {
  name                = "vm-dev-001"
  resource_group_name = "rg-moshstaq-lab-compute"
}


# Grant VM's Managed Identity access to storage (Entra ID method)
resource "azurerm_role_assignment" "vm_storage_blob_reader" {
  scope                = data.azurerm_storage_account.lab.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = data.azurerm_virtual_machine.dev.identity[0].principal_id
}

# Also grant Contributor for write operations (separate role)
resource "azurerm_role_assignment" "vm_storage_blob_contributor" {
  scope                = data.azurerm_storage_account.lab.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = data.azurerm_virtual_machine.dev.identity[0].principal_id
}

# Container for upload testing
resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_name  = data.azurerm_storage_account.lab.name
  container_access_type = "private"
}
