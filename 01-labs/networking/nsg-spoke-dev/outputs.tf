output "nsg_app_id" {
  description = "ID of the App subnet NSG"
  value       = azurerm_network_security_group.app.id
}

output "nsg_data_id" {
  description = "ID of the Data subnet NSG"
  value       = azurerm_network_security_group.data.id
}


output "security_rules_summary" {
  description = "Summary of security posture"
  value = {
    app_subnet = {
      ssh_from   = "Hub (10.0.0.0/16)"
      http_from  = "Internet"
      https_from = "Internet"
      default    = "Deny all other"
    }
    data_subnet = {
      sql_from = "App subnet only (10.1.1.0/24)"
      ssh_from = "Hub (10.0.0.0/16)"
      default  = "Deny all other"
    }
    flow_logs = "VNet-level (covers all subnets)"
  }
}



