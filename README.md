# Azure Landing Zone

Production-pattern Azure platform foundation built with Terraform, implementing hub-spoke networking, centralised observability, secretless CI/CD authentication, and a governed identity model for workload repositories. This repository owns the platform layer only — it never deploys application workloads.

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Landing%20Zone-0078D4?logo=microsoft-azure)](https://azure.microsoft.com)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)](https://github.com/features/actions)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## What This Is

A production-pattern Azure platform built from scratch — not a template. Every resource is defined in Terraform,every deployment authenticates via OIDC with no stored secrets, and every design decision is documented in an Architecture Decision Record.

This repository owns: hub-spoke networking, Azure Policy governance, centralised observability, secretless CI/CD identity, and workload landing zones. What does not live here: application workloads, container
deployments, AKS clusters, or any compute that serves an application. Those live in workload repositories that consume this platform's outputs via azurerm data sources.

---

## Repository Structure

```
azure-landing-zone/
├── .github/
│   ├── terraform-modules.json        ← module registry for CI/CD pipeline
│   │
│   └── workflows/
│       ├── terraform-matrix-plan.yml     ← PR: parallel plan per changed module
│       ├── terraform-matrix-apply.yml    ← merge: sequential apply in tier order
│       └── drift-detection.yml           ← weekly: drift detection across all modules
│
│── docs/
    ├── adr/                         ← Architecture Decision Records
    |   ├── ADR-001-state-storage.md
    |   ├── ADR-002-hub-spoke-topology.md
    |   ├── ADR-003-workload-identity.md
    |   ├── ADR-004-provider-pinning.md
    ├── architecture.md              ← diagrams and design documentation
│
└── platform/
    ├── bootstrap/                   ← tier 0: state storage, versioning, lock
    │
    ├── connectivity/                ← tier 1: ALL network topology
    │   ├── main.tf                  # hub VNet and subnets
    │   ├── spokes.tf                # workloads and data spoke VNets, rg-taskflow landing zone
    │   ├── peering.tf               # all VNet peerings
    │   ├── nsg.tf                   # all NSGs and rules
    │   ├── udr.tf                   # route tables and associations
    │   ├── diagnostics.tf           # NSG flow logs → law-platform
    │   ├── private-dns.tf           # ephemeral private DNS zones (workload-owned on promotion)
    │   ├── variables.tf
    │   ├── outputs.tf               # every ID workloads will ever need
    │   ├── backend.tf
    │   └── providers.tf
    │
    ├── management/                  ← tier 1: observability, alerts, backup, budgets
    │   ├── main.tf                  # Log Analytics workspace
    │   ├── action-groups.tf         # central alert action group
    │   ├── activity-logs.tf         # subscription Activity Log → law-platform
    │   ├── alerts.tf                # KQL scheduled query alerts
    │   ├── backup.tf                # Recovery Services Vault and VM backup policy
    │   ├── budget.tf                # subscription and workload RG budget alerts
    │   ├── outputs.tf
    │   ├── variables.tf
    │   ├── backend.tf
    │   └── providers.tf
    │
    ├── governance/                  ← tier 2: Azure Policy (manual only)
    │
    ├── identity/
        └── github-oidc/             ← tier 2: OIDC federation for all workloads (manual only)

```

---

## Architecture

### Management Group Hierarchy

Policy assignments at the `moshstaq` management group propagate automatically to all child subscriptions. No per-subscription policy configuration is required.

```
Tenant Root Group
└── moshstaq
    ├── platform      ← shared infrastructure subscriptions
    └── workloads     ← application landing zones
```

### Hub-Spoke Network Topology

## Network Architecture

```
                        Internet
                           │
                  (Ingress / Egress)
                           │
              ┌────────────▼────────────┐
              │  vnet-hub (10.0.0.0/16) │
              │ rg-platform-connectivity│
              │                         │
              │  snet-appgw.            │
              │  snet-NVA               │
              │  snet-shared-services   │
              │                         │
              │  Centralised Routing &  │
              │  Security Enforcement   │
              └────────────┬────────────┘
                           │
                 VNet Peering (Hub-Spoke)
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │

┌─────────────▼────────────┐      ┌────────────▼────────────┐
│ vnet-workloads           │      │ vnet-data               │
│ (10.1.0.0/16)            │      │ (10.2.0.0/16)           │
│ rg-workloads             │      │ rg-data                 │
│                          │      │                         │
│ snet-compute 10.1.1.0/24 │      │ Subnets provisioned     │
│ snet-containers 10.1.3.0 │      │ on demand (PaaS / PE)   │
│ snet-aks 10.1.4.0/22     │      │                         │
│                          │      │                         │
│                          │      │ UDR: 10.1.0.0/16 → NVA  │
│ UDR: 10.2.0.0/16 → NVA   │      │                         │
│ (Forced Tunnelling)      │      │                         │
└──────────────────────────┘      └─────────────────────────┘
```

### Inter-Spoke Routing

All cross-spoke traffic routes through the hub NVA via UDRs on both spoke route tables. Spoke-to-spoke traffic is not transitive through peering alone. AKS internet egress uses NAT Gateway, not the NVA, to avoid a single point of failure on the cluster control plane path.

### Terraform State Strategy

Each module owns an isolated state file in Azure Blob Storage. Modules reference cross-tier outputs via `terraform_remote_state` data sources within this repository. Workload repositories consume platform outputs
via `azurerm` data sources — never via remote state. This keeps state file contents private and safe for consumption from public repositories.

```
tfstate/
├── platform-bootstrap
├── platform-connectivity
├── platform-management
├── platform-governance
├── platform-identity

```

State are protected by blob versioning, soft delete, and a `CanNotDelete` resource lock on `rg-tfstate`.

---

---

## Platform Modules

### bootstrap — Tier 0

Provisions the remote state storage account, container, versioning, soft delete, and the CanNotDelete resource lock on `rg-tfstate`. This module must be applied first and its state is managed locally on first run only. All subsequent modules use the storage account it creates.

### connectivity — Tier 1

Owns all network topology: hub VNet, spoke VNets, subnets, NSGs, UDRs, VNet peerings, and NSG diagnostic settings. Also provisions workload landing zone resource groups — `rg-workloads`, `rg-data`, and `rg-taskflow` — as empty boundaries for workload repositories to deploy into.

The NVA subnet is declared here with no NSG attached. Traffic policy
on that subnet is enforced at the OS level on the NVA appliance.

Key files:

- `main.tf` — hub VNet, subnets including NVA subnet
- `spokes.tf` — spoke VNets, landing zone resource groups
- `peering.tf` — all VNet peerings
- `nsg.tf` — NSGs and rules
- `udr.tf` — route tables and subnet associations
- `diagnostics.tf` — NSG flow logs to law-platform
- `outputs.tf` — all IDs consumed by other modules and workloads

### management — Tier 1

Owns centralised observability and cost management: Log Analytics workspace, action group, activity log diagnostic settings, KQL-based scheduled query alerts, Recovery Services Vault, VM backup policy, and subscription and workload resource group budgets.

Key files:

- `main.tf` — Log Analytics workspace
- `alerts.tf` — three KQL scheduled query alerts
- `action-groups.tf` — central alert action group
- `activity-logs.tf` — subscription activity log forwarding
- `backup.tf` — Recovery Services Vault and VM backup policy
- `budget.tf` — subscription and rg-taskflow budget alerts
- `outputs.tf` — workspace ID and action group ID

### governance — Tier 2 — Manual Only

Manages Azure Policy definitions and assignments at management group scope. Three policies are assigned at the `moshstaq` management group and propagate automatically to all child subscriptions:

| Policy                    | Effect            | Purpose                          |
| ------------------------- | ----------------- | -------------------------------- |
| Require `Environment` tag | Audit             | Flags untagged resource groups   |
| Allowed locations         | Deny              | Restricts deployments to eastus2 |
| Activity Log forwarding   | DeployIfNotExists | Auto-configures audit logging    |

This module is excluded from automated CI. It operates at management group scope, which requires privileges that exceed the least-privilege boundary for a CI service principal. Changes require manual apply by an operator with User Access Administrator at management group scope.
See `docs/adr/ADR-003-workload-identity.md`.

### identity/github-oidc — Tier 2 — Manual Only

Manages all GitHub Actions service principals using `for_each` over a `repos` variable. The platform controls what repositories get Azure access and at what scope. Adding a new workload repository requires a new entry in `terraform.tfvars` and corresponding RBAC in `rbac.tf`.

This module is excluded from automated CI. It manages AAD application registrations and requires Microsoft Graph `Application.Read.All` permission, which represents unacceptable privilege escalation for an automated pipeline. Changes require manual apply by an operator withsufficient Graph permissions.
See `docs/adr/ADR-003-workload-identity.md`.

#### Current Service Principals

| Repository         | Scope                       | Role                          |
| ------------------ | --------------------------- | ----------------------------- |
| azure-landing-zone | rg-platform-connectivity    | Contributor                   |
| azure-landing-zone | rg-platform-management      | Contributor                   |
| azure-landing-zone | rg-workloads                | Contributor                   |
| azure-landing-zone | rg-data                     | Contributor                   |
| azure-landing-zone | rg-tfstate                  | Storage Blob Data Contributor |
| azure-landing-zone | rg-tfstate                  | Reader                        |
| azure-landing-zone | rg-taskflow                 | Reader                        |
| azure-landing-zone | /subscriptions/...          | Monitoring Reader             |
| azure-landing-zone | /subscriptions/...          | Cost Management Reader        |
| azure-landing-zone | moshstaq (management group) | Reader                        |
| taskflow-platform  | rg-taskflow                 | Contributor                   |
| taskflow-platform  | rg-workloads                | Network Contributor           |
| taskflow-platform  | rg-tfstate                  | Storage Blob Data Contributor |
| taskflow-platform  | rg-tfstate                  | Reader                        |

---

## Platform Services

### Governance (Azure Policy)

Three policies applied at management group scope — they propagate automatically to all child subscriptions:

| Policy                    | Effect            | Purpose                        |
| ------------------------- | ----------------- | ------------------------------ |
| Require `environment` tag | Deny              | Prevents untagged resources    |
| Allowed locations         | Deny              | Locks deployments to `eastus2` |
| Activity Log forwarding   | DeployIfNotExists | Auto-configures audit logging  |

The `DeployIfNotExists` effect is the most operationally significant — it auto-remediates non-compliant resources rather than just flagging them.

### Observability

Centralised Log Analytics workspace (`law-platform`) receives:

- NSG flow logs from all connectivity subnets (NetworkSecurityGroupEvent, NetworkSecurityGroupRuleCounter)
- Activity Logs from all subscriptions via the Azure Monitor subscription diagnostic setting

Three KQL-based scheduled query alerts run against this workspace:

| Alert                 | Severity | Frequency | What It Catches            |
| --------------------- | -------- | --------- | -------------------------- |
| Policy non-compliance | Warning  | Hourly    | Governance drift           |
| Deployment failures   | Error    | Hourly    | Failed Terraform applies   |
| NSG deny spike        | Warning  | 15 min    | Unexpected blocked traffic |

All alerts route to a central Action Group (`ag-platform-alerts`) with email notification. Daily quota cap of 1GB on `law-platform` protects against unexpected ingestion cost spikes.

### Backup & Disaster Recovery

A Recovery Services Vault (`rsv-platform`) in `rg-platform-management` provides the backup infrastructure. A daily VM backup policy (bkpol-vm-daily) is provisioned and ready — no VMs are currently registered to it, so cost is $0. Infrastructure defined in Terraform has a built-in DR story: terraform apply rebuilds it. The vault exists for workload data that Terraform cannot recover.

### Authentication

All workflows authenticate via OIDC. The `ARM_USE_OIDC: true` and `ARM_USE_AZUREAD: true` environment variables are set at workflow level. No secrets are stored in GitHub beyond the client ID, tenant ID, and subscription ID — none of which are credentials.

## CI/CD Pipeline

- Backend uses blob lease locking to prevent concurrent apply conflicts. All workflows authenticate via OIDC — no secrets stored in GitHub.

### How It Works

```
PR opened touching platform/**
│
▼
Detect changed modules → terraform-modules.json
│
▼
Matrix Plan — parallel per changed module
│ Posts plan diff as PR comment
▼
Peer review
│
▼
Merge to main
│
▼
Matrix Apply — sequential, tier order enforced
│
▼
Weekly Drift Detection — Covers: connectivity, management. Excluded: governance, github-oidc (manual only)
│ Non-empty plan → GitHub issue opened automatically
```

### Module Registry

All platform modules are ci_enabled: false. The pipeline plans and detects drift — it never auto-applies platform changes. Platform infrastructure changes require explicit human review and manual apply.

Two modules are additionally excluded from drift detection:

| Module               | Reason                                                                           |
| -------------------- | -------------------------------------------------------------------------------- |
| governance           | Requires management group scope privileges exceeding CI least-privilege boundary |
| identity/github-oidc | Requires Microsoft Graph permissions incompatible with CI service principal      |

## Cost Management

This project runs on a £20/month budget. Workloads are deployed for learning, validated, then destroyed.

| Resource                  | Status                           | Monthly Cost  |
| ------------------------- | -------------------------------- | ------------- |
| Storage Account (tfstate) | Permanent                        | £1            |
| Log Analytics Workspace   | Permanent                        | £1            |
| Recovery Services Vault   | No cost until a VM is registered | £0            |
| **Total**                 |                                  | **~£2/month** |

Budget alerts are configured at subscription (£20) and `rg-taskflow` ($15) scope — email notifications at 50%, 80%, 100% actual and a forecasted threshold that warns before the limit lands. The forecasted threshold is the most operationally useful for ephemeral workloads like AKS.

Workloads are deployed for validation and destroyed after completion. This is intentional — it demonstrates cost-aware engineering and keeps focus on the platform layer where the durable value is.

---

## Deployment Order

Modules must be deployed in dependency order:

```bash
# 1. Bootstrap — remote state storage
cd platform/bootstrap && terraform init && terraform apply

# 2. Identity — OIDC service principal and RBAC
cd platform/identity/github-oidc && terraform init && terraform apply

# 3. Platform services — order matters
cd platform/connectivity && terraform init && terraform apply
cd platform/management  && terraform init && terraform apply
cd platform/governance  && terraform init && terraform apply

```

After step 2, connectivity and management changes trigger CI automatically on PR. Governance and github-oidc always require manual apply.

**Variable requirements:** management, governance, and github-oidc require `terraform.tfvars` files with non-sensitive variable values. Sensitive values (`subscription_id`, `tenant_id`) are read automatically
from the `ARM_SUBSCRIPTION_ID` and `ARM_TENANT_ID` environment variables set by the CI workflow — no tfvars entry required for these.

---

## Resource Group Layout

| Resource Group           | Tier         | Purpose                                | Lifecycle                               |
| ------------------------ | ------------ | -------------------------------------- | --------------------------------------- |
| rg-tfstate               | Platform     | Terraform remote state storage         | Permanent                               |
| rg-platform-connectivity | Platform     | Hub VNet, spokes, NSGs                 | Permanent                               |
| rg-platform-management   | Platform     | Log Analytics, alerts, backup, budgets | Permanent                               |
| rg-workloads             | Landing Zone | Workloads spoke VNet                   | Permanent                               |
| rg-data                  | Landing Zone | Data spoke VNet                        | Permanent                               |
| rg-taskflow              | Landing Zone | Empty boundary for taskflow-platform   | Permanent boundary / Ephemeral contents |

---

## Architecture Decision Records

| ADR     | Decision                                                 |
| ------- | -------------------------------------------------------- |
| ADR-001 | Per-module Azure Blob Storage for Terraform remote state |
| ADR-002 | Hub-spoke network topology                               |
| ADR-003 | OIDC workload identity over service principal secrets    |
| ADR-004 | Terraform provider pinning to exact versions             |

Full records in `docs/adr/`.

---

## Related Repositories

| Repository                                                       | Purpose                                         |
| ---------------------------------------------------------------- | ----------------------------------------------- |
| [stratum-platform](https://github.com/moshstaq/stratum-platform) | Multi-cloud platform consumer — not yet created |
| [aws-landing-zone](https://github.com/moshstaq/aws-landing-zone) | AWS platform foundation — not yet created       |

---

## Author

github.com/moshstaq
