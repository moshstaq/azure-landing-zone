#---------------------------------------------------------
# Data Source: Management Group for Policy Assignment
#---------------------------------------------------------
data "azurerm_management_group" "root" {
  name = "moshstaq"
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
  display_name = "Deploy Activity Log diagnostics to Log Analytics"
  description  = "Automatically configures Activity Log to stream to Log Analytics workspace"
  policy_type  = "Custom"
  mode         = "All"

  management_group_id = data.azurerm_management_group.root.id

  metadata = jsonencode({
    category = "Monitoring"
    version  = "1.0.0"
  })

  policy_rule = jsonencode({
    if = {
      field  = "type"
      equals = "Microsoft.Resources/subscriptions"
    }
    then = {
      effect = "deployIfNotExists"
      details = {
        type            = "Microsoft.Insights/diagnosticSettings"
        deploymentScope = "subscription"
        existenceScope  = "subscription"
        existenceCondition = {
          allOf = [
            {
              field  = "Microsoft.Insights/diagnosticSettings/workspaceId"
              equals = "[parameters('logAnalyticsWorkspaceId')]"
            }
          ]
        }
        roleDefinitionIds = [
          "/providers/Microsoft.Authorization/roleDefinitions/749f88d5-cbae-40b8-bcfc-e573ddc772fa",
          "/providers/Microsoft.Authorization/roleDefinitions/92aaf0da-9dab-42b6-94a3-d43ce8d16293"
        ]
        deployment = {
          location = "eastus2"
          properties = {
            mode = "incremental"
            template = {
              "$schema"      = "https://schema.management.azure.com/schemas/2018-05-01/subscriptionDeploymentTemplate.json#"
              contentVersion = "1.0.0.0"
              parameters = {
                logAnalyticsWorkspaceId = {
                  type = "string"
                }
              }
              resources = [
                {
                  type       = "Microsoft.Insights/diagnosticSettings"
                  apiVersion = "2021-05-01-preview"
                  name       = "activity-log-to-law"
                  properties = {
                    workspaceId = "[parameters('logAnalyticsWorkspaceId')]"
                    logs = [
                      {
                        category = "Administrative"
                        enabled  = true
                      },
                      {
                        category = "Security"
                        enabled  = true
                      },
                      {
                        category = "Policy"
                        enabled  = true
                      }
                    ]
                  }
                }
              ]
            }
            parameters = {
              logAnalyticsWorkspaceId = {
                value = "[parameters('logAnalyticsWorkspaceId')]"
              }
            }
          }
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
  display_name         = "Deploy Activity Log to Log Analytics"
  description          = "Automatically configures subscription Activity Log diagnostics"
  management_group_id  = data.azurerm_management_group.root.id
  policy_definition_id = azurerm_policy_definition.deploy_diag_activity_log.id
  location             = "eastus2"

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    logAnalyticsWorkspaceId = {
      value = var.log_analytics_workspace_id
    }
  })
}


#---------------------------------------------------------
# Role Assignment: Allow Policy to Deploy Diagnostic Settings
#---------------------------------------------------------
data "azurerm_subscription" "current" {}

resource "azurerm_role_assignment" "policy_monitoring_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Monitoring Contributor"
  principal_id         = azurerm_management_group_policy_assignment.deploy_diag_activity_log.identity[0].principal_id
}

resource "azurerm_role_assignment" "policy_law_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Log Analytics Contributor"
  principal_id         = azurerm_management_group_policy_assignment.deploy_diag_activity_log.identity[0].principal_id
}
