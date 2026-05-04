# Azure Landing Zone v2

Enterprise-grade Azure platform foundation built with Terraform, implementing hub-and-spoke networking, centralised observability, secretless CI/CD, and a governed identity model for workload repositories. This repository owns the platform layer only — it never deploys application workloads.

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Landing%20Zone-0078D4?logo=microsoft-azure)](https://azure.microsoft.com)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)](https://github.com/features/actions)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## What This Is

A production-pattern Azure platform built from scratch — not a template. Every resource is defined in Terraform, every deployment runs through GitHub Actions with OIDC authentication, and every design decision mirrors what platform teams do at enterprise scale.

This repository owns: hub-and-spoke networking, Azure Policy governance, centralised observability, secretless CI/CD identity, and workload landing zones. What does not live here: application workloads, container deployments, AKS clusters, or any compute that serves an application. Those live in workload repositories that consume this platform's outputs via remote state.

---

## Architecture

### Management Group Hierarchy

Policy inheritance flows top-down. Governance is enforced at the management group level so individual teams can't opt out.

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

All cross-spoke traffic is forced through the hub NVA via UDRs on both spoke subnets. Spoke-to-spoke traffic is not transitive through peering alone. Asymmetric routing is prevented by design.

Workload landing zones: rg-taskflow is provisioned by this repository as an empty resource group. The taskflow-platform workload repository deploys into it. This is the platform landing zone pattern — the platform provisions the boundary, the workload fills it.

### Terraform State Strategy

Each tier owns its own remote state in Azure Blob Storage. Modules reference cross-tier outputs via `terraform_remote_state` data sources — no hardcoded IDs, no monolithic state file.

```
tfstate/
├── platform-bootstrap
├── platform-connectivity
├── platform-management
├── platform-governance
├── platform-identity

```

A broken workload deployment cannot corrupt platform state. State files are protected by blob versioning, soft delete, and a `CanNotDelete` resource lock on `rg-tfstate`.

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
└── platform/
    ├── bootstrap/                   ← tier 0: state storage, versioning, lock
    │
    ├── connectivity/                ← tier 1: ALL network topology
    │   ├── main.tf                  # hub VNet and subnets
    │   ├── spokes.tf                # workloads and data spoke VNets
    │   ├── peering.tf               # all VNet peerings
    │   ├── nsg.tf                   # all NSGs and rules
    │   ├── udr.tf                   # route tables and associations
    │   ├── diagnostics.tf           # NSG flow logs → law-platform
    │   ├── variables.tf
    │   ├── outputs.tf               # every ID workloads will ever need
    │   ├── backend.tf
    │   └── versions.tf
    │
    ├── management/                  ← tier 1: observability, budgets, backup
    │
    ├── governance/                  ← tier 2: Azure Policy
    │
    ├── identity/
    │   └── github-oidc/             ← tier 2: OIDC federation for all workloads

```

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

- NSG flow logs from all connectivity subnets
- Activity Logs from all subscriptions via the Azure Monitor subscription diagnostic setting
- AKS telemetry from workload repositories (planned)

Three KQL-based scheduled query alerts run against this workspace:

| Alert                 | Severity | Frequency | What It Catches            |
| --------------------- | -------- | --------- | -------------------------- |
| Policy non-compliance | Warning  | Hourly    | Governance drift           |
| Deployment failures   | Error    | Hourly    | Failed Terraform applies   |
| NSG deny spike        | Warning  | 15 min    | Unexpected blocked traffic |

All alerts route to a central Action Group (`ag-platform-alerts`) with email notification. The Action Group ID is exposed as a Terraform output so workload modules can reference it via remote state without hardcoding.

Daily quota cap of 1GB on `law-platform` protects against unexpected ingestion cost spikes.

### Identity & Authentication

No stored secrets anywhere. GitHub Actions authenticates to Azure via OIDC federated credentials. The platform/identity/github-oidc module manages all workload service principals using for_each — the platform is the gatekeeper for what repositories get Azure access and at what scope.

#Current Service Principals Managed by This Module

| Repository         | Scope                                                                   | Role                |
| ------------------ | ----------------------------------------------------------------------- | ------------------- |
| azure-landing-zone | rg-platform-connectivity, rg-workloads, rg-data, rg-platform-management | Contributor         |
| taskflow-platform  | rg-taskflow                                                             | Contributor         |
| taskflow-platform  | snet-aks                                                                | Network Contributor |

Adding a new workload repository requires a new entry in `terraform.tfvars` and RBAC defined in `rbac.tf`. The platform team controls it. The workload team consumes it.

## CI/CD Pipeline

- Backend uses blob lease locking to prevent concurrent apply conflicts. All workflows authenticate via OIDC — no secrets stored in GitHub.

### How It Works

```
PR opened touching platform/\*\*
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
Weekly Drift Detection — all modules
│ Non-empty plan → GitHub issue opened automatically
```

All platform modules are ci_enabled: false. The pipeline plans and detects drift — it never auto-applies platform changes. Platform infrastructure changes require explicit human review and manual apply.

### Design Decisions

NVA over Azure Firewall — cost and routing visibility. The NVA handles east-west spoke-to-spoke traffic only. AKS internet egress uses NAT Gateway, not the NVA, to avoid a single point of failure on the cluster's control plane path.
Manual apply for platform modules — platform changes are sensitive. Connectivity, governance, and identity mistakes are hard to recover from. Speed is not the priority here.

Landing zone pattern for workloads — platform/connectivity provisions empty resource groups for each workload. The workload repo deploys into the RG it has been handed. This maintains a clean `platform/workload` boundary and prevents workload pipelines from needing access to platform resource groups.

`for_each` for OIDC service principals — all GitHub Actions SPs are managed in one place. Adding a new workload is a three-file change: `spokes.tf, rbac.tf`, and `terraform.tfvars`.

## Cost Management

This project runs on a $20/month budget. Workloads are deployed for learning, validated, then destroyed.

| Resource                  | Status                           | Monthly Cost  |
| ------------------------- | -------------------------------- | ------------- |
| Storage Account (tfstate) | Permanent                        | $1            |
| Log Analytics Workspace   | Permanent                        | $1            |
| Recovery Services Vault   | No cost until a VM is registered | $0            |
| **Total**                 |                                  | **~$2/month** |

Budget alerts configured at subscription ($20) and resource group ($15) level — email notifications at 50%, 80%, 100% actual and forecasted thresholds.

Destroying workloads after validation is intentional — demonstrates cost-aware engineering and keeps focus on the platform layer where the durable value is.

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

After step 2, subsequent deployments run automatically via GitHub Actions on PR and merge.

---

## Related Repositories

| Repository          | Purpose                                                                                        |
| ------------------- | ---------------------------------------------------------------------------------------------- |
| `taskflow-platform` | EContainerised task processing platform on AKS. Consumes platform networking via remote state. |

## Author

github.com/moshstaq
