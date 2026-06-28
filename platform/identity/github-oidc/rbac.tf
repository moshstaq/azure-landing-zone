

# -----------------------------------------------------
# azure-landing-zone SP
# Manages all platform modules — needs Contributor
# on every RG it provisions resources into
# -----------------------------------------------------

resource "azurerm_role_assignment" "landing_zone_connectivity" {
  scope                = data.azurerm_resource_group.connectivity.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions["azure-landing-zone"].object_id
}

resource "azurerm_role_assignment" "landing_zone_management" {
  scope                = data.azurerm_resource_group.management.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions["azure-landing-zone"].object_id
}

resource "azurerm_role_assignment" "landing_zone_workloads" {
  scope                = data.azurerm_resource_group.workloads.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions["azure-landing-zone"].object_id
}

resource "azurerm_role_assignment" "landing_zone_data" {
  scope                = data.azurerm_resource_group.data.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions["azure-landing-zone"].object_id
}

resource "azurerm_role_assignment" "landing_zone_tfstate_blob" {
  scope                = data.azurerm_resource_group.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_actions["azure-landing-zone"].object_id
}

resource "azurerm_role_assignment" "landing_zone_tfstate_reader" {
  scope                = data.azurerm_resource_group.tfstate.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.github_actions["azure-landing-zone"].object_id
}

resource "azurerm_role_assignment" "landing_zone_monitoring_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azuread_service_principal.github_actions["azure-landing-zone"].object_id
}

resource "azurerm_role_assignment" "landing_zone_cost_management_reader" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Cost Management Reader"
  principal_id         = azuread_service_principal.github_actions["azure-landing-zone"].object_id
}

resource "azurerm_role_assignment" "landing_zone_management_group_reader" {
  scope                = "/providers/Microsoft.Management/managementGroups/moshstaq"
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.github_actions["azure-landing-zone"].object_id
}

# -----------------------------------------------------
# taskflow-platform SP
# Contributor on rg-taskflow for all workload resources
# Network Contributor on the workloads Vnet and subnets
# -----------------------------------------------------


resource "azuread_application_federated_identity_credential" "environment_production" {
  for_each       = var.repos
  application_id = azuread_application.github_actions[each.key].id
  display_name   = "github-environment-production"
  issuer         = "https://token.actions.githubusercontent.com"
  subject        = "repo:${var.github_org}/${each.key}:environment:azure-production"
  audiences      = ["api://AzureADTokenExchange"]
  description    = "Trust GitHub Actions from azure-production environment"
}

resource "azurerm_role_assignment" "taskflow_contributor" {
  scope                = data.azurerm_resource_group.taskflow.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions["taskflow-platform"].object_id
}

resource "azurerm_role_assignment" "taskflow_network_contributor" {
  scope                = data.azurerm_resource_group.workloads.id
  role_definition_name = "Network Contributor"
  principal_id         = azuread_service_principal.github_actions["taskflow-platform"].object_id
}

resource "azurerm_role_assignment" "taskflow_tfstate_blob" {
  scope                = data.azurerm_resource_group.tfstate.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_service_principal.github_actions["taskflow-platform"].object_id
}

resource "azurerm_role_assignment" "taskflow_tfstate_reader" {
  scope                = data.azurerm_resource_group.tfstate.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.github_actions["taskflow-platform"].object_id
}

resource "azurerm_role_assignment" "landing_zone_taskflow_reader" {
  scope                = data.azurerm_resource_group.taskflow.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.github_actions["azure-landing-zone"].object_id
}
