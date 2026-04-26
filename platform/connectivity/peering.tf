# ── Hub ↔ Workloads ───────────────────────────────────────────────────────────

resource "azurerm_virtual_network_peering" "hub_to_workloads" {
  name                         = "peer-hub-to-workloads"
  resource_group_name          = azurerm_resource_group.connectivity.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.workloads.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "workloads_to_hub" {
  name                         = "peer-workloads-to-hub"
  resource_group_name          = azurerm_resource_group.workloads.name
  virtual_network_name         = azurerm_virtual_network.workloads.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

# ── Hub ↔ Data ────────────────────────────────────────────────────────────────

resource "azurerm_virtual_network_peering" "hub_to_data" {
  name                         = "peer-hub-to-data"
  resource_group_name          = azurerm_resource_group.connectivity.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.data.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}

resource "azurerm_virtual_network_peering" "data_to_hub" {
  name                         = "peer-data-to-hub"
  resource_group_name          = azurerm_resource_group.data.name
  virtual_network_name         = azurerm_virtual_network.data.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
  allow_gateway_transit        = false
  use_remote_gateways          = false
}
