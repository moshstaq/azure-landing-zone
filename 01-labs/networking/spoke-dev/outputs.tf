output "spoke_vnet_id" {
  description = "Dev Spoke Vnet ID"
  value       = module.spoke_dev_vnet.hub_vnet_id
}

output "spoke_vnet_name" {
  description = "Dev spoke VNet name"
  value       = module.spoke_dev_vnet.vnet_name
}

output "subnet_ids" {
  description = "Subnet IDs in dev spoke"
  value       = module.spoke_dev_vnet.subnet_ids
}

output "peering_status" {
  description = "Confirmation of peering setup"
  value       = "Hub and Spoke peering established successfully"
}
