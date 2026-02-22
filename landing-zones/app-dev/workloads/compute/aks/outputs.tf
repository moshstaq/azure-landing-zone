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
