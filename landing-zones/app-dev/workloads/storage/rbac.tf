#--------------------------------------------------------------
# RBAC: VM Managed Identity → Storage Blob Data Reader
#--------------------------------------------------------------

# This allows the VM to READ blobs using its Managed Identity

resource "azurerm_role_assignment" "vm_blob_reader" {
  scope = azurerm_storage_account.main.id


  role_definition_name = "Storage Blob Data Reader"


  principal_id = data.terraform_remote_state.vm.outputs.vm_identity_principal_id
}
