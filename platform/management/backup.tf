
# ─────────────────────────────────────────────────────
# Recovery Services Vault
# Central backup vault for the platform
# Demonstrates enterprise backup pattern
# ─────────────────────────────────────────────────────
resource "azurerm_recovery_services_vault" "platform" {
  name                = "rsv-platform"
  location            = azurerm_resource_group.management.location
  resource_group_name = azurerm_resource_group.management.name
  sku                 = "Standard"


  # Immutability — prevents backup data modification
  immutability      = "Disabled"
  storage_mode_type = "LocallyRedundant"

  tags = {
    environment = "platform"
    managed_by  = "terraform"
  }
}

# ─────────────────────────────────────────────────────
# Backup Policy — Virtual Machines
# Defines when backups run and how long they're kept
# ─────────────────────────────────────────────────────
resource "azurerm_backup_policy_vm" "daily" {
  name                = "bkpol-vm-daily"
  resource_group_name = azurerm_resource_group.management.name
  recovery_vault_name = azurerm_recovery_services_vault.platform.name

  # Timezone for backup schedule
  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "02:00" # 2AM UTC — low activity window
  }

  retention_daily {
    count = 7 # Keep 7 daily restore points
  }

  retention_weekly {
    count    = 4 # Keep 4 weekly restore points
    weekdays = ["Sunday"]
  }

  retention_monthly {
    count    = 3 # Keep 3 monthly restore points
    weekdays = ["Sunday"]
    weeks    = ["First"]
  }
}
