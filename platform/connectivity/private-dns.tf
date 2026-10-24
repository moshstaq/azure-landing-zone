# ── Private DNS ───────────────────────────────────────────────────────────────
# Platform-owned zone for Key Vault private endpoints, shared by all workloads.
# Workloads join it with a private_dns_zone_group on their own endpoints; they
# do not write records into it directly.
resource "azurerm_private_dns_zone" "kv" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.connectivity.name

  tags = {
    environment = "workloads"
    purpose     = "taskflow-platform"
    managed_by  = "terraform"
  }
}

# Without this link, the zone holds records but resolves nothing for pods
# in vnet-workloads.
resource "azurerm_private_dns_zone_virtual_network_link" "kv_workloads" {
  name                  = "link-kv-workloads"
  resource_group_name   = azurerm_resource_group.connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.kv.name
  virtual_network_id    = azurerm_virtual_network.workloads.id
  registration_enabled  = false

  tags = {
    environment = "workloads"
    purpose     = "taskflow-platform"
    managed_by  = "terraform"
  }
}
