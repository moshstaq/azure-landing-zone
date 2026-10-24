#---------------------------------------------------------
# Data Source: Management Group for Policy Assignment
#---------------------------------------------------------
data "azurerm_management_group" "root" {
  name = var.management_group_name
}

#---------------------------------------------------------
# RBAC: Management Group for Policy Assignment
#---------------------------------------------------------

#---------------------------------------------------------
# Policy 1: Require Environment Tag on Resource Groups
# Effect: Audit (logs non-compliance, doesn't block)
#---------------------------------------------------------
resource "azurerm_policy_definition" "require_tag_rg" {
  name         = "require-tag-on-resource-groups"
  display_name = "Require Environment tag on resource groups"
  description  = "Audits resource groups that don't have the Environment tag"
  policy_type  = "Custom"
  mode         = "All"

  management_group_id = data.azurerm_management_group.root.id

  metadata = jsonencode({
    category = "Tags"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field  = "type"
          equals = "Microsoft.Resources/subscriptions/resourceGroups"
        },
        {
          field  = "[concat('tags[', parameters('tagName'), ']')]"
          exists = "false"
        }
      ]
    }
    then = {
      effect = "audit"
    }
  })

  parameters = jsonencode({
    tagName = {
      type = "String"
      metadata = {
        displayName = "Tag Name"
        description = "Name of the tag to require"
      }
    }
  })
}

#---------------------------------------------------------
# Policy 2: Allowed Locations
# Effect: Deny (blocks non-compliant deployments)
#---------------------------------------------------------
resource "azurerm_policy_definition" "allowed_locations" {
  name         = "allowed-locations-custom"
  display_name = "Allowed locations for resources"
  description  = "Restricts resource deployment to approved Azure regions"
  policy_type  = "Custom"
  mode         = "Indexed"

  management_group_id = data.azurerm_management_group.root.id

  metadata = jsonencode({
    category = "General"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      allOf = [
        {
          field = "location"
          notIn = "[parameters('allowedLocations')]"
        },
        {
          field     = "location"
          notEquals = "global"
        }

      ]

    }
    then = {
      effect = "deny"
    }
  })

  parameters = jsonencode({
    allowedLocations = {
      type = "Array"
      metadata = {
        displayName = "Allowed Locations"
        description = "List of allowed Azure regions"
        strongType  = "location"
      }
      defaultValue = ["eastus2"] # Default to eastus2, can be overridden in assignment
    }
  })
}




#---------------------------------------------------------
# Policy Assignment: Allowed Locations
#---------------------------------------------------------
resource "azurerm_management_group_policy_assignment" "allowed_locations" {
  name                 = "allow-eastus2-only"
  display_name         = "Allow eastus2 only"
  description          = "Restricts all resource deployments to eastus2"
  management_group_id  = data.azurerm_management_group.root.id
  policy_definition_id = azurerm_policy_definition.allowed_locations.id

  parameters = jsonencode({
    allowedLocations = {
      value = var.allowed_locations
    }
  })
}

#---------------------------------------------------------
# Policy Assignment: Audit Allowed Locations
#---------------------------------------------------------
resource "azurerm_management_group_policy_assignment" "auditing_locations" {
  name                 = "audit-rg-locations"
  display_name         = "Allowed locations for resource groups (audit mode)"
  description          = "Review resource groups at the management group"
  management_group_id  = data.azurerm_management_group.root.id
  policy_definition_id = "/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988"

  parameters = jsonencode({
    listOfAllowedLocations = {
      value = var.allowed_locations

    }
    effect = {
      value = "Audit"
    }
  })
}



#---------------------------------------------------------
# Policy Assignment: Apply to Management Group
#---------------------------------------------------------
resource "azurerm_management_group_policy_assignment" "require_tag_rg" {
  name                 = "require-env-tag-rg"
  display_name         = "Require Environment tag on resource groups"
  description          = "Ensures all resource groups have Environment tag for cost allocation"
  management_group_id  = data.azurerm_management_group.root.id
  policy_definition_id = azurerm_policy_definition.require_tag_rg.id

  parameters = jsonencode({
    tagName = {
      value = var.required_tag_name
    }
  })
}


#---------------------------------------------------------
# Policy 3: Deploy Diagnostic Settings for Resource Groups
# Effect: DeployIfNotExists (auto-remediation)
#---------------------------------------------------------
resource "azurerm_policy_definition" "deploy_diag_activity_log" {
  name         = "deploy-activity-log-law"
  display_name = "Audit Activity Log diagnostics to Log Analytics"
  description  = "Audits that the subscription Activity Log streams to the Log Analytics workspace"
  policy_type  = "Custom"
  mode         = "All"

  management_group_id = data.azurerm_management_group.root.id

  metadata = jsonencode({
    category = "Monitoring"
    version  = "2.0.0"
  })

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Resources/subscriptions"
    }
    then = {
      effect = "auditIfNotExists"
      details = {
        type           = "Microsoft.Insights/diagnosticSettings"
        existenceScope = "subscription"
        existenceCondition = {
          allOf = [
            {
              field  = "Microsoft.Insights/diagnosticSettings/workspaceId"
              equals = "[parameters('logAnalyticsWorkspaceId')]"
            }
          ]
        }

      }
    }
  })

  parameters = jsonencode({
    logAnalyticsWorkspaceId = {
      type = "String"
      metadata = {
        displayName = "Log Analytics Workspace ID"
        description = "Full resource ID of the Log Analytics workspace"
      }
    }
  })
}

#---------------------------------------------------------
# Policy Assignment: Deploy Diagnostic Settings
#---------------------------------------------------------
resource "azurerm_management_group_policy_assignment" "deploy_diag_activity_log" {
  name                 = "deploy-activity-law"
  display_name         = "Audit Activity Log diagnostics to Log Analytics"
  description          = "Audits that the subscription Activity Log streams to the Log Analytics workspace"
  management_group_id  = data.azurerm_management_group.root.id
  policy_definition_id = azurerm_policy_definition.deploy_diag_activity_log.id



  parameters = jsonencode({
    logAnalyticsWorkspaceId = {
      value = var.log_analytics_workspace_id
    }
  })
}




