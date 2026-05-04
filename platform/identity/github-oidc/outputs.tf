output "landing_zone_client_id" {
  description = "Client ID for the azure-landing-zone GitHub Actions SP"
  value       = azuread_application.github_actions["azure-landing-zone"].client_id
}

output "landing_zone_object_id" {
  description = "Service principal object ID for the azure-landing-zone SP"
  value       = azuread_service_principal.github_actions["azure-landing-zone"].object_id
}

output "taskflow_client_id" {
  description = "Client ID for the taskflow-platform GitHub Actions SP"
  value       = azuread_application.github_actions["taskflow-platform"].client_id
}

output "taskflow_object_id" {
  description = "Service principal object ID for the taskflow-platform SP"
  value       = azuread_service_principal.github_actions["taskflow-platform"].object_id
}

output "tenant_id" {
  description = "Azure AD tenant ID"
  value       = var.tenant_id
}

output "subscription_id" {
  description = "Subscription ID"
  value       = var.subscription_id
}
