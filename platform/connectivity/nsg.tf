# ── Workloads Spoke NSGs ──────────────────────────────────────────────────────

resource "azurerm_network_security_group" "containers" {
  name                = "nsg-containers"
  location            = var.location
  resource_group_name = azurerm_resource_group.workloads.name

  tags = {
    environment = "workloads"
    purpose     = "containers-subnet-security"
    managed_by  = "terraform"
  }
}

resource "azurerm_subnet_network_security_group_association" "containers" {
  subnet_id                 = azurerm_subnet.containers.id
  network_security_group_id = azurerm_network_security_group.containers.id
}

resource "azurerm_network_security_group" "aks" {
  name                = "nsg-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.workloads.name

  tags = {
    environment = "workloads"
    purpose     = "aks-subnet-security"
    managed_by  = "terraform"
  }
}

resource "azurerm_subnet_network_security_group_association" "aks" {
  subnet_id                 = azurerm_subnet.aks.id
  network_security_group_id = azurerm_network_security_group.aks.id
}

# Allow inbound from hub only — internet blocked by default deny
resource "azurerm_network_security_rule" "allow_hub_inbound_aks" {
  name                        = "Allow-Hub-Inbound"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_address_prefix       = "10.0.0.0/16"
  destination_address_prefix  = "*"
  destination_port_range      = "*"
  source_port_range           = "*"
  resource_group_name         = azurerm_resource_group.workloads.name
  network_security_group_name = azurerm_network_security_group.aks.name
}

