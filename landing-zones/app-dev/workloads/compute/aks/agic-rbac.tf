resource "azurerm_user_assigned_identity" "agic" {
  name                = "mi-agic"
  location            = local.location
  resource_group_name = local.resource_group_name

  tags = {
    environment = "dev"
    managed_by  = "terraform"
  }
}

resource "azurerm_federated_identity_credential" "agic" {
  name                = "fed-agic"
  resource_group_name = local.resource_group_name
  parent_id           = azurerm_user_assigned_identity.agic.id
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.this.oidc_issuer_url
  subject             = "system:serviceaccount:kube-system:ingress-azure"
}

resource "azurerm_role_assignment" "agic_appgw_contributor" {
  scope                = azurerm_application_gateway.hub.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.agic.principal_id
}

resource "azurerm_role_assignment" "agic_rg_reader" {
  scope                = data.azurerm_resource_group.connectivity.id
  role_definition_name = "Reader"
  principal_id         = azurerm_user_assigned_identity.agic.principal_id
}

resource "azurerm_role_assignment" "agic_subnet_network_contributor" {
  scope                = data.azurerm_subnet.appgw.id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_user_assigned_identity.agic.principal_id
}

output "agic_client_id" {
  description = "AGIC managed identity client ID for Helm install"
  value       = azurerm_user_assigned_identity.agic.client_id
}
