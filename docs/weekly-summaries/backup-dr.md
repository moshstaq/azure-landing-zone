# Work Notes — Weeks 18-20

**Date:** 28 February 2026
**Session Focus:** Monitoring wrap-up, Disaster Recovery, Backup, Cost Management

---

## Week 18 — Monitoring & Alerting Wrap-up

### Problem

Log Analytics workspace `law-platform` had been provisioned since Week 5 but receiving zero data. Platform alerts existed but had nothing to query. Root cause — no diagnostic settings wired up to send data to the workspace.

### What Was Missing

Two categories of data needed wiring:

1. **NSG flow logs** — `NetworkSecurityGroupEvent` and `NetworkSecurityGroupRuleCounter` from both spoke NSGs
2. **Azure Activity Logs** — subscription-level events feeding `AzureActivity` table

### NSG Diagnostic Settings

Added `diagnostics.tf` to `landing-zones/app-dev/networking/`:

```hcl
resource "azurerm_monitor_diagnostic_setting" "nsg_aks" {
  name                       = "diag-nsg-app-dev-aks"
  target_resource_id         = azurerm_network_security_group.aks.id
  log_analytics_workspace_id = local.law_workspace_id

  enabled_log { category = "NetworkSecurityGroupEvent" }
  enabled_log { category = "NetworkSecurityGroupRuleCounter" }
}
```

Log Analytics workspace ID pulled via remote state from `platform/management` — follows the same pattern as connectivity outputs. No hardcoded resource IDs.

Applied to both NSGs:

- `nsg-app-dev-aks`
- `nsg-app-dev-containers`

### Activity Log Forwarding

Added `activity-logs.tf` to `platform/management/`:

```hcl
resource "azurerm_monitor_diagnostic_setting" "activity_logs" {
  name                       = "diag-activity-logs-to-law"
  target_resource_id         = data.azurerm_subscription.current.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.platform.id
  ...
}
```

Target resource is the subscription itself — all eight Activity Log categories forwarded:

- Administrative ← feeds `alert-terraform-apply-failure`
- Policy ← feeds `alert-policy-noncompliance`
- Security, ServiceHealth, Alert, Recommendation, Autoscale, ResourceHealth

### Validation

Queried `AzureActivity` table immediately after apply:

```
CategoryValue    Count
Administrative   2
```

Two events visible — the two `terraform apply` operations that created the diagnostic settings. Data flowing confirmed.

### Cost Implication

Activity Logs and NSG flow logs both fall within the free 5GB/month Log Analytics ingestion tier. Lab environment generates <100MB/month. Effective cost: **$0**.

### Alert Query Status

- `alert-policy-noncompliance` — wired, Policy events will appear on next governed deployment
- `alert-terraform-apply-failure` — wired, Administrative events confirmed flowing
- `alert-nsg-deny-spike` — wired, NetworkSecurityGroupRuleCounter flows when NSGs active

---

## Week 19 — Disaster Recovery & Backup

### DR Philosophy for IaC-Based Infrastructure

Infrastructure defined as code has a fundamentally different DR story than traditional environments. If everything in Azure was deleted, `terraform apply` rebuilds it. That _is_ the DR strategy for infrastructure.

What Terraform cannot recover is data. DR focus therefore is:

```
What needs protection?
├── Terraform state files    ← losing these is catastrophic
├── Key Vault secrets        ← protected by soft delete
├── Log Analytics data       ← controlled by retention policy
└── Workload data            ← ephemeral in lab, not applicable
```

### Terraform State Protection

Added to `platform/bootstrap/main.tf`:

**Blob versioning:**

```hcl
blob_properties {
  versioning_enabled = true
  ...
}
```

Every `terraform apply` overwrites the state file. Versioning retains all previous versions. If state gets corrupted, roll back to any previous version.

**Container soft delete:**

```hcl
container_delete_retention_policy {
  days = 7
}
```

Accidentally deleted containers recoverable within 7 days.

**Resource lock:**

```hcl
resource "azurerm_management_lock" "tfstate" {
  name       = "lock-tfstate-rg"
  scope      = azurerm_resource_group.tfstate.id
  lock_level = "CanNotDelete"
  notes      = "Protects Terraform state storage from accidental deletion"
}
```

Prevents deletion of `rg-tfstate` even with Contributor access. Must be explicitly removed before the resource group can be deleted.

**Verification:**

```
Versioning:           true
BlobSoftDelete:       enabled, 7 days
ContainerSoftDelete:  enabled, 7 days
Lock:                 CanNotDelete on rg-tfstate
```

### Log Analytics Controls

Updated `platform/management/main.tf`:

```hcl
resource "azurerm_log_analytics_workspace" "platform" {
  retention_in_days = 30      # explicit, was defaulting
  daily_quota_gb    = 1       # was -1 (unlimited) — cost risk
}
```

Daily quota cap at 1GB protects against unexpected ingestion spikes. Without this, a misconfigured diagnostic setting could generate GBs of logs and an unexpected bill.

### Recovery Services Vault

Added `platform/management/backup.tf`:

```hcl
resource "azurerm_recovery_services_vault" "platform" {
  name              = "rsv-platform"
  sku               = "Standard"
  soft_delete_enabled = true
  storage_mode_type = "LocallyRedundant"   # GeoRedundant is default — more expensive
}
```

Note: Azure defaults to `GeoRedundant` storage for Recovery Services Vaults. Explicitly set to `LocallyRedundant` for lab cost discipline.

**VM Backup Policy:**

```hcl
resource "azurerm_backup_policy_vm" "daily" {
  backup { frequency = "Daily", time = "02:00" }
  retention_daily   { count = 7  }
  retention_weekly  { count = 4, weekdays = ["Sunday"] }
  retention_monthly { count = 3, weekdays = ["Sunday"], weeks = ["First"] }
}
```

Policy exists and is ready — no VMs currently registered to it. Cost is $0 until a VM is protected.

### Cost Implication

- Blob versioning: ~$0.0003/month for lab state file sizes
- Resource lock: free
- Log Analytics quota cap: free (protective only)
- Recovery Services Vault with no protected items: free
- **Total: effectively $0**

---

## Week 20 — Cost Management & Budget Alerts

### Baseline

- Current month spend: ~$20
- No budgets configured — no automated alerts on spending

### Budgets Built

Added `platform/management/budgets.tf`:

**Subscription budget — $20:**

| Threshold | Type       | Amount        | Action                               |
| --------- | ---------- | ------------- | ------------------------------------ |
| 50%       | Actual     | $10           | Early warning — check what's running |
| 80%       | Actual     | $16           | Review and plan destruction          |
| 100%      | Actual     | $20           | Limit reached                        |
| 110%      | Forecasted | $22 projected | Destroy before it lands              |

**rg-app-dev budget — $15:**

| Threshold | Type       | Amount        | Action                          |
| --------- | ---------- | ------------- | ------------------------------- |
| 80%       | Actual     | $12           | AKS sessions consuming budget   |
| 100%      | Actual     | $15           | RG limit reached                |
| 120%      | Forecasted | $18 projected | Destroy ephemeral resources now |

### Why Two Budgets

The subscription budget is the overall safety net. The `rg-app-dev` budget is tighter because that's where expensive ephemeral resources run. AKS at ~$10/day and App Gateway at ~$7/day can consume $15 in a single session if left running.

The Forecasted threshold is the most valuable — it warns before the limit is hit based on current spend trajectory, giving time to destroy resources before the bill lands.

### Alert Delivery

All notifications sent to `mosh_shood@hotmail.com` via the budget notification system. Independent of the Action Group used for platform alerts — budget alerts are a Cost Management feature, not Azure Monitor.

---

## Private Endpoint — Storage Account (Completed Earlier)

Already built in `landing-zones/app-dev/workloads/storage/`:

**Complete implementation:**

- `azurerm_private_endpoint.blob` — NIC in `snet-data` (10.1.2.0/24)
- `azurerm_private_dns_zone.blob` — `privatelink.blob.core.windows.net`
- `azurerm_private_dns_zone_virtual_network_link.blob` — linked to `vnet-app-dev`
- `azurerm_private_dns_a_record.blob` — maps storage FQDN to private IP
- `azurerm_storage_account_network_rules.main` — `default_action = "Deny"`
- `public_network_access_enabled = false` — public endpoint blocked
- `depends_on = [azurerm_storage_container.uploads]` — prevents race condition where firewall locks Terraform out before container is created

**Traffic flow:**

```
Resource in snet-app / snet-data
    │
    │  DNS resolves stappdev.blob.core.windows.net
    ▼
privatelink.blob.core.windows.net → 10.1.2.x (private IP)
    │
    │  Private Link
    ▼
Storage Account — public access blocked
```

---

## Files Modified This Session

| File                                              | Change                                                     |
| ------------------------------------------------- | ---------------------------------------------------------- |
| `landing-zones/app-dev/networking/diagnostics.tf` | New — NSG diagnostic settings                              |
| `platform/management/activity-logs.tf`            | New — subscription Activity Log forwarding                 |
| `platform/management/main.tf`                     | Updated — Log Analytics retention and quota cap            |
| `platform/management/backup.tf`                   | New — Recovery Services Vault and VM backup policy         |
| `platform/management/budgets.tf`                  | New — subscription and RG budget alerts                    |
| `platform/bootstrap/main.tf`                      | Updated — versioning, container soft delete, resource lock |

---

## Permanently Running Resources Added

| Resource                        | Monthly Cost      |
| ------------------------------- | ----------------- |
| NSG diagnostic settings (x2)    | ~$0               |
| Activity Log diagnostic setting | ~$0               |
| Recovery Services Vault         | ~$0               |
| Budget alerts (x2)              | Free              |
| Log Analytics quota cap         | Free (protective) |
| Resource lock on rg-tfstate     | Free              |

---

## Key Concepts Covered

**Diagnostic settings** — the bridge between Azure resources and Log Analytics. Without them the workspace exists but receives nothing. Every resource that should be monitored needs an explicit diagnostic setting pointing to the workspace.

**Subscription-scoped diagnostic setting** — `target_resource_id` set to the subscription ID captures Activity Logs for the entire subscription. This is different from resource-level diagnostic settings which target individual resources.

**Blob versioning vs soft delete** — soft delete recovers deleted blobs. Versioning recovers overwritten blobs. Both are needed for complete state file protection. Versioning is the more important one for Terraform state since state files are overwritten on every apply, not deleted.

**Resource lock** — `CanNotDelete` prevents deletion but allows modification. `ReadOnly` prevents both. For a state storage account, `CanNotDelete` is appropriate — you still need to write state files.

**Recovery Services Vault storage mode** — Azure defaults to `GeoRedundant` which replicates backup data to a paired region. `LocallyRedundant` keeps data in one region and is significantly cheaper. Always set explicitly in Terraform to avoid unexpected GRS costs.

**Budget forecasted threshold** — more valuable than actual thresholds for ephemeral workloads. Warns based on projected spend before the limit is hit, giving time to act.

**Daily quota cap on Log Analytics** — `-1` means unlimited ingestion. A misconfigured diagnostic setting sending verbose logs could generate GBs of data and an unexpected bill. Always set an explicit cap in lab environments.
