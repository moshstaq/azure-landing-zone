# Reference existing spoke VNet
data "azurerm_virtual_network" "spoke_dev" {
  name                = "vnet-spoke-dev"
  resource_group_name = "rg-spoke-dev"
}

# Reference existing resource group for containers
data "azurerm_resource_group" "containers" {
  name = "rg-${var.project_name}-lab-containers"
}

#---------------------------------------------------------------
# Subnet for ACI (with delegation)
# This subnet is dedicated to Azure Container Instances
#---------------------------------------------------------------
resource "azurerm_subnet" "containers" {
  name                 = "snet-containers"
  resource_group_name  = data.azurerm_virtual_network.spoke_dev.resource_group_name
  virtual_network_name = data.azurerm_virtual_network.spoke_dev.name
  address_prefixes     = [var.container_subnet_cidr]

  # ACI requires subnet delegation
  delegation {
    name = "aci-delegation"

    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

#---------------------------------------------------------------
# NSG for Container Subnet
#---------------------------------------------------------------
resource "azurerm_network_security_group" "containers" {
  name                = "nsg-spoke-dev-containers"
  location            = var.location
  resource_group_name = data.azurerm_virtual_network.spoke_dev.resource_group_name
  tags                = var.tags
}

# Allow HTTP from App subnet to Containers
resource "azurerm_network_security_rule" "allow_http_from_app" {
  name                        = "Allow-HTTP-From-App-Subnet"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "10.1.1.0/24" # snet-app
  destination_address_prefix  = var.container_subnet_cidr
  resource_group_name         = data.azurerm_virtual_network.spoke_dev.resource_group_name
  network_security_group_name = azurerm_network_security_group.containers.name
}

# Allow HTTPS from App subnet
resource "azurerm_network_security_rule" "allow_https_from_app" {
  name                        = "Allow-HTTPS-From-App-Subnet"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "10.1.1.0/24"
  destination_address_prefix  = var.container_subnet_cidr
  resource_group_name         = data.azurerm_virtual_network.spoke_dev.resource_group_name
  network_security_group_name = azurerm_network_security_group.containers.name
}

# Allow from Hub (for management/testing)
resource "azurerm_network_security_rule" "allow_from_hub" {
  name                        = "Allow-From-Hub"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.0.0/16" # Hub VNet
  destination_address_prefix  = var.container_subnet_cidr
  resource_group_name         = data.azurerm_virtual_network.spoke_dev.resource_group_name
  network_security_group_name = azurerm_network_security_group.containers.name
}

# Deny all other inbound
resource "azurerm_network_security_rule" "deny_all_inbound" {
  name                        = "Deny-All-Inbound"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_virtual_network.spoke_dev.resource_group_name
  network_security_group_name = azurerm_network_security_group.containers.name
}

# Associate NSG with subnet
resource "azurerm_subnet_network_security_group_association" "containers" {
  subnet_id                 = azurerm_subnet.containers.id
  network_security_group_id = azurerm_network_security_group.containers.id
}

#---------------------------------------------------------------
# Private ACI Container Group (VNet Integrated)
#---------------------------------------------------------------
resource "azurerm_container_group" "private_api" {
  name                = "aci-${var.project_name}-private"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.containers.name
  os_type             = "Linux"

  # VNet integration - no public IP
  ip_address_type = "Private"
  subnet_ids      = [azurerm_subnet.containers.id]

  restart_policy = "Always"

  container {
    name   = "api"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = 0.5
    memory = 0.5

    ports {
      port     = 80
      protocol = "TCP"
    }

    environment_variables = {
      "SERVICE_NAME" = "private-api"
      "ENVIRONMENT"  = var.environment
    }
  }

  tags = merge(var.tags, {
    NetworkType = "Private"
  })
}

#---------------------------------------------------------------
# Private DNS Zone for Container Resolution
# Allows accessing container by name instead of IP
#---------------------------------------------------------------
resource "azurerm_private_dns_zone" "containers" {
  name                = "containers.${var.project_name}.local"
  resource_group_name = data.azurerm_resource_group.containers.name
  tags                = var.tags
}

# Link DNS zone to spoke VNet
resource "azurerm_private_dns_zone_virtual_network_link" "spoke_dev" {
  name                  = "link-spoke-dev"
  resource_group_name   = data.azurerm_resource_group.containers.name
  private_dns_zone_name = azurerm_private_dns_zone.containers.name
  virtual_network_id    = data.azurerm_virtual_network.spoke_dev.id
  registration_enabled  = false # We'll add records manually

  tags = var.tags
}

# A record for the private container
resource "azurerm_private_dns_a_record" "private_api" {
  name                = "api"
  zone_name           = azurerm_private_dns_zone.containers.name
  resource_group_name = data.azurerm_resource_group.containers.name
  ttl                 = 300
  records             = [azurerm_container_group.private_api.ip_address]
}
