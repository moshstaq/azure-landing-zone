resource "azurerm_monitor_action_group" "platform" {
  name                = "ag-platform-alerts"
  resource_group_name = azurerm_resource_group.management.name
  short_name          = "plt-alerts"

  email_receiver {
    name                    = "platform-team"
    email_address           = var.alert_email
    use_common_alert_schema = true
  }

  tags = {
    Environment = "platform"
    managed_by  = "terraform"
  }
}
