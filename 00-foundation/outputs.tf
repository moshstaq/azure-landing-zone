# outputs.tf

output "summary" {
  value = <<-EOT

  =====================================================
  FOUNDATION DEPLOYED!
  =====================================================

  Management Groups:
  - ${azurerm_management_group.root.display_name}
  - ${azurerm_management_group.platform.display_name}
  - ${azurerm_management_group.workloads.display_name}

  Resource Groups (Permanent):
  - ${azurerm_resource_group.platform_core.name}
  - ${azurerm_resource_group.platform_network.name}
  - ${azurerm_resource_group.tfstate.name}

  Resource Groups (Labs):
  %{for name, rg in azurerm_resource_group.labs~}
  - ${rg.name}
  %{endfor~}

  Hub Network: ${azurerm_virtual_network.hub.name}
  Address Space: ${join(", ", azurerm_virtual_network.hub.address_space)}

  Terraform State Storage: ${azurerm_storage_account.tfstate.name}

  
  EOT
}

output "storage_account_name" {
  value       = azurerm_storage_account.tfstate.name
  description = "Storage account for Terraform state"
}

output "hub_vnet_id" {
  value       = azurerm_virtual_network.hub.id
  description = "Hub VNet resource ID"
}

output "lab_resource_groups" {
  value       = { for k, v in azurerm_resource_group.labs : k => v.name }
  description = "Lab resource group names"
}
