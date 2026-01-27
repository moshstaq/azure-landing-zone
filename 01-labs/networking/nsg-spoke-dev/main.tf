# Data sources 

data "azurerm_subnet" "app" {
  name                 = "snet-app"
  virtual_network_name = "vnet-spoke-dev"
  resource_group_name  = "rg-spoke-dev"
}

data "azurerm_subnet" "data" {
  name                 = "snet-data"
  virtual_network_name = "vnet-spoke-dev"
  resource_group_name  = "rg-spoke-dev"
}


# NSG for App Subnet
resource "azurerm_network_security_group" "app" {
  name                = "nsg-spoke-dev-app"
  resource_group_name = "rg-spoke-dev"
  location            = "eastus2"

  tags = {
    Environment = "dev"
    Project     = "azure-landing-zone"
    ManagedBy   = "terraform"
  }
}

# Rule: Allow SSH from hub (for jumpbox)
resource "azurerm_network_security_rule" "app_allow_ssh_from_hub" {
  name                        = "Allow_SSH_From_Hub"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "10.0.0.0/16"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.app.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

resource "azurerm_network_security_rule" "app_allow_http_" {
  name                        = "Allow_HTTP"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.app.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

resource "azurerm_network_security_rule" "app_allow_https" {
  name                        = "Allow_HTTPS"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.app.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# Rule: Allow ICMP (ping) from Hub for troubleshooting
resource "azurerm_network_security_rule" "app_allow_icmp_from_hub" {
  name                        = "Allow-ICMP-From-Hub"
  priority                    = 130
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.0.0/16" # Hub VNet
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.app.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# Rule: Explicit deny all other inbound (for logging purposes)
resource "azurerm_network_security_rule" "app_deny_all_inbound" {
  name                        = "Deny-All-Inbound"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.app.resource_group_name
  network_security_group_name = azurerm_network_security_group.app.name
}

# Associate NSG to App Subnet
resource "azurerm_subnet_network_security_group_association" "app" {
  subnet_id                 = data.azurerm_subnet.app.id
  network_security_group_id = azurerm_network_security_group.app.id
}

# NSG for Data Subnet
resource "azurerm_network_security_group" "data" {
  name                = "nsg-spoke-dev-data"
  resource_group_name = "rg-spoke-dev"
  location            = "eastus2"
  tags = {
    Environment = "dev"
    Project     = "azure-landing-zone"
    ManagedBy   = "terraform"
  }
}

# Rule: Allow SQL from App Subnet
resource "azurerm_network_security_rule" "data_allow_sql_from_app" {
  name                        = "Allow_SQL_From_App"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "1433"
  source_address_prefix       = data.azurerm_subnet.app.address_prefixes[0]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.data.resource_group_name
  network_security_group_name = azurerm_network_security_group.data.name
}

# Rule: Allow SSH from Hub (for jumpbox)
resource "azurerm_network_security_rule" "data_allow_ssh_from_hub" {
  name                        = "Allow_SSH_From_Hub"
  priority                    = 110
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "10.0.0.0/16" # Hub VNet
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.data.resource_group_name
  network_security_group_name = azurerm_network_security_group.data.name
}

# Rule: ALlow ICMP (ping) from Hub for troubleshooting
resource "azurerm_network_security_rule" "data_allow_icmp_from_hub" {
  name                        = "Allow-ICMP-From-Hub"
  priority                    = 120
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Icmp"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "10.0.0.0/16" # Hub VNet
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.data.resource_group_name
  network_security_group_name = azurerm_network_security_group.data.name

}

# Rule: Explicit deny all other inbound (for logging purposes)
resource "azurerm_network_security_rule" "data_deny_all_inbound" {
  name                        = "Deny-All-Inbound"
  priority                    = 1000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_network_security_group.data.resource_group_name
  network_security_group_name = azurerm_network_security_group.data.name
}

# Associate NSG to Data Subnet
resource "azurerm_subnet_network_security_group_association" "data" {
  subnet_id                 = data.azurerm_subnet.data.id
  network_security_group_id = azurerm_network_security_group.data.id
}




