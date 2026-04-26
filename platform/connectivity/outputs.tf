
# ── Resource Groups ───────────────────────────────────────────────────────────

output "rg_connectivity_name" {
  value = azurerm_resource_group.connectivity.name
}

output "rg_workloads_name" {
  value = azurerm_resource_group.workloads.name
}

output "rg_data_name" {
  value = azurerm_resource_group.data.name
}

# ── VNet IDs ──────────────────────────────────────────────────────────────────

output "vnet_hub_id" {
  value = azurerm_virtual_network.hub.id
}

output "vnet_hub_name" {
  value = azurerm_virtual_network.hub.name
}

output "vnet_workloads_id" {
  value = azurerm_virtual_network.workloads.id
}

output "vnet_data_id" {
  value = azurerm_virtual_network.data.id
}

# ── Subnet IDs — consumed by workload modules ─────────────────────────────────

output "snet_compute_id" {
  description = "General compute subnet — VMs, workload pods"
  value       = azurerm_subnet.workload_compute.id
}



output "snet_containers_id" {
  description = "ACI delegated subnet"
  value       = azurerm_subnet.containers.id
}

output "snet_aks_id" {
  description = "AKS subnet — Azure CNI pod IPs drawn from this range"
  value       = azurerm_subnet.aks.id
}



output "snet_nva_id" {
  description = "NVA subnet in hub — consumed by platform/nva module"
  value       = azurerm_subnet.nva.id
}

output "snet_appgw_id" {
  description = "Application Gateway subnet in hub"
  value       = azurerm_subnet.appgw.id
}

# ── NVA ───────────────────────────────────────────────────────────────────────

output "nva_private_ip" {
  description = "Static private IP of the NVA — next-hop for spoke UDRs"
  value       = var.nva_private_ip
}

# ── NSG IDs ───────────────────────────────────────────────────────────────────

output "nsg_aks_id" {
  value = azurerm_network_security_group.aks.id
}

output "nsg_containers_id" {
  value = azurerm_network_security_group.containers.id
}



# ── Location ──────────────────────────────────────────────────────────────────

output "location" {
  value = var.location
}
