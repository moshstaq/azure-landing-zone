output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.vm.name
}

output "vm_id" {
  description = "ID of the virtual machine"
  value       = azurerm_linux_virtual_machine.vm.id
}

output "vm_private_ip" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.vm.private_ip_address
}

output "vm_identity_principal_id" {
  description = "Principal ID of VM managed identity (for Lab 3.2)"
  value       = azurerm_linux_virtual_machine.vm.identity[0].principal_id
}


output "admin_username" {
  description = "Admin username"
  value       = var.admin_username
}

output "ssh_command" {
  description = "SSH command (requires network access to private IP)"
  value       = "ssh -i ~/.ssh/azure-lab-vm ${var.admin_username}@${azurerm_network_interface.vm.private_ip_address}"
}


output "auto_shutdown_time" {
  description = "Auto-shutdown time (UTC)"
  value       = "${var.auto_shutdown_time} UTC daily"
}
