output "storage_account_name" {
  description = "Storage account name for testing"
  value       = azurerm_storage_account.lab_data.name
}

output "storage_container_name" {
  description = "Container name"
  value       = azurerm_storage_container.test_data.name
}

output "test_blob_url" {
  description = "URL of test blob (requires auth to access)"
  value       = azurerm_storage_blob.test_file.url
}

output "vm_managed_identity_principal_id" {
  description = "VM's managed identity principal ID"
  value       = data.azurerm_virtual_machine.vm.identity[0].principal_id
}

output "rbac_assignments" {
  description = "RBAC assignments created"
  value = {
    admins_contributor = {
      scope = data.azurerm_resource_group.spoke_dev.name
      role  = "Contributor"
    }
    readers_reader = {
      scope = data.azurerm_resource_group.spoke_dev.name
      role  = "Reader"
    }
    vm_blob_reader = {
      scope = azurerm_storage_account.lab_data.name
      role  = "Storage Blob Data Reader"
    }
  }
}
