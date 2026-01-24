resource "azurerm_virtual_network" "lab" {
  name                = "vnet-${var.prefix}-lab-compute"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.lab.name
  address_space       = ["10.10.0.0/16"]

  tags = {
    Environment = "learning"
    Lab         = "compute"

  }
}

resource "azurerm_subnet" "vm" {
  name                 = "snet-vm"
  resource_group_name  = data.azurerm_resource_group.lab.name
  virtual_network_name = azurerm_virtual_network.lab.name
  address_prefixes     = ["10.10.1.0/24"]
}

resource "azurerm_network_security_group" "vm" {
  name                = "nsg-${var.prefix}-lab-vm"
  resource_group_name = data.azurerm_resource_group.lab.name
  location            = var.location


  security_rule {
    name                       = "allow-ssh"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = "learning"
    Lab         = "compute"
  }
}

resource "azurerm_subnet_network_security_group_association" "vm" {
  subnet_id                 = azurerm_subnet.vm.id
  network_security_group_id = azurerm_network_security_group.vm.id
}

resource "azurerm_public_ip" "vm" {
  name                = "pip-${var.prefix}-lab-vm"
  resource_group_name = data.azurerm_resource_group.lab.name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = "learning"
  }
}

resource "azurerm_network_interface" "vm" {
  name                = "nic-${var.prefix}-lab-vm"
  resource_group_name = data.azurerm_resource_group.lab.name
  location            = var.location

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.vm.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }

  tags = {
    Environment = "learning"
    Lab         = "compute"
  }
}
