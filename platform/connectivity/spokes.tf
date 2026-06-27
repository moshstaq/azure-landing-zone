# ── Workloads Spoke ───────────────────────────────────────────────────────────
locals {
  common_tags = {
    environment = "workloads"
    purpose     = "workload-spoke"
    managed_by  = "terraform"
  }
}


resource "azurerm_resource_group" "workloads" {
  name     = "rg-workloads"
  location = var.location

  tags = local.common_tags
}

resource "azurerm_virtual_network" "workloads" {
  name                = "vnet-workloads"
  location            = var.location
  resource_group_name = azurerm_resource_group.workloads.name
  address_space       = ["10.1.0.0/16"]

  tags = local.common_tags
}

resource "azurerm_subnet" "workload_compute" {
  name                 = "snet-compute"
  resource_group_name  = azurerm_resource_group.workloads.name
  virtual_network_name = azurerm_virtual_network.workloads.name
  address_prefixes     = ["10.1.1.0/24"]
}



resource "azurerm_subnet" "containers" {
  name                 = "snet-containers"
  resource_group_name  = azurerm_resource_group.workloads.name
  virtual_network_name = azurerm_virtual_network.workloads.name
  address_prefixes     = ["10.1.3.0/24"]

  delegation {
    name = "aci-delegation"
    service_delegation {
      name    = "Microsoft.ContainerInstance/containerGroups"
      actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
    }
  }
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  resource_group_name  = azurerm_resource_group.workloads.name
  virtual_network_name = azurerm_virtual_network.workloads.name
  address_prefixes     = ["10.1.4.0/22"]
}

# ── Data Spoke ────────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "data" {
  name     = "rg-data"
  location = var.location

  tags = local.common_tags
}

resource "azurerm_virtual_network" "data" {
  name                = "vnet-data"
  location            = var.location
  resource_group_name = azurerm_resource_group.data.name
  address_space       = ["10.2.0.0/16"]

  tags = local.common_tags
}

resource "azurerm_subnet" "data_services" {
  name                 = "snet-data-services"
  resource_group_name  = azurerm_resource_group.data.name
  virtual_network_name = azurerm_virtual_network.data.name
  address_prefixes     = ["10.2.0.0/24"]
}



# ── Taskflow Workload Landing Zone ───────────────────────────────────────────

resource "azurerm_resource_group" "taskflow" {
  name     = "rg-taskflow"
  location = var.location

  tags = {
    environment = "workloads"
    purpose     = "taskflow-platform"
    managed_by  = "terraform"
  }
}


