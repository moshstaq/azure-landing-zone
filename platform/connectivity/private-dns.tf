# ─────────────────────────────────────────────────────
# Centralised Private DNS Zones — Hub
#
# DNS zones live in the hub and are linked to all spokes.
# New spokes inherit DNS resolution automatically via
# VNet peering — no per-spoke DNS zone management needed.
#
# Pattern: one zone per PaaS service type
# ─────────────────────────────────────────────────────

# Remote state — spoke VNets to link
data "terraform_remote_state" "app_dev_networking" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "sttfstate7tcl"
    container_name       = "tfstate"
    key                  = "landing-zone-app-dev-networking.tfstate"
  }
}

locals {
  spoke_vnet_ids = {
    app_dev = data.terraform_remote_state.app_dev_networking.outputs.vnet_app_dev_id
  }
}

# ─────────────────────────────────────────────────────
# Private DNS Zones
# ─────────────────────────────────────────────────────

# Blob Storage
resource "azurerm_private_dns_zone" "blob" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.connectivity.name

  tags = {
    environment = "platform"
    managed_by  = "terraform"
    purpose     = "private-dns"
  }
}

# Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.connectivity.name

  tags = {
    environment = "platform"
    managed_by  = "terraform"
    purpose     = "private-dns"
  }
}

# Azure Container Registry
resource "azurerm_private_dns_zone" "acr" {
  name                = "privatelink.azurecr.io"
  resource_group_name = azurerm_resource_group.connectivity.name

  tags = {
    environment = "platform"
    managed_by  = "terraform"
    purpose     = "private-dns"
  }
}

# AKS API server
resource "azurerm_private_dns_zone" "aks" {
  name                = "privatelink.eastus2.azmk8s.io"
  resource_group_name = azurerm_resource_group.connectivity.name

  tags = {
    environment = "platform"
    managed_by  = "terraform"
    purpose     = "private-dns"
  }
}

# ─────────────────────────────────────────────────────
# VNet Links — hub VNet
# Hub must be linked first so hub resources can resolve
# ─────────────────────────────────────────────────────

resource "azurerm_private_dns_zone_virtual_network_link" "blob_hub" {
  name                  = "link-vnet-hub-blob"
  resource_group_name   = azurerm_resource_group.connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = {
    environment = "platform"
    managed_by  = "terraform"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_hub" {
  name                  = "link-vnet-hub-keyvault"
  resource_group_name   = azurerm_resource_group.connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = {
    environment = "platform"
    managed_by  = "terraform"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_hub" {
  name                  = "link-vnet-hub-acr"
  resource_group_name   = azurerm_resource_group.connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = {
    environment = "platform"
    managed_by  = "terraform"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks_hub" {
  name                  = "link-vnet-hub-aks"
  resource_group_name   = azurerm_resource_group.connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = {
    environment = "platform"
    managed_by  = "terraform"
  }
}

# ─────────────────────────────────────────────────────
# VNet Links — spoke VNets
# Each spoke linked to all hub DNS zones
# New spokes: add to spoke_vnet_ids local and re-apply
# ─────────────────────────────────────────────────────

resource "azurerm_private_dns_zone_virtual_network_link" "blob_spokes" {
  for_each = local.spoke_vnet_ids

  name                  = "link-${each.key}-blob"
  resource_group_name   = azurerm_resource_group.connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name
  virtual_network_id    = each.value
  registration_enabled  = false

  tags = {
    environment = "platform"
    managed_by  = "terraform"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_spokes" {
  for_each = local.spoke_vnet_ids

  name                  = "link-${each.key}-keyvault"
  resource_group_name   = azurerm_resource_group.connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = each.value
  registration_enabled  = false

  tags = {
    environment = "platform"
    managed_by  = "terraform"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "acr_spokes" {
  for_each = local.spoke_vnet_ids

  name                  = "link-${each.key}-acr"
  resource_group_name   = azurerm_resource_group.connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.acr.name
  virtual_network_id    = each.value
  registration_enabled  = false

  tags = {
    environment = "platform"
    managed_by  = "terraform"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "aks_spokes" {
  for_each = local.spoke_vnet_ids

  name                  = "link-${each.key}-aks"
  resource_group_name   = azurerm_resource_group.connectivity.name
  private_dns_zone_name = azurerm_private_dns_zone.aks.name
  virtual_network_id    = each.value
  registration_enabled  = false

  tags = {
    environment = "platform"
    managed_by  = "terraform"
  }
}

# ─────────────────────────────────────────────────────
# Outputs — consumed by spoke modules when registering
# DNS A records for their private endpoints
# ─────────────────────────────────────────────────────

output "private_dns_zone_blob_id" {
  description = "Private DNS zone ID for blob storage"
  value       = azurerm_private_dns_zone.blob.id
}

output "private_dns_zone_keyvault_id" {
  description = "Private DNS zone ID for Key Vault"
  value       = azurerm_private_dns_zone.keyvault.id
}

output "private_dns_zone_acr_id" {
  description = "Private DNS zone ID for ACR"
  value       = azurerm_private_dns_zone.acr.id
}

output "private_dns_zone_aks_id" {
  description = "Private DNS zone ID for AKS"
  value       = azurerm_private_dns_zone.aks.id
}

output "private_dns_zone_blob_name" {
  description = "Private DNS zone name for blob storage"
  value       = azurerm_private_dns_zone.blob.name
}

output "private_dns_zone_keyvault_name" {
  description = "Private DNS zone name for Key Vault"
  value       = azurerm_private_dns_zone.keyvault.name
}
