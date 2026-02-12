#--------------------------------------------------------------
# Private Endpoint for Storage Account (Blob)
#--------------------------------------------------------------

resource "azurerm_private_endpoint" "blob" {
  name                = "pe-${azurerm_storage_account.main.name}-blob"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = data.azurerm_subnet.data.id

  private_service_connection {
    name                           = "psc-${azurerm_storage_account.main.name}-blob"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false

    subresource_names = ["blob"]
  }

  tags = var.tags
}

#--------------------------------------------------------------
# Private DNS Zone for Blob Storage
#--------------------------------------------------------------

resource "azurerm_private_dns_zone" "blob" {

  name                = "privatelink.blob.core.windows.net"
  resource_group_name = var.resource_group_name

  tags = var.tags
}

#--------------------------------------------------------------
# Link Private DNS Zone to VNet
#--------------------------------------------------------------

resource "azurerm_private_dns_zone_virtual_network_link" "blob" {
  name                  = "link-${var.vnet_name}-blob"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.blob.name

  virtual_network_id = data.azurerm_virtual_network.main.id


  tags = var.tags
}

#--------------------------------------------------------------
# DNS A Record (maps storage FQDN to Private Endpoint IP)
#--------------------------------------------------------------

resource "azurerm_private_dns_a_record" "blob" {
  name                = azurerm_storage_account.main.name
  zone_name           = azurerm_private_dns_zone.blob.name
  resource_group_name = var.resource_group_name
  ttl                 = 300


  records = [azurerm_private_endpoint.blob.private_service_connection[0].private_ip_address]
}
