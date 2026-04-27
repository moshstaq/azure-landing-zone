# Azure Landing Zone v2

Enterprise-grade Azure infrastructure built with Terraform, implementing Cloud Adoption Framework (CAF) landing zone patterns. Built as a hands-on learning project to demonstrate platform engineering skills across governance, networking, identity, observability, and CI/CD automation. This repository owns the platform foundation

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Landing%20Zone-0078D4?logo=microsoft-azure)](https://azure.microsoft.com)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)](https://github.com/features/actions)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## What This Is

A production-pattern Azure Landing Zone built from scratch — not a template. Every resource is defined in Terraform, every deployment runs through GitHub Actions, and every design decision mirrors what platform teams do at enterprise scale.

This covers the full platform stack: management group hierarchy, hub-spoke networking, Azure Policy governance, centralised observability, secretless CI/CD via OIDC,and cost management.

What does not live here: application workloads, container deployments, AKS clusters, storage accounts, or any compute that serves an application. Those live in workload repositories that consume this platform's outputs.
The companion workload repository is azure-app-dev.

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

                        Internet
                           │
                  (Ingress / Egress)
                           │
              ┌────────────▼────────────┐
              │  vnet-hub (10.0.0.0/16) │
              │  rg-platform-connectivity│
              │                         │
              │  snet-ingress           │ → App Gateway (L7)
              │  snet-firewall          │ → NVA / Azure Firewall
              │  snet-shared-services   │ → Bastion, DNS, Private Endpoints
              │                         │
              │  Centralised Routing &  │
              │  Security Enforcement   │
              └────────────┬────────────┘
                           │
                 VNet Peering (Hub-Spoke)
                           │
        ┌──────────────────┴──────────────────┐
        │                                     │

┌─────────────▼────────────┐ ┌────────────▼────────────┐
│ vnet-workloads │ │ vnet-data │
│ (10.1.0.0/16) │ │ (10.2.0.0/16) │
│ rg-workloads │ │ rg-data │
│ │ │ │
│ snet-compute 10.1.1.0/24 │ │ Subnets provisioned │
│ snet-containers 10.1.3.0 │ │ on demand (PaaS / PE) │
│ snet-aks 10.1.4.0/22 │ │ │
│ │ │ │
│ │ │ UDR: 10.1.0.0/16 → NVA │
│ UDR: 10.2.0.0/16 → NVA │ │ │
│ (Forced Tunnelling) │ │ │
└──────────────────────────┘ └─────────────────────────┘

Inter-Spoke Routing
Spoke-to-spoke traffic is not transitive through peering alone. All cross-spoke traffic is forced through the hub NVA via UDRs on both spoke subnets. Both directions route through the NVA — asymmetric routing is prevented by design.

## Security Model

- Trust boundaries
- Identity flow
- Network isolation assumptions

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

A broken workload deployment cannot corrupt platform state. Blast radius is scoped to the module. State files are protected by blob versioning, soft delete, and a `CanNotDelete` resource lock on `rg-tfstate`.

---

## Repository Structure

azure-landing-zone/
├── .github/
│ ├── terraform-modules.json # module registry for CI/CD pipeline
│ │
│ └── workflows/
│ ├── terraform-matrix-plan.yml # PR: parallel plan per changed module
│ ├── terraform-matrix-apply.yml # merge: sequential apply in tier order
│ └── drift-detection.yml # weekly: drift detection across all modules
│
└── platform/
├── bootstrap/ # tier 0: state storage, versioning, lock
│
├── connectivity/ # tier 1: ALL network topology
│ ├── main.tf # hub VNet and subnets
│ ├── spokes.tf # workload + data VNets
│ ├── peering.tf # VNet peerings
│ ├── nsg.tf # NSGs and rules
│ ├── udr.tf # route tables + associations
│ ├── diagnostics.tf # NSG flow logs → law-platform
│ ├── variables.tf
│ ├── outputs.tf # exposes IDs for downstream use
│ ├── backend.tf
│ └── versions.tf
│
├── management/ # tier 1: observability, budgets, backup
│
├── governance/ # tier 2: Azure Policy
│
├── identity/
│ └── github-oidc/ # tier 2: OIDC for this + workload repos
│
└── nva/ # tier 2: hub NVA VM (ci_enabled: false)

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

- Azure Activity Logs — all eight categories at subscription scope
- NSG flow logs — `NetworkSecurityGroupEvent` and `NetworkSecurityGroupRuleCounter` from all spoke NSGs
- AKS telemetry — OMS agent wired to `law-platform` via Terraform

Three KQL-based scheduled query alerts run against this workspace:

| Alert                 | Severity | Frequency | What It Catches            |
| --------------------- | -------- | --------- | -------------------------- |
| Policy non-compliance | Warning  | Hourly    | Governance drift           |
| Deployment failures   | Error    | Hourly    | Failed Terraform applies   |
| NSG deny spike        | Warning  | 15 min    | Unexpected blocked traffic |

All alerts route to a central Action Group (`ag-platform-alerts`) with email notification. The Action Group ID is exposed as a Terraform output so workload modules can reference it via remote state without hardcoding.

Daily quota cap of 1GB on `law-platform` protects against unexpected ingestion cost spikes.

### Identity & Authentication

No stored secrets anywhere in this repository. GitHub Actions authenticates to Azure via OIDC federated credentials:

```
GitHub Actions Runner
       │
       │  JWT token (short-lived, audience: api://AzureADTokenExchange)
       ▼
Azure AD App Registration
       │
       │  Access token scoped to specific resource groups
       ▼
Azure Resource Manager
```

The service principal has scoped RBAC — Contributor on workload resource groups, Reader on platform resource groups. Not broad subscription-level access.

## CI/CD Pipeline

- Backend uses blob lease locking to prevent concurrent apply conflicts

### How It Works

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

### Key Design Decisions

All platform modules are ci_enabled: false. Platform infrastructure is sensitive. Connectivity, governance, and identity changes require explicit human review and manual apply. The pipeline plans and detects drift — it never auto-applies platform changes.

Sequential apply, tier-ordered. Bootstrap before connectivity. Connectivity before governance. Tier order is enforced by the pipeline, not assumed.

Drift detection raises GitHub issues. A weekly scheduled plan across all modules surfaces any divergence between declared state and real infrastructure. The issue body contains the full plan output and three resolution options: accept, correct, or investigate.

Independent pipelines per repository. This repository's pipeline only touches platform/**. The azure-app-dev pipeline only touches workloads/**. A workload change never triggers a platform plan.

## Design Trade-offs

- NVA vs Azure Firewall → chose NVA for cost and learning visibility
- Manual apply vs full automation → prioritised safety over speed

---

## Cost Management

This project runs on a $20/month budget. Workloads are deployed for learning, validated, then destroyed.

| Resource                  | Status                           | Monthly Cost  |
| ------------------------- | -------------------------------- | ------------- |
| Storage Account (tfstate) | ✅ Permanent                     | $1            |
| Log Analytics Workspace   | ✅ Permanent                     | $1            |
| Recovery Services Vault   | No cost until a VM is registered | $0            |
| Private DNS Zones (hub)   | Provision On demand              | $0            |
| **Total**                 |                                  | **~$2/month** |

Budget alerts configured at subscription ($20) and resource group ($15) level — email notifications at 50%, 80%, 100% actual and forecasted thresholds.

Destroying workloads after validation is intentional — demonstrates cost-aware engineering and keeps focus on the platform layer where the durable value is.

---

## Skills Demonstrated

**Terraform** — remote state, cross-module data sources, output chaining, `for_each` for scalable resource creation, `depends_on` for explicit dependency ordering, provider configuration, lifecycle rules

**Azure Networking** — hub-spoke VNet topology, NSG rules and associations, VNet peering

**Identity & Security** — OIDC federated credentials, managed identities, RBAC least-privilege scoping, Key Vault RBAC authorisation, workload identity token exchange flow

**Governance** — Management Group hierarchy, Azure Policy (Deny + DeployIfNotExists), policy inheritance, tag enforcement

**Observability** — Log Analytics KQL queries, scheduled query alerts, Action Groups, diagnostic settings (resource and subscription scope), NSG flow logs, Activity Log forwarding

**CI/CD** — GitHub Actions matrix strategy, OIDC secretless authentication, artifact passing, PR comment automation, drift detection, environment protection gates, `ci_enabled` module flag

**Disaster Recovery** — blob versioning, soft delete, resource locks, Recovery Services Vault, backup policies

**Cost Management** — budget alerts with tiered thresholds, forecasted spend alerts, daily quota caps, ephemeral workload discipline

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

Repository Purpose Consumes azure-landing-zone Platform foundation (this repo) - azure-app-dev Workload deployments platform-connectivity.tfstate

## Author

github.com/moshstaq
