**Session Focus:** Monitoring & Alerting

---

## 1. Platform Monitoring — Completed

### Action Group

- Created `ag-platform-alerts` in `rg-platform-management`
- Email receiver: platform team
- Exposed `action_group_id` as Terraform output for workload modules to consume via remote state

### KQL-Based Scheduled Query Alerts

Three alerts deployed against `law-platform`:

| Alert                           | Severity | Frequency | Query Target                        |
| ------------------------------- | -------- | --------- | ----------------------------------- |
| `alert-policy-noncompliance`    | Warning  | PT1H      | AzureActivity — Policy failures     |
| `alert-terraform-apply-failure` | Error    | PT1H      | AzureActivity — Deployment failures |
| `alert-nsg-deny-spike`          | Warning  | PT15M     | AzureDiagnostics — NSG block events |

**Note:** Alerts are built and live but not yet fully validated with real data — NSG diagnostic settings and full Log Analytics ingestion not wired up yet. Revisit during Week 18 wrap-up.

---
