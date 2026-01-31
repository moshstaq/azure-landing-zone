#--------------------------------------------------------------
# Network Interface
#--------------------------------------------------------------
resource "azurerm_network_interface" "vm" {
  name                = "nic-${var.environment}-vm"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.labs.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"

  }

  tags = var.tags
}


#--------------------------------------------------------------
# Linux Virtual Machine
#--------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "vm" {
  name                = "vm-${var.environment}-001"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.labs.name
  size                = var.vm_size
  admin_username      = var.admin_username
  network_interface_ids = [
    azurerm_network_interface.vm.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = trimspace(data.local_file.ssh_public_key.content)
  }

  os_disk {
    name                 = "osdisk-vm-${var.environment}-001"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  boot_diagnostics {

  }

  identity {
    type = "SystemAssigned"
  }

  computer_name                   = "vm-${var.environment}-001"
  disable_password_authentication = true

  tags = var.tags
}

#--------------------------------------------------------------
# Auto-Shutdown Schedule (Cost Control)
#--------------------------------------------------------------

resource "azurerm_dev_test_global_vm_shutdown_schedule" "vm" {
  virtual_machine_id    = azurerm_linux_virtual_machine.vm.id
  location              = var.location
  enabled               = true
  daily_recurrence_time = var.auto_shutdown_time
  timezone              = "UTC"

  notification_settings {
    enabled = false
  }

  tags = var.tags
}

#--------------------------------------------------------------
# Log Analytics VM Extension (Azure Monitor Agent)
#--------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.28"
  auto_upgrade_minor_version = true
  automatic_upgrade_enabled  = true


  tags = var.tags
}

#--------------------------------------------------------------
# Data Collection Rule (connects VM to Log Analytics)
#--------------------------------------------------------------
resource "azurerm_monitor_data_collection_rule" "vm" {
  name                = "dcr-vm-${var.environment}-001"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.labs.name

  destinations {
    log_analytics {
      workspace_resource_id = data.azurerm_log_analytics_workspace.main.id
      name                  = "log-analystics-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog", "Microsoft-Perf"]
    destinations = ["log-analystics-destination"]
  }

  data_sources {
    syslog {
      facility_names = [
        "auth",
        "authpriv",
        "daemon",
        "kern",
        "syslog",
        "user"
      ]
      log_levels = [
        "Alert",
        "Critical",
        "Emergency",
        "Error",
        "Warning"
      ]
      name    = "syslog-datasource"
      streams = ["Microsoft-Syslog"]
    }

    performance_counter {
      counter_specifiers = [
        "Processor(*)\\% Processor Time",
        "Memory(*)\\% Used Memory",
        "LogicalDisk(*)\\% Free Space"
      ]
      name                          = "perf-datasource"
      sampling_frequency_in_seconds = 60
      streams                       = ["Microsoft-Perf"]
    }
  }

  tags = var.tags
}


#--------------------------------------------------------------
# Link Data Collection Rule to VM
#--------------------------------------------------------------
resource "azurerm_monitor_data_collection_rule_association" "vm" {
  name                    = "dcr-vm-${var.environment}"
  target_resource_id      = azurerm_linux_virtual_machine.vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm.id
}
