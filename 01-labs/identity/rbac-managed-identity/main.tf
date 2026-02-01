#--------------------------------------------------------------
# RBAC Role Assignments - Groups to Resource Group
#--------------------------------------------------------------

# Lab-Admins get Contributor on spoke-dev RG
resource "azurerm_role_assignment" "lab_admins_contributor" {
  scope                = data.azurerm_resource_group.spoke_dev.id
  role_definition_name = "Contributor"
  principal_id         = var.lab_admins_group_id

  principal_type = "Group"

}

# Lab-Readers get Reader on spoke-dev RG
resource "azurerm_role_assignment" "lab_readers_reader" {
  scope                = data.azurerm_resource_group.spoke_dev.id
  role_definition_name = "Reader"
  principal_id         = var.lab_readers_group_id
  principal_type       = "Group"
}


#--------------------------------------------------------------
# Storage Account for Managed Identity Testing
#--------------------------------------------------------------

resource "azurerm_storage_account" "lab_data" {
  name                     = "stlabdata${random_string.suffix.result}"
  resource_group_name      = data.azurerm_resource_group.lab_compute.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"


  min_tls_version                 = "TLS1_2"
  allow_nested_items_to_be_public = false

  tags = {
    Environment = var.environment
    Purpose     = "managed-identity-testing"
    Lab         = "3.2"
  }
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}


resource "azurerm_storage_container" "test_data" {
  name                  = "testdata"
  storage_account_name  = azurerm_storage_account.lab_data.name
  container_access_type = "private"
}


resource "azurerm_storage_blob" "test_file" {
  name                   = "hello.txt"
  storage_account_name   = azurerm_storage_account.lab_data.name
  storage_container_name = azurerm_storage_container.test_data.name
  type                   = "Block"
  source_content         = "Hello from Managed Identity! If you can read this, RBAC works!"
}

#--------------------------------------------------------------
# Managed Identity RBAC - VM to Storage
#--------------------------------------------------------------

resource "azurerm_role_assignment" "vm_blob_reader" {
  scope                = azurerm_storage_account.lab_data.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = data.azurerm_virtual_machine.vm.identity[0].principal_id

  principal_type = "ServicePrincipal"
}
