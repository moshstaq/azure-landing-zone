output "client_id" {
  description = "Application (client) ID for GitHub secrets"
  value       = azuread_application.github_actions.client_id
}

output "tenant_id" {
  description = "Azure AD tenant ID for GitHub secrets"
  value       = var.tenant_id
}

output "subscription_id" {
  description = "Subscription ID for GitHub secrets"
  value       = var.subscription_id
}

output "service_principal_object_id" {
  description = "Service principal object ID (for reference)"
  value       = azuread_service_principal.github_actions.object_id
}
