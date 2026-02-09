output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.id
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.vm.private_ip_address
}



output "vm_identity_principal_id" {
  description = "Principal ID of the VM's managed identity"
  value       = azurerm_linux_virtual_machine.main.identity[0].principal_id
}


output "admin_username" {
  description = "Admin username for SSH"
  value       = var.admin_username
}

output "data_collection_rule_id" {
  description = "ID of the Data Collection Rule"
  value       = azurerm_monitor_data_collection_rule.vm.id
}

output "azure_monitor_agent_status" {
  description = "Azure Monitor Agent extension status"
  value       = "Installed - check VM extensions in portal for provisioning state"
}

output "ssh_connection_info" {
  description = "SSH connection info (requires VPN/Bastion)"
  value       = "ssh ${var.admin_username}@${azurerm_network_interface.vm.private_ip_address} (private network only)"
}
