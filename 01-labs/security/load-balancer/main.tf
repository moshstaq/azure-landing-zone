
# DATA SOURCES - Reference existing resources


data "azurerm_subnet" "app" {
  name                 = "snet-app"
  virtual_network_name = "vnet-spoke-dev"
  resource_group_name  = "rg-spoke-dev"
}

data "azurerm_network_interface" "vm1" {
  name                = "nic-dev-vm"
  resource_group_name = "rg-moshstaq-lab-compute"
}

data "azurerm_network_security_group" "app" {
  name                = "nsg-spoke-dev-app"
  resource_group_name = "rg-spoke-dev"
}


# SECOND VM - vm-dev-002 for HA


resource "azurerm_network_interface" "vm2" {
  name                = "nic-dev-vm-002"
  location            = "eastus2"
  resource_group_name = "rg-moshstaq-lab-compute"

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = data.azurerm_subnet.app.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    environment = "dev"
    lab         = "4.3-load-balancer"
  }
}

resource "azurerm_linux_virtual_machine" "vm2" {
  name                = "vm-dev-002"
  location            = "eastus2"
  resource_group_name = "rg-moshstaq-lab-compute"
  size                = "Standard_B1s"

  admin_username = "azureuser"

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/azure-lab-vm.pub")
  }

  network_interface_ids = [azurerm_network_interface.vm2.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Cloud-init to install nginx and create unique identifier
  custom_data = base64encode(<<-CLOUDINIT
    #cloud-config
    package_update: true
    packages:
      - nginx
    runcmd:
      - echo "<h1>Hello from vm-dev-002</h1><p>Private IP: $(hostname -I | awk '{print $1}')</p>" > /var/www/html/index.html
      - systemctl enable nginx
      - systemctl start nginx
    CLOUDINIT
  )

  tags = {
    environment = "dev"
    lab         = "4.3-load-balancer"
  }
}


# PUBLIC IP - For Load Balancer frontend


resource "azurerm_public_ip" "lb" {
  name                = "pip-lb-web"
  location            = "eastus2"
  resource_group_name = "rg-spoke-dev"
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    environment = "dev"
    lab         = "4.3-load-balancer"
  }
}



# LOAD BALANCER


resource "azurerm_lb" "web" {
  name                = "lb-web-dev"
  location            = "eastus2"
  resource_group_name = "rg-spoke-dev"
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "fe-web"
    public_ip_address_id = azurerm_public_ip.lb.id
  }

  tags = {
    environment = "dev"
    lab         = "4.3-load-balancer"
  }
}



# BACKEND POOL


resource "azurerm_lb_backend_address_pool" "web" {
  name            = "bp-web-servers"
  loadbalancer_id = azurerm_lb.web.id
}

# Associate existing VM (vm-dev-001) NIC with backend pool
resource "azurerm_network_interface_backend_address_pool_association" "vm1" {
  network_interface_id    = data.azurerm_network_interface.vm1.id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
}

# Associate new VM (vm-dev-002) NIC with backend pool
resource "azurerm_network_interface_backend_address_pool_association" "vm2" {
  network_interface_id    = azurerm_network_interface.vm2.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.web.id
}


# HEALTH PROBE


resource "azurerm_lb_probe" "http" {
  name                = "probe-http"
  loadbalancer_id     = azurerm_lb.web.id
  protocol            = "Http"
  port                = 80
  request_path        = "/"
  interval_in_seconds = 5
  number_of_probes    = 2
}


# LOAD BALANCING RULE


resource "azurerm_lb_rule" "http" {
  name                           = "rule-http"
  loadbalancer_id                = azurerm_lb.web.id
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "fe-web"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.web.id]
  probe_id                       = azurerm_lb_probe.http.id
  idle_timeout_in_minutes        = 4
  enable_tcp_reset               = true
  disable_outbound_snat          = true
}


# NSG RULE - Allow HTTP from Internet to backend VMs


resource "azurerm_network_security_rule" "allow_http_lb" {
  name                        = "Allow-HTTP-From-LB"
  priority                    = 105
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "10.1.1.0/24"
  resource_group_name         = "rg-spoke-dev"
  network_security_group_name = data.azurerm_network_security_group.app.name
}
