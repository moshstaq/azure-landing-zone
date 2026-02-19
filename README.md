# Azure Landing Zone

Enterprise-grade Azure infrastructure built with Terraform, implementing Cloud Adoption Framework (CAF) landing zone patterns. Built as a hands-on learning project to demonstrate platform engineering skills across governance, networking, identity, and CI/CD automation.

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Landing%20Zone-0078D4?logo=microsoft-azure)](https://azure.microsoft.com)
[![CI/CD](https://img.shields.io/badge/CI%2FCD-GitHub%20Actions-2088FF?logo=github-actions)](https://github.com/features/actions)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## What This Is

A production-pattern Azure Landing Zone built from scratch — not a template, not a wizard. Every resource is defined in Terraform, every deployment runs through GitHub Actions, and every design decision mirrors what platform teams do at enterprise scale.

This covers the full stack: management group hierarchy, hub-spoke networking, Azure Policy, centralized observability, secretless CI/CD via OIDC, and workload isolation across landing zones.

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
Hub VNet (10.0.0.0/16)              Spoke VNet (10.1.0.0/16)
├── snet-shared (10.0.1.0/24)       ├── snet-app (10.1.1.0/24)
│                                   ├── snet-data (10.1.2.0/24)
│                                   ├── snet-containers (10.1.3.0/24)
└────────── VNet Peering ───────────┘
```

Central connectivity lives in the platform hub. Spoke VNets are workload-isolated but share hub services. NSGs enforce traffic boundaries at subnet level.

### Terraform State Strategy

Each tier owns its own remote state in Azure Blob Storage. Modules reference cross-tier outputs via `terraform_remote_state` data sources — no hardcoded IDs, no monolithic state file.

```
tfstate/
├── platform/bootstrap/
├── platform/connectivity/
├── platform/management/
├── platform/governance/
├── platform/identity/
└── landing-zones/app-dev/
    ├── networking/
    └── workloads/compute/
```

This means a broken workload deployment cannot corrupt platform state. Blast radius is scoped to the module.

---

## Repository Structure

```
azure-landing-zone/
├── .github/
│   ├── terraform-modules.json       ← module registry for matrix CI/CD
│   └── workflows/
│       ├── terraform-matrix-plan.yml   ← PR plan with parallel matrix
│       ├── terraform-matrix-apply.yml  ← sequential apply on merge
│       └── drift-detection.yml         ← weekly scheduled drift check
├── platform/
│   ├── bootstrap/        ← remote state storage (Storage Account)
│   ├── connectivity/     ← hub VNet, subnets, NSGs
│   ├── management/       ← Log Analytics, Azure Monitor alerts
│   ├── governance/       ← Azure Policy definitions and assignments
│   └── identity/
│       └── github-oidc/  ← App Registration, federated credentials, RBAC
└── landing-zones/
    └── app-dev/
        ├── networking/   ← spoke VNet, subnets, NSGs, VNet peering
        └── workloads/
            └── compute/
                ├── aci/             ← Azure Container Instances
                ├── container-apps/  ← Container Apps + monitoring
                └── vm/              ← Virtual Machines
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

The `DeployIfNotExists` policy is the most operationally significant — it auto-remediates non-compliant resources rather than just flagging them.

### Observability

Centralized Log Analytics workspace (`law-platform`) receives:

- Activity Logs from all subscriptions via Policy-driven diagnostic settings
- NSG flow logs from platform and spoke subnets
- Container Apps telemetry from workload landing zones

Three KQL-based scheduled query alerts run against this workspace:

| Alert                 | Severity | Frequency | What It Catches            |
| --------------------- | -------- | --------- | -------------------------- |
| Policy non-compliance | Warning  | Hourly    | Governance drift           |
| Deployment failures   | Error    | Hourly    | Failed Terraform applies   |
| NSG deny spike        | Warning  | 15 min    | Unexpected blocked traffic |

All alerts route to a central Action Group with email notification — the same Action Group ID is exposed as a Terraform output so workload modules can reference it via remote state without hardcoding.

### Identity & Authentication

No stored secrets anywhere in this repository. GitHub Actions authenticates to Azure via OIDC federated credentials:

```
GitHub Actions Runner
       │
       │  JWT token (short-lived, audience: api://AzureADTokenExchange)
       ▼
Azure AD App Registration
       │
       │  Access token scoped to subscription
       ▼
Azure Resource Manager
```

Three federated credentials cover the full CI/CD surface:

| Credential                      | Subject Claim                  | Used By           |
| ------------------------------- | ------------------------------ | ----------------- |
| `github-main-branch`            | `ref:refs/heads/main`          | Direct pushes     |
| `github-pull-requests`          | `pull_request`                 | PR plan workflows |
| `github-environment-production` | `environment:azure-production` | Apply workflow    |

The service principal has Contributor scoped to specific resource groups — not broad subscription-level access.

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
Matrix Plan (parallel, one job per changed module)
    │
    ├── platform/connectivity
    ├── platform/management
    └── landing-zones/app-dev/networking
    │
    ▼
Post plan diff as PR comment (peer review)
    │
    ▼
Merge to main
    │
    ▼
Matrix Apply (sequential — dependency order enforced)
```

### Drift Detection

A weekly scheduled workflow runs `terraform plan` across all modules. If any plan is non-empty (meaning real infrastructure diverged from state), the workflow fails and triggers an alert. This catches out-of-band changes made via the portal or CLI.

### Key Design Decisions

**Matrix strategy over monolithic workflow** — modules are detected dynamically from `terraform-modules.json`. Adding a new module to CI/CD is a one-line JSON change, not a workflow rewrite.

**Sequential apply, parallel plan** — planning in parallel is safe because it's read-only. Applying sequentially respects the dependency order (platform before landing zones, networking before workloads).

**Environment protection on apply** — the production environment requires explicit approval before apply runs. The OIDC federated credential for apply is scoped to `environment:azure-production`, so even a compromised workflow token from a plan job can't trigger an apply.

---

## Cost Management

This project runs on a $20/month budget. Workloads are deployed for learning, validated, then destroyed.

| Resource                   | Status                     | Monthly Cost  |
| -------------------------- | -------------------------- | ------------- |
| Storage Account (tfstate)  | ✅ Permanent               | ~$1           |
| Log Analytics Workspace    | ✅ Permanent               | ~$1           |
| Container Apps Environment | ✅ Running                 | ~$3           |
| Virtual Machine            | 🗑️ Destroyed after Week 9  | $0            |
| Key Vault                  | 🗑️ Destroyed after Week 8  | $0            |
| Storage + Private Endpoint | 🗑️ Destroyed after Week 10 | $0            |
| **Total**                  |                            | **~$5/month** |

Destroying workloads after validation is intentional — it demonstrates cost-aware engineering and keeps the focus on the platform layer, which is where the durable value is.

---

## Skills Demonstrated

**Terraform** — remote state, state data sources for cross-module references, output chaining, provider configuration, dependency management

**Azure** — Management Groups, hub-spoke VNet peering, NSGs, Azure Policy (Deny + DeployIfNotExists), Log Analytics, RBAC least-privilege, Container Apps, Azure Monitor

**CI/CD** — GitHub Actions, OIDC secretless authentication, matrix strategy, artifact passing between jobs, PR comment automation, drift detection, environment protection gates

**Platform Patterns** — landing zone architecture, tier-based deployment ordering, immutable infrastructure, GitOps workflow, blast radius isolation via modular state

---

## Getting Started

### Prerequisites

- Azure subscription
- Terraform >= 1.5.0
- Azure CLI
- GitHub repository with Actions enabled

### Deployment Order

Modules must be deployed in dependency order:

```bash
# 1. Bootstrap (remote state storage)
cd platform/bootstrap && terraform init && terraform apply

# 2. Identity (OIDC + service principal)
cd platform/identity/github-oidc && terraform init && terraform apply

# 3. Platform services (order matters)
cd platform/connectivity && terraform init && terraform apply
cd platform/management  && terraform init && terraform apply
cd platform/governance  && terraform init && terraform apply

# 4. Landing zone networking
cd landing-zones/app-dev/networking && terraform init && terraform apply

# 5. Workloads (deploy to test, destroy when done)
cd landing-zones/app-dev/workloads/compute/container-apps && terraform init && terraform apply
```

After step 2, subsequent deployments run automatically via GitHub Actions on PR and merge.

---

## Learning Log

Weekly progress documented in [`docs/`](docs/) — covering decisions made, problems hit, and what each week taught. Built over 6 months targeting Cloud Engineer and Platform Engineer roles.

Architecture decisions and diagrams documented in [`docs/architecture.md`](docs/architecture.md)

---

## License

MIT — see [LICENSE](LICENSE)
