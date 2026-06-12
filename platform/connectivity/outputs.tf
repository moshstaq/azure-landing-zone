output "location" {
  description = "Primary region for all platform resources"
  value       = azurerm_resource_group.connectivity.location
}

output "resource_group_name" {
  description = "Name of the connectivity resource group"
  value       = azurerm_resource_group.connectivity.name
}

output "rg_connectivity_name" {
  description = "Name of the platform connectivity resource group"
  value       = azurerm_resource_group.connectivity.name
}

output "rg_workloads_name" {
  description = "Name of the workloads resource group"
  value       = azurerm_resource_group.workloads.name
}

output "rg_data_name" {
  description = "Name of the data resource group"
  value       = azurerm_resource_group.data.name
}

output "rg_taskflow_id" {
  description = "Resource ID of the taskflow workload landing zone"
  value       = azurerm_resource_group.taskflow.id
}

output "rg_taskflow_name" {
  description = "Name of the taskflow workload landing zone"
  value       = azurerm_resource_group.taskflow.name
}

output "vnet_hub_name" {
  description = "Name of the hub virtual network"
  value       = azurerm_virtual_network.hub.name
}

output "vnet_hub_id" {
  description = "ID of the hub virtual network"
  value       = azurerm_virtual_network.hub.id
}

output "vnet_workloads_id" {
  description = "ID of the workloads spoke virtual network"
  value       = azurerm_virtual_network.workloads.id
}

output "vnet_data_id" {
  description = "ID of the data spoke virtual network"
  value       = azurerm_virtual_network.data.id
}

output "snet_shared_services_id" {
  description = "ID of the shared services subnet"
  value       = azurerm_subnet.shared_services.id
}

output "snet_appgw_id" {
  description = "Application Gateway subnet ID"
  value       = azurerm_subnet.appgw.id
}

output "snet_nva_id" {
  description = "ID of the NVA subnet"
  value       = azurerm_subnet.nva.id
}

output "snet_compute_id" {
  description = "ID of the workloads compute subnet"
  value       = azurerm_subnet.workload_compute.id
}

output "snet_containers_id" {
  description = "ID of the containers subnet"
  value       = azurerm_subnet.containers.id
}

output "snet_aks_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.aks.id
}

output "nsg_aks_id" {
  description = "ID of the AKS network security group"
  value       = azurerm_network_security_group.aks.id
}

output "nsg_containers_id" {
  description = "ID of the containers network security group"
  value       = azurerm_network_security_group.containers.id
}

output "nva_private_ip" {
  description = "Static private IP of the hub NVA"
  value       = "10.0.3.4"
}

/*
output "private_dns_zone_kv_rg" {
  description = "Resource group containing the ephemeral Key Vault private DNS zone."
  value       = azurerm_resource_group.connectivity.name
}

output "private_dns_zone_kv_id" {
  description = "Resource ID of the ephemeral Key Vault private DNS zone."
  value       = azurerm_private_dns_zone.kv.id
}
*/

output "snet_data_services_id" {
  description = "ID of the data services subnet"
  value       = azurerm_subnet.data_services.id
}
