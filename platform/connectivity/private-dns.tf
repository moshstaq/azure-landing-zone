# EPHEMERAL — remove after taskflow-platform validation
resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.connectivity.name

  tags = {
    environment = "platform"
    managed-by  = "terraform"
    ephemeral   = "true"
  }
}

# EPHEMERAL — remove after taskflow-platform validation
resource "azurerm_private_dns_zone_virtual_network_link" "kv_workloads" {
  name                  = "link-kv-vnet-workloads"
  resource_group_name   = azurerm_resource_group.connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id    = azurerm_virtual_network.workloads.id
  registration_enabled  = false
}
