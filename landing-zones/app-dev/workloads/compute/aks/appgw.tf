# ─────────────────────────────────────────────────────
# Application Gateway
# Conceptually a hub resource but managed here alongside
# AKS since both are ephemeral — deployed and destroyed
# together to stay within budget constraints.
# In production this would be permanent in platform/connectivity.
#
# snet-appgw is permanent and lives in platform/connectivity.
# This module reads it via data source in data.tf.
# ─────────────────────────────────────────────────────
locals {
  location = "eastus2"
}

# Public IP — internet entry point
resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw"
  location            = local.location
  resource_group_name = "rg-platform-connectivity"
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

# Application Gateway
resource "azurerm_application_gateway" "hub" {
  name                = "agw-hub"
  location            = local.location
  resource_group_name = "rg-platform-connectivity"

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = data.azurerm_subnet.appgw.id
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  frontend_port {
    name = "port-80"
    port = 80
  }

  backend_address_pool {
    name         = "aks-ingress-pool"
    ip_addresses = ["10.1.4.38"]
  }

  backend_http_settings {
    name                  = "aks-http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    probe_name            = "aks-health-probe"
  }

  probe {
    name                = "aks-health-probe"
    protocol            = "Http"
    path                = "/"
    host                = "10.1.4.38"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip"
    frontend_port_name             = "port-80"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "http-routing-rule"
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "aks-ingress-pool"
    backend_http_settings_name = "aks-http-settings"
  }

  tags = {
    environment = "dev"
    managed_by  = "terraform"
    note        = "ephemeral-see-readme"
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }
}
