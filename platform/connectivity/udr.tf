# ── Workloads Spoke UDR ───────────────────────────────────────────────────────
# Forces traffic from workload subnet to data spoke through NVA
# Overrides the default system route Azure creates for vnet-data peering

resource "azurerm_route_table" "workload" {
  name                = "rt-workload"
  location            = var.location
  resource_group_name = azurerm_resource_group.workloads.name


  route {
    name                   = "route-to-data"
    address_prefix         = "10.2.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.nva_private_ip
  }

  tags = {
    environment = "workloads"
    purpose     = "workload-spoke-routing"
    managed_by  = "terraform"
  }
}

resource "azurerm_subnet_route_table_association" "compute" {
  subnet_id      = azurerm_subnet.workload_compute.id
  route_table_id = azurerm_route_table.workload.id
}

# ── Data Spoke UDR ────────────────────────────────────────────────────────────
# Return path — forces responses from data subnet back through NVA
# Prevents asymmetric routing that would break TCP sessions

resource "azurerm_route_table" "data" {
  name                = "rt-data"
  location            = var.location
  resource_group_name = azurerm_resource_group.data.name


  route {
    name                   = "route-to-workloads"
    address_prefix         = "10.1.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.nva_private_ip
  }

  tags = {
    environment = "platform"
    purpose     = "data-spoke-routing"
    managed_by  = "terraform"
  }
}

