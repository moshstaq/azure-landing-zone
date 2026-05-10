# -----------------------------------------------------
# Data Sources
# -----------------------------------------------------
data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "tfstate" {
  name = "rg-tfstate"
}

data "azurerm_resource_group" "connectivity" {
  name = "rg-platform-connectivity"
}

data "azurerm_resource_group" "management" {
  name = "rg-platform-management"
}

data "azurerm_resource_group" "workloads" {
  name = "rg-workloads"
}

data "azurerm_resource_group" "data" {
  name = "rg-data"
}

data "azurerm_resource_group" "taskflow" {
  name = "rg-taskflow"
}

data "azurerm_subnet" "aks" {
  name                 = "snet-aks"
  virtual_network_name = "vnet-workloads"
  resource_group_name  = "rg-workloads"
}




# -----------------------------------------------------
# AAD Applications
# -----------------------------------------------------
resource "azuread_application" "github_actions" {
  for_each     = var.repos
  display_name = each.value.display_name
}

# -----------------------------------------------------
# Service Principals
# -----------------------------------------------------
resource "azuread_service_principal" "github_actions" {
  for_each  = var.repos
  client_id = azuread_application.github_actions[each.key].client_id
}

# -----------------------------------------------------
# Federated Credential — main branch
# -----------------------------------------------------
resource "azuread_application_federated_identity_credential" "main_branch" {
  for_each       = var.repos
  application_id = azuread_application.github_actions[each.key].id
  display_name   = "github-main-branch"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${each.key}:ref:refs/heads/main"
  audiences      = ["api://AzureADTokenExchange"]
  description    = "Trust GitHub Actions from main branch"
}

# -----------------------------------------------------
# Federated Credential — pull requests
# -----------------------------------------------------
resource "azuread_application_federated_identity_credential" "pull_request" {
  for_each       = var.repos
  application_id = azuread_application.github_actions[each.key].id
  display_name   = "github-pull-requests"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${each.key}:pull_request"
  audiences      = ["api://AzureADTokenExchange"]
  description    = "Trust GitHub Actions from pull requests"
}


