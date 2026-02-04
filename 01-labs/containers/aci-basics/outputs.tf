output "resource_group_name" {
  description = "Resource group containing ACI resources"
  value       = azurerm_resource_group.containers.name
}

#---------------------------------------------------------------
# Hello World Container Outputs
#---------------------------------------------------------------
output "helloworld_fqdn" {
  description = "FQDN for Hello World container"
  value       = azurerm_container_group.helloworld.fqdn
}

output "helloworld_ip" {
  description = "Public IP for Hello World container"
  value       = azurerm_container_group.helloworld.ip_address
}

output "helloworld_url" {
  description = "URL to access Hello World app"
  value       = "http://${azurerm_container_group.helloworld.fqdn}"
}

#---------------------------------------------------------------
# Batch Job Container Outputs
#---------------------------------------------------------------
output "batchjob_name" {
  description = "Name of batch job container group"
  value       = azurerm_container_group.batchjob.name
}

output "batchjob_state" {
  description = "Current state of batch job"
  value       = "Check with: az container show -g ${azurerm_resource_group.containers.name} -n ${azurerm_container_group.batchjob.name} --query 'instanceView.state' -o tsv"
}

#---------------------------------------------------------------
# Multi-Container Outputs
#---------------------------------------------------------------
output "multicontainer_fqdn" {
  description = "FQDN for multi-container group"
  value       = azurerm_container_group.multicontainer.fqdn
}

output "multicontainer_url" {
  description = "URL to access multi-container app"
  value       = "http://${azurerm_container_group.multicontainer.fqdn}"
}

#---------------------------------------------------------------
# Useful Commands
#---------------------------------------------------------------
output "useful_commands" {
  description = "Commands for interacting with containers"
  value = {
    view_logs_helloworld = "az container logs -g ${azurerm_resource_group.containers.name} -n ${azurerm_container_group.helloworld.name}"
    view_logs_batchjob   = "az container logs -g ${azurerm_resource_group.containers.name} -n ${azurerm_container_group.batchjob.name}"
    view_logs_sidecar    = "az container logs -g ${azurerm_resource_group.containers.name} -n ${azurerm_container_group.multicontainer.name} --container-name sidecar"
    exec_into_container  = "az container exec -g ${azurerm_resource_group.containers.name} -n ${azurerm_container_group.helloworld.name} --exec-command '/bin/sh'"
    show_status          = "az container show -g ${azurerm_resource_group.containers.name} -n ${azurerm_container_group.helloworld.name} --query 'instanceView.state' -o tsv"
    stop_container       = "az container stop -g ${azurerm_resource_group.containers.name} -n ${azurerm_container_group.helloworld.name}"
    start_container      = "az container start -g ${azurerm_resource_group.containers.name} -n ${azurerm_container_group.helloworld.name}"
  }
}

#---------------------------------------------------------------
# Cost Information
#---------------------------------------------------------------
output "cost_info" {
  description = "Cost information for ACI"
  value = {
    pricing_model = "Per-second billing"
    cpu_rate      = "~$0.0000125/second per vCPU (Linux)"
    memory_rate   = "~$0.0000015/second per GB"
    tip           = "Stop containers when not testing to minimize costs"
    stop_all      = "az container stop -g ${azurerm_resource_group.containers.name} -n ${azurerm_container_group.helloworld.name} && az container stop -g ${azurerm_resource_group.containers.name} -n ${azurerm_container_group.multicontainer.name}"
  }
}
