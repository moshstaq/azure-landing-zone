# policies.tf

# ============================================================================
# AZURE POLICIES (AUDIT MODE)
# ============================================================================

resource "azurerm_subscription_policy_assignment" "require_environment_tag" {
  name                 = "audit-environment-tag"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"

  display_name = "Audit resources missing Environment tag"

  parameters = jsonencode({
    tagName = { value = "Environment" }
  })
}

resource "azurerm_subscription_policy_assignment" "allowed_locations" {
  name                 = "allowed-locations"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c"

  display_name = "Restrict resource locations"

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = [var.location, "eastus", "eastus2", "westus2", "centralus"]
    }
  })
}
