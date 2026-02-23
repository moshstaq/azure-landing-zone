output "cluster_id" {
  description = "AKS cluster ID"
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "AKS cluster name"
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_fqdn" {
  description = "AKS cluster FQDN"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "kube_config_command" {
  description = "Command to get kubeconfig"
  value       = "az aks get-credentials --resource-group ${data.terraform_remote_state.networking.outputs.resource_group_name} --name ${azurerm_kubernetes_cluster.this.name}"
}

output "node_resource_group" {
  description = "Resource group containing AKS nodes"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "appgw_public_ip" {
  description = "Application Gateway public IP — internet entry point"
  value       = azurerm_public_ip.appgw.ip_address
}

output "workload_identity_client_id" {
  description = "Client ID of the managed identity for workload identity binding"
  value       = azurerm_user_assigned_identity.workload.client_id
}

output "key_vault_name" {
  description = "Key Vault name"
  value       = azurerm_key_vault.workload.name
}

output "db_password_secret_uri" {
  description = "Key Vault secret URI for db-password"
  value       = azurerm_key_vault_secret.db_password.id
}

output "appgw_id" {
  description = "Application Gateway resource ID"
  value       = azurerm_application_gateway.hub.id
}
