
# ============================================================================
# DATA SOURCES
# ============================================================================

data "azurerm_subscription" "current" {}
data "azurerm_client_config" "current" {}
data "azuread_client_config" "current" {}

# ============================================================================
# LOCALS
# ============================================================================

locals {
  prefix = var.your_name

  common_tags = {
    Environment = "learning"
    ManagedBy   = "terraform"
    Team        = "Ops"
    Owner       = var.your_name
  }

  lab_categories = ["compute", "networking", "monitoring", "identity", "devops", "project"]
}

# ============================================================================
# RANDOM SUFFIX
# ============================================================================

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# ============================================================================
# MANAGEMENT GROUPS
# ============================================================================

resource "azurerm_management_group" "root" {
  display_name               = "${local.prefix}-learning"
  parent_management_group_id = "/providers/Microsoft.Management/managementGroups/${data.azurerm_client_config.current.tenant_id}"
}

resource "azurerm_management_group" "platform" {
  display_name               = "${local.prefix}-platform"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group" "workloads" {
  display_name               = "${local.prefix}-workloads"
  parent_management_group_id = azurerm_management_group.root.id
}

resource "azurerm_management_group_subscription_association" "current" {
  management_group_id = azurerm_management_group.workloads.id
  subscription_id     = "/subscriptions/${data.azurerm_subscription.current.subscription_id}"
}

# ============================================================================
# RESOURCE GROUPS - Platform (Permanent)
# ============================================================================

resource "azurerm_resource_group" "platform_core" {
  name     = "rg-${local.prefix}-platform-core"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "platform_network" {
  name     = "rg-${local.prefix}-platform-network"
  location = var.location
  tags     = local.common_tags
}

resource "azurerm_resource_group" "tfstate" {
  name     = "rg-${local.prefix}-tfstate"
  location = var.location
  tags     = local.common_tags
}

# ============================================================================
# RESOURCE GROUPS - Labs (Disposable)
# ============================================================================

resource "azurerm_resource_group" "labs" {
  for_each = toset(local.lab_categories)

  name     = "rg-${local.prefix}-lab-${each.value}"
  location = var.location

  tags = merge(local.common_tags, {
    Type       = "learning-lab"
    Disposable = "true"
  })
}

# ============================================================================
# TERRAFORM STATE STORAGE
# ============================================================================

resource "azurerm_storage_account" "tfstate" {
  name                     = "st${local.prefix}tfst${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.tfstate.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_2"

  tags = local.common_tags
}

resource "azurerm_storage_container" "tfstate" {
  name                  = "tfstate"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# ============================================================================
# LOG ANALYTICS WORKSPACE
# ============================================================================

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${local.prefix}-main"
  resource_group_name = azurerm_resource_group.platform_core.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = local.common_tags
}

# ============================================================================
# HUB VIRTUAL NETWORK
# ============================================================================

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${local.prefix}-hub"
  resource_group_name = azurerm_resource_group.platform_network.name
  location            = var.location
  address_space       = ["10.0.0.0/16"]

  tags = local.common_tags
}

resource "azurerm_subnet" "shared_services" {
  name                 = "snet-shared-services"
  resource_group_name  = azurerm_resource_group.platform_network.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.0.0/24"]
}

# ============================================================================
# NETWORK SECURITY GROUP
# ============================================================================

resource "azurerm_network_security_group" "hub_default" {
  name                = "nsg-${local.prefix}-hub-default"
  resource_group_name = azurerm_resource_group.platform_network.name
  location            = var.location

  tags = local.common_tags
}

resource "azurerm_subnet_network_security_group_association" "shared_services" {
  subnet_id                 = azurerm_subnet.shared_services.id
  network_security_group_id = azurerm_network_security_group.hub_default.id
}

# ============================================================================
# ENTRA ID GROUPS
# ============================================================================

resource "azuread_group" "lab_admins" {
  display_name     = "${local.prefix}-Lab-Admins"
  security_enabled = true
  description      = "Full access to learning lab resources"
  owners           = [data.azuread_client_config.current.object_id]
  members          = [data.azuread_client_config.current.object_id]
}

resource "azuread_group" "lab_contributors" {
  display_name     = "${local.prefix}-Lab-Contributors"
  security_enabled = true
  description      = "Contributor access to learning lab resources"
  owners           = [data.azuread_client_config.current.object_id]
}

resource "azuread_group" "lab_readers" {
  display_name     = "${local.prefix}-Lab-Readers"
  security_enabled = true
  description      = "Read-only access to learning lab resources"
  owners           = [data.azuread_client_config.current.object_id]
}

# ============================================================================
# RBAC ASSIGNMENTS
# ============================================================================

resource "azurerm_role_assignment" "lab_admins" {
  for_each = azurerm_resource_group.labs

  scope                = each.value.id
  role_definition_name = "Owner"
  principal_id         = azuread_group.lab_admins.object_id
}

resource "azurerm_role_assignment" "lab_contributors" {
  for_each = azurerm_resource_group.labs

  scope                = each.value.id
  role_definition_name = "Contributor"
  principal_id         = azuread_group.lab_contributors.object_id
}
