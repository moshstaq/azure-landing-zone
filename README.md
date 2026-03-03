# Azure Landing Zone

Enterprise-grade Azure infrastructure built with Terraform, implementing Cloud Adoption Framework (CAF) landing zone patterns. Built as a hands-on learning project to demonstrate platform engineering skills across governance, networking, identity, observability, and CI/CD automation.

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Landing%20Zone-0078D4?logo=microsoft-azure)](https://azure.microsoft.com)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)](https://github.com/features/actions)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## What This Is

A production-pattern Azure Landing Zone built from scratch — not a template, not a wizard. Every resource is defined in Terraform, every deployment runs through GitHub Actions, and every design decision mirrors what platform teams do at enterprise scale.

This covers the full platform stack: management group hierarchy, hub-spoke networking with Application Gateway ingress, Azure Policy governance, centralised observability, secretless CI/CD via OIDC, AKS with workload identity, Private Endpoints with centralised hub DNS, disaster recovery, and cost management.

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

```
Hub VNet (10.0.0.0/16)                    Spoke VNet (10.1.0.0/16)
├── snet-shared-services (10.0.1.0/24)    ├── snet-app (10.1.1.0/24)
├── snet-appgw (10.0.2.0/24)             ├── snet-data (10.1.2.0/24)  ← Private Endpoints
│                                         ├── snet-containers (10.1.3.0/24)
│                                         └── snet-aks (10.1.4.0/22)
└──────────────── VNet Peering ───────────┘
```

Internet traffic enters via Application Gateway in the hub — never directly into spoke subnets. NSGs enforce this boundary explicitly. The `snet-aks` NSG allows inbound only from `10.0.0.0/16` (hub), blocking all direct internet access.

### Traffic Flow — Internet to AKS Workloads

```
Internet
    │
    ▼
Application Gateway (hub - snet-appgw)
    │  AGIC manages backend pool dynamically
    ▼
VNet Peering
    │
    ▼
NGINX Ingress / AGIC (system node pool)
    │
    ▼
Application pods (workload node pool)
    │  Secrets fetched via workload identity
    ▼
Azure Key Vault
```

### Terraform State Strategy

Each tier owns its own remote state in Azure Blob Storage. Modules reference cross-tier outputs via `terraform_remote_state` data sources — no hardcoded IDs, no monolithic state file.

```
tfstate/
├── platform-bootstrap
├── platform-connectivity
├── platform-management
├── platform-governance
├── platform-identity
└── lz-app-dev-networking
    lz-app-dev-keyvault
    lz-app-dev-storage
    lz-app-dev-vm
    lz-app-dev-aci
    lz-app-dev-container-apps
    lz-app-dev-aks
```

A broken workload deployment cannot corrupt platform state. Blast radius is scoped to the module. State files are protected by blob versioning, soft delete, and a `CanNotDelete` resource lock on `rg-tfstate`.

---

## Repository Structure

```
azure-landing-zone/
├── .github/
│   ├── terraform-modules.json          ← module registry for matrix CI/CD
│   └── workflows/
│       ├── terraform-matrix-plan.yml   ← PR plan with parallel matrix
│       ├── terraform-matrix-apply.yml  ← sequential apply on merge
│       └── drift-detection.yml         ← weekly scheduled drift check
├── platform/
│   ├── bootstrap/        ← remote state storage, versioning, resource lock
│   ├── connectivity/     ← hub VNet, subnets, Private DNS zones (hub pattern)
│   ├── management/       ← Log Analytics, alerts, backup vault, budgets
│   ├── governance/       ← Azure Policy definitions and assignments
│   └── identity/
│       └── github-oidc/  ← App Registration, federated credentials, RBAC
└── landing-zones/
    └── app-dev/
        ├── networking/   ← spoke VNet, subnets, NSGs, peering, diagnostic settings
        └── workloads/
            ├── compute/
            │   ├── aci/             ← Azure Container Instances
            │   ├── container-apps/  ← Container Apps + monitoring
            │   ├── vm/              ← Virtual Machines
            │   └── aks/             ← AKS, AGIC, workload identity, Key Vault CSI
            ├── storage/             ← Storage Account, Private Endpoint, Private Link
            └── security/
                └── keyvault/        ← Key Vault, RBAC, secrets
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

### AKS — Workload Identity & Key Vault Integration

AKS cluster (`aks-app-dev`) uses Azure CNI — pod IPs come directly from the VNet address space enabling direct NSG enforcement at pod level.

Workload identity replaces Kubernetes Secrets for sensitive values:

```
Pod (nginx-demo-sa service account)
    │
    │  OIDC projected service account token
    ▼
Azure AD — validates federated credential subject claim
    │  system:serviceaccount:default:nginx-demo-sa
    ▼
Managed Identity (mi-aks-nginx-demo)
    │  Key Vault Secrets User role
    ▼
Azure Key Vault — secret fetched at pod startup
    │
    ▼
CSI Secrets Store — syncs to Kubernetes secret
    │
    ▼
Pod env var — DB_PASSWORD injected at runtime
```

No credentials stored in the cluster. Federated credential subject is scoped to a specific service account — other pods in the cluster cannot assume the identity.

### Application Gateway — Hub Ingress Pattern

Application Gateway lives in the hub VNet (`snet-appgw 10.0.2.0/24`). AGIC (Application Gateway Ingress Controller) runs inside AKS and watches Kubernetes Ingress resources — when an Ingress is created or updated, AGIC automatically updates the Application Gateway backend pool via the Azure API. No hardcoded backend IPs.

Traffic path:

```
Internet → Application Gateway (hub) → VNet Peering → Pods (spoke)
```

Direct internet access to spoke subnets is blocked by NSG — the hub is the only entry point.

### Private Endpoints & DNS

Storage accounts connect to the spoke VNet via Private Link:

- Private Endpoint NIC deployed in `snet-data` (10.1.2.0/24)
- `public_network_access_enabled = false` — public endpoint blocked
- `default_action = "Deny"` on network rules — all traffic via private endpoint
- `depends_on` on storage container — prevents firewall locking Terraform out mid-apply

Centralised Private DNS zones defined in hub (`platform/connectivity/private-dns.tf`):

| Zone                                | Service            |
| ----------------------------------- | ------------------ |
| `privatelink.blob.core.windows.net` | Blob Storage       |
| `privatelink.vaultcore.azure.net`   | Key Vault          |
| `privatelink.azurecr.io`            | Container Registry |
| `privatelink.eastus2.azmk8s.io`     | AKS API server     |

DNS zones live in the hub and link to all spokes — new spokes inherit DNS resolution automatically without managing their own zones.

### Disaster Recovery

| Protection              | Resource        | Detail                                                   |
| ----------------------- | --------------- | -------------------------------------------------------- |
| Blob versioning         | `sttfstate7tcl` | Every state file overwrite retains previous version      |
| Blob soft delete        | `sttfstate7tcl` | Deleted blobs recoverable for 7 days                     |
| Container soft delete   | `sttfstate7tcl` | Deleted containers recoverable for 7 days                |
| Resource lock           | `rg-tfstate`    | `CanNotDelete` — prevents accidental RG deletion         |
| Key Vault soft delete   | `kv-aks-appdev` | Secrets recoverable for 7 days after deletion            |
| Backup vault            | `rsv-platform`  | VM backup policy — daily 2AM UTC, 7 daily restore points |
| Log Analytics retention | `law-platform`  | 30 days explicit, daily quota cap 1GB                    |

---

## CI/CD Pipeline

### How It Works

```
PR Opened
    │
    ▼
Detect changed modules (terraform-modules.json)
    │
    ▼
Matrix Plan — parallel, one job per changed module
    │
    ▼
Post plan diff as PR comment — peer review
    │
    ▼
Merge to main
    │
    ▼
Matrix Apply — sequential, dependency order enforced
    │
    ▼
Drift Detection — weekly scheduled plan across all modules
```

### Key Design Decisions

**Matrix strategy over monolithic workflow** — modules detected dynamically from `terraform-modules.json`. Adding a new module to CI/CD is a one-line JSON change.

**Sequential apply, parallel plan** — planning in parallel is safe (read-only). Applying sequentially respects tier dependency order — platform before landing zones, networking before workloads.

**`ci_enabled` flag per module** — platform modules (`ci_enabled: false`) require manual apply. Landing zone modules (`ci_enabled: true`) run through the automated pipeline. Prevents auto-applying sensitive platform changes.

**Drift detection** — weekly scheduled workflow runs `terraform plan` across all modules. Non-empty plan means real infrastructure diverged from state — workflow fails and alerts.

---

## Cost Management

This project runs on a $20/month budget. Workloads are deployed for learning, validated, then destroyed.

| Resource                  | Status                                  | Monthly Cost  |
| ------------------------- | --------------------------------------- | ------------- |
| Storage Account (tfstate) | ✅ Permanent                            | ~$1           |
| Log Analytics Workspace   | ✅ Permanent                            | ~$1           |
| Recovery Services Vault   | ✅ Permanent                            | ~$0           |
| Private DNS Zones (hub)   | 📝 Code only — not applied              | $0            |
| AKS Cluster + App Gateway | 🗑️ Ephemeral — destroyed after sessions | $0            |
| Container Apps            | 🗑️ Ephemeral                            | $0            |
| Virtual Machine           | 🗑️ Ephemeral                            | $0            |
| **Total**                 |                                         | **~$3/month** |

Budget alerts configured at subscription ($20) and resource group ($15) level — email notifications at 50%, 80%, 100% actual and forecasted thresholds.

Destroying workloads after validation is intentional — demonstrates cost-aware engineering and keeps focus on the platform layer where the durable value is.

---

## Skills Demonstrated

**Terraform** — remote state, cross-module data sources, output chaining, `for_each` for scalable resource creation, `depends_on` for explicit dependency ordering, provider configuration, lifecycle rules

**Azure Networking** — hub-spoke VNet topology, NSG rules and associations, VNet peering (bidirectional), Private Endpoints, Private Link, Private DNS zones, Application Gateway, AGIC

**AKS** — Azure CNI networking, system and workload node pools, node labels and selectors, OIDC issuer, workload identity, federated credentials, CSI Secrets Store driver

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

# 4. Landing zone networking
cd landing-zones/app-dev/networking && terraform init && terraform apply

# 5. Workloads — deploy to test, destroy when done
cd landing-zones/app-dev/workloads/compute/aks && terraform init && terraform apply
```

After step 2, subsequent deployments run automatically via GitHub Actions on PR and merge.

---

## Learning Log

Weekly progress documented in [`docs/`](docs/) — covering decisions made, problems encountered, errors triaged, and what each week taught. Built over 6 months targeting Cloud and Platform Engineer roles.

Architecture decisions and Mermaid diagrams in [`docs/architecture.md`](docs/architecture.md).

---

## License

MIT — see [LICENSE](LICENSE)
