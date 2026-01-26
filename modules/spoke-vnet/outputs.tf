output "hub_vnet_id" {
  description = "ID of the spoke"
  value       = azurerm_virtual_network.spoke.id
}

output "vnet_name" {
  description = "Name of the spoke vnet"
  value       = azurerm_virtual_network.spoke.name
}

output "subnet_ids" {
  description = "IDs of the map subnets in the spoke vnet"
  value       = { for sname, subnet in azurerm_subnet.subnets : sname => subnet.id }
}

output "address_space" {
  description = "Address space of the spoke VNet"
  value       = azurerm_virtual_network.spoke.address_space
}
