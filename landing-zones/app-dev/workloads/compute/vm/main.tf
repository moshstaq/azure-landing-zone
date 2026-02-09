
#--------------------------------------------------------------
# Network Interface
#--------------------------------------------------------------
resource "azurerm_network_interface" "vm" {
  name                = "nic-${var.vm_name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = data.azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"

  }

  tags = {
    Environment = var.environment
  }
}

#--------------------------------------------------------------
# Linux Virtual Machine
#--------------------------------------------------------------
resource "azurerm_linux_virtual_machine" "main" {
  name                = var.vm_name
  resource_group_name = var.resource_group_name
  location            = var.location
  size                = var.vm_size
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.vm.id
  ]

  # System-assigned Managed Identity 
  identity {
    type = "SystemAssigned"
  }

  # SSH Key authentication (no passwords!)
  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  # Disable password authentication entirely
  disable_password_authentication = true

  # OS Disk configuration
  os_disk {
    name                 = "osdisk-${var.vm_name}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  # Ubuntu 22.04 LTS image
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

#--------------------------------------------------------------
# RBAC: Grant your user SSH access via Entra ID
#--------------------------------------------------------------
resource "azurerm_role_assignment" "vm_admin_login" {
  scope                = azurerm_linux_virtual_machine.main.id
  role_definition_name = "Virtual Machine Administrator Login"
  principal_id         = data.azurerm_client_config.current.object_id
}

#--------------------------------------------------------------
# RBAC: Grant VM's Managed Identity permission to send metrics
# (Needed for Azure Monitor Agent in Phase 2)
#------------------------------------------------------------
resource "azurerm_role_assignment" "vm_monitoring" {
  scope                = data.azurerm_log_analytics_workspace.platform.id
  role_definition_name = "Monitoring Metrics Publisher"
  principal_id         = azurerm_linux_virtual_machine.main.identity[0].principal_id
}


#--------------------------------------------------------------
# Azure Monitor Agent Extension
#--------------------------------------------------------------
resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.main.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.24"
  automatic_upgrade_enabled  = true
  auto_upgrade_minor_version = true

  tags = {
    Environment = var.environment
  }
}


#--------------------------------------------------------------
# Data Collection Rule - Defines WHAT to collect
#--------------------------------------------------------------
resource "azurerm_monitor_data_collection_rule" "vm" {
  name                = "dcr-${var.vm_name}"
  resource_group_name = var.resource_group_name
  location            = var.location

  destinations {
    log_analytics {
      workspace_resource_id = data.azurerm_log_analytics_workspace.platform.id
      name                  = "law-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["law-destination"]
  }

  data_flow {
    streams      = ["Microsoft-Perf"]
    destinations = ["law-destination"]
  }

  # Collect Linux Syslog
  data_sources {
    syslog {
      facility_names = [
        "auth",     # Authentication logs (SSH attempts!)
        "authpriv", # Private auth messages
        "daemon",   # System daemons
        "syslog"    # General system logs
      ]
      log_levels = [
        "Warning",
        "Error",
        "Critical",
        "Alert",
        "Emergency",
        "Info"
      ]
      name    = "syslog-datasource"
      streams = ["Microsoft-Syslog"]
    }

    # Collect Performance counters
    performance_counter {
      name                          = "perf-datasource"
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "Processor(*)\\% Processor Time", # CPU usage
        "Memory(*)\\% Used Memory",       # Memory usage
        "LogicalDisk(*)\\% Free Space"    # Disk space
      ]
    }
  }

  tags = {
    Environment = var.environment
  }
}

#--------------------------------------------------------------
# Associate DCR with VM - Links the rule TO the VM
#--------------------------------------------------------------
resource "azurerm_monitor_data_collection_rule_association" "vm" {
  name                    = "dcra-${var.vm_name}"
  target_resource_id      = azurerm_linux_virtual_machine.main.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vm.id
}
