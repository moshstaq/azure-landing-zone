#--------------------------------------------------------------
# Storage Account Network Rules
# Applied AFTER container creation to avoid chicken-and-egg problem
#--------------------------------------------------------------

resource "azurerm_storage_account_network_rules" "main" {
  storage_account_id = azurerm_storage_account.main.id

  default_action = "Deny"
  bypass         = ["AzureServices"]

  # This ensures the container is created BEFORE firewall locks down
  depends_on = [azurerm_storage_container.uploads]
}
