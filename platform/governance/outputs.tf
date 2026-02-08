output "require_tag_policy_id" {
  description = "Policy definition ID for required tags"
  value       = azurerm_policy_definition.require_tag_rg.id
}

output "allowed_locations_policy_id" {
  description = "Policy definition ID for allowed locations"
  value       = azurerm_policy_definition.allowed_locations.id
}

output "diagnostic_settings_policy_id" {
  description = "Policy definition ID for diagnostic settings"
  value       = azurerm_policy_definition.deploy_diag_activity_log.id
}

output "policy_identity_principal_id" {
  description = "Principal ID of the policy managed identity"
  value       = azurerm_management_group_policy_assignment.deploy_diag_activity_log.identity[0].principal_id
}
