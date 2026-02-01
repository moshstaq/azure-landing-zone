# data source

data "azurerm_virtual_network" "spoke" {
  name                = "vnet-spoke-dev"
  resource_group_name = "rg-spoke-dev"
}

data "azurerm_subnet" "app" {
  name                 = "snet-app"
  virtual_network_name = "vnet-spoke-dev"
  resource_group_name  = "rg-spoke-dev"
}

data "azurerm_virtual_network" "hub" {
  name                = "vnet-moshstaq-hub"
  resource_group_name = "rg-moshstaq-platform-network"
}

#----------------------------------------------------------------------
# Private DNS Zone for Key Vault
#----------------------------------------------------------------------
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.security.name

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
    Lab         = "4.2-private-endpoint"
  }
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_spoke" {
  name                  = "link-spoke-dev"
  resource_group_name   = azurerm_resource_group.security.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = data.azurerm_virtual_network.spoke.id
  registration_enabled  = false # Don't auto-register VM DNS records

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}


resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_hub" {
  name                  = "link-hub"
  resource_group_name   = azurerm_resource_group.security.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = data.azurerm_virtual_network.hub.id
  registration_enabled  = false

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
  }
}

#----------------------------------------------------------------------
# Private Endpoint for Key Vault
#----------------------------------------------------------------------

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pep-kv-${var.project}"
  location            = azurerm_resource_group.security.location
  resource_group_name = azurerm_resource_group.security.name
  subnet_id           = data.azurerm_subnet.app.id

  private_service_connection {
    name                           = "psc-kv-${var.project}"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"] # Key Vault's subresource type
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }

  tags = {
    Environment = var.environment
    Project     = var.project
    ManagedBy   = "Terraform"
    Lab         = "4.2-private-endpoint"
  }
}
