output "connection_info" {
  value = <<-EOT

  =====================================================
  🖥️  LINUX VM DEPLOYED!
  =====================================================

  VM Name:     ${azurerm_linux_virtual_machine.lab.name}
  Public IP:   ${azurerm_public_ip.vm.ip_address}
  Username:    azureuser
  Size:        Standard_B1s (FREE TIER)
  
  Auto-shutdown: 7:00 PM EST daily

  -----------------------------------------------------
  TO CONNECT:
  -----------------------------------------------------

  1. Save the SSH key:
     terraform output -raw ssh_private_key > ~/.ssh/lab-vm.pem
     chmod 600 ~/.ssh/lab-vm.pem

  2. Connect:
     ssh -i ~/.ssh/lab-vm.pem azureuser@${azurerm_public_ip.vm.ip_address}

  -----------------------------------------------------
  LEARNING EXERCISES:
  -----------------------------------------------------
  
  • Install nginx: sudo apt update && sudo apt install nginx -y
  • Check Azure VM metrics in Portal
  • Practice Azure CLI from inside the VM
  • Try stopping/starting from Portal and CLI

  -----------------------------------------------------
  CLEANUP (when done):
  -----------------------------------------------------
  
  terraform destroy

  =====================================================

  EOT
}

output "ssh_private_key" {
  value     = tls_private_key.ssh.private_key_pem
  sensitive = true
}

output "public_ip" {
  value = azurerm_public_ip.vm.ip_address
}
