# ─────────────────────────────────────────────────────
# Data — current subscription
# ─────────────────────────────────────────────────────
data "azurerm_subscription" "budget" {}

# ─────────────────────────────────────────────────────
# Subscription-level budget
# Monthly limit with tiered alert thresholds
# ─────────────────────────────────────────────────────

locals {
  budget_start_date = formatdate("YYYY-MM-01'T'00:00:00Z", timestamp())
}
resource "azurerm_consumption_budget_subscription" "monthly" {
  name            = "budget-sub-monthly"
  subscription_id = data.azurerm_subscription.budget.id

  amount     = 20
  time_grain = "Monthly"

  time_period {
    start_date = local.budget_start_date
  }

  # 50% threshold — early warning
  notification {
    enabled        = true
    threshold      = 50
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_emails = [var.alert_email]
  }

  # 80% threshold — approaching limit
  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_emails = [var.alert_email]
  }

  # 100% threshold — limit reached
  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_emails = [var.alert_email]
  }

  # 110% forecasted — projected to exceed
  notification {
    enabled        = true
    threshold      = 110
    operator       = "GreaterThan"
    threshold_type = "Forecasted"

    contact_emails = [var.alert_email]
  }
}

# ─────────────────────────────────────────────────────
# Resource group budget — taskflow workloads
# Tighter limit on the workload RG where
# ephemeral expensive resources run (AKS, App Gateway)
# ─────────────────────────────────────────────────────
resource "azurerm_consumption_budget_resource_group" "taskflow" {
  name              = "budget-rg-taskflow-monthly"
  resource_group_id = "/subscriptions/${data.azurerm_subscription.budget.subscription_id}/resourceGroups/rg-taskflow"

  amount     = 15
  time_grain = "Monthly"

  time_period {
    start_date = local.budget_start_date
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    threshold_type = "Actual"

    contact_emails = [var.alert_email]
  }

  notification {
    enabled        = true
    threshold      = 120
    operator       = "GreaterThan"
    threshold_type = "Forecasted"

    contact_emails = [var.alert_email]
  }
}
