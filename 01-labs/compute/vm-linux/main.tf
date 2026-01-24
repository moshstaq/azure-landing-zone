
# ============================================================================
# DATA SOURCES - Reference your foundation
# ============================================================================

data "azurerm_resource_group" "lab" {
  name = "rg-${var.prefix}-lab-compute"
}

# ============================================================================
# SSH KEY
# ============================================================================

resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


resource "azurerm_linux_virtual_machine" "lab" {
  name                = "vm-${var.prefix}-linux"
  resource_group_name = data.azurerm_resource_group.lab.name
  location            = var.location
  size                = "Standard_B1s" # FREE TIER!
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh.public_key_openssh
  }

  os_disk {
    name                 = "osdisk-${var.prefix}-linux"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Environment  = "learning"
    Lab          = "compute"
    AutoShutdown = "true"
  }
}

# ============================================================================
# AUTO-SHUTDOWN (Saves Money!)
# ============================================================================

resource "azurerm_dev_test_global_vm_shutdown_schedule" "lab" {
  virtual_machine_id = azurerm_linux_virtual_machine.lab.id
  location           = var.location
  enabled            = true

  daily_recurrence_time = "1900" # 7 PM
  timezone              = "Eastern Standard Time"

  notification_settings {
    enabled = false
  }

  tags = {
    Environment = "learning"
  }
}
