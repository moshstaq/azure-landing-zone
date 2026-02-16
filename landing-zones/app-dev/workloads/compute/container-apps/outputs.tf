output "environment_id" {
  description = "Container Apps Environment ID"
  value       = azurerm_container_app_environment.this.id
}

output "environment_name" {
  description = "Container Apps Environment name"
  value       = azurerm_container_app_environment.this.name
}

output "app_url" {
  description = "Container App FQDN"
  value       = "https://${azurerm_container_app.hello.ingress[0].fqdn}"
}

output "app_name" {
  description = "Container App name"
  value       = azurerm_container_app.hello.name
}
