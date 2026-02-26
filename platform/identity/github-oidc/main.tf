# -----------------------------------------------------
# Data Sources
# -----------------------------------------------------
data "azurerm_subscription" "current" {}

data "azurerm_resource_group" "app_dev" {
  name = "rg-app-dev"
}

# We'll also need rg-tfstate for state file access
data "azurerm_resource_group" "tfstate" {
  name = "rg-tfstate"
}

data "azurerm_resource_group" "connectivity" {
  name = "rg-platform-connectivity"
}



# -----------------------------------------------------
# Azure AD Application Registration
# -----------------------------------------------------
resource "azuread_application" "github_actions" {
  display_name = "sp-github-actions-${var.github_repo}"

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false
  }
}

# -----------------------------------------------------
# Service Principal (the "instance" of the app)
# -----------------------------------------------------
resource "azuread_service_principal" "github_actions" {

  client_id = azuread_application.github_actions.client_id
}

# -----------------------------------------------------
# Federated Identity Credential
# This is the "trust" between Azure AD and GitHub
# -----------------------------------------------------
resource "azuread_application_federated_identity_credential" "main_branch" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-main-branch"


  issuer    = "https://token.actions.githubusercontent.com"
  subject   = "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/main"
  audiences = ["api://AzureADTokenExchange"]

  description = "Trust GitHub Actions from main branch"
}

# -----------------------------------------------------
# Federated Credential for Pull Requests
# -----------------------------------------------------
resource "azuread_application_federated_identity_credential" "pull_request" {
  application_id = azuread_application.github_actions.id
  display_name   = "github-pull-requests"

  issuer = "https://token.actions.githubusercontent.com"

  subject   = "repo:${var.github_org}/${var.github_repo}:pull_request"
  audiences = ["api://AzureADTokenExchange"]

  description = "Trust GitHub Actions from pull requests"
}

# Reader on connectivity — allows pipeline to read hub resources
# without being able to modify VNet, NSGs, peering, or other platform infra
resource "azurerm_role_assignment" "connectivity_reader" {
  scope                = data.azurerm_resource_group.connectivity.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.github_actions.object_id
}

# Contributor scoped to connectivity RG
# Required to manage ephemeral App Gateway and Public IP during AKS sessions
resource "azurerm_role_assignment" "connectivity_contributor" {
  scope                = data.azurerm_resource_group.connectivity.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}
