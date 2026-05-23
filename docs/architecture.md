# Architecture

This document covers the design of each layer of the landing zone — management hierarchy, networking, identity, CI/CD, and observability. All diagrams reflect the actual deployed infrastructure.

---

## Management Group Hierarchy

Policy assignments at the `moshstaq` management group propagate down to all child management groups and subscriptions automatically. No per-subscription policy configuration required.

```mermaid
graph TD
    TRG["🏢 Tenant Root Group"]
    MG["📁 moshstaq\nManagement Group"]
    PLAT["📁 platform\nShared Infrastructure"]
    WORK["📁 workloads\nApplication Landing Zones"]
    SUB["💳 Azure Subscription"]

    TRG --> MG
    MG --> PLAT
    MG --> WORK
    WORK --> SUB

    POL1["🔒 Policy: Require environment tag\n(Audit)"]
    POL2["🔒 Policy: Allowed locations\n(Deny)"]
    POL3["🔧 Policy: Activity Log forwarding\n(DeployIfNotExists)"]

    MG -.->|inherits| POL1
    MG -.->|inherits| POL2
    MG -.->|inherits| POL3

    style TRG fill:#f0f0f0,stroke:#999
    style MG fill:#0078D4,color:#fff,stroke:#005a9e
    style PLAT fill:#0078D4,color:#fff,stroke:#005a9e
    style WORK fill:#0078D4,color:#fff,stroke:#005a9e
    style SUB fill:#50e6ff,stroke:#0078D4
    style POL1 fill:#f7630c,color:#fff,stroke:#c45000
    style POL2 fill:#d13438,color:#fff,stroke:#a4262c
    style POL3 fill:#107c10,color:#fff,stroke:#0a5c0a
```

---

## Hub-Spoke Network Topology

The hub VNet is owned by the platform team. Spoke VNets are owned by landing zones. Peering is bi-directional — spoke traffic can reach hub shared services, hub can reach spoke workloads.

```mermaid
graph TB
    subgraph HUB["🌐 Hub VNet — 10.0.0.0/16 (rg-platform-connectivity)"]
        SHARED["snet-shared-services\n10.0.1.0/24"]
        APPGW["snet-appgw\n10.0.2.0/24"]
        NVA["snet-nva\n10.0.3.0/28"]
    end

    subgraph WORKLOADS["📦 Workloads Spoke — 10.1.0.0/16 (rg-workloads)"]
        COMPUTE["snet-compute\n10.1.1.0/24"]
        CONTAINERS["snet-containers\n10.1.3.0/24"]
        AKS["snet-aks\n10.1.4.0/22"]
    end

    subgraph DATA["🗄️ Data Spoke — 10.2.0.0/16 (rg-data)"]
        DATA_SUBNETS["Subnets provisioned\non demand (PaaS / PE)"]
    end

    HUB <-->|"VNet Peering\n(bi-directional)"| WORKLOADS
    HUB <-->|"VNet Peering\n(bi-directional)"| DATA

    NSG_CONTAINERS["🛡️ NSG\nnsg-containers"]
    NSG_AKS["🛡️ NSG\nnsg-aks"]

    CONTAINERS --- NSG_CONTAINERS
    AKS --- NSG_AKS

    style HUB fill:#e6f3ff,stroke:#0078D4
    style WORKLOADS fill:#e6ffe6,stroke:#107c10
    style DATA fill:#fff4ce,stroke:#f7630c
    style NSG_CONTAINERS fill:#fff4ce,stroke:#f7630c
    style NSG_AKS fill:#fff4ce,stroke:#f7630c
```

---

## Terraform State Architecture

Each module owns an isolated state file. Cross-module references use `terraform_remote_state` data sources — resource IDs flow between modules without hardcoding. Arrows show the direction of the dependency (the module at the tail reads from the module at the head).

```mermaid
graph LR
    subgraph STORAGE["💾 sttfstate7tcl (rg-tfstate)"]
        BS["platform/bootstrap"]
        MGMT["platform/management"]
        CONN["platform/connectivity"]
        GOV["platform/governance"]
        OIDC["platform/identity/github-oidc"]
    end

    MGMT -->|"law_workspace_id"| CONN
    CONN -->|"private_dns_zone_kv_id"| OIDC

    style STORAGE fill:#f0f0f0,stroke:#999
    style MGMT fill:#0078D4,color:#fff
    style CONN fill:#0078D4,color:#fff
    style OIDC fill:#0078D4,color:#fff
```

> `platform/connectivity` reads `law_workspace_id` from `platform/management` to configure NSG diagnostic settings. `platform/identity/github-oidc` reads `private_dns_zone_kv_id` from `platform/connectivity` to create the DNS zone RBAC assignment for `taskflow-platform`. This means management must be applied before connectivity, and connectivity before identity.

---

## Identity & OIDC Authentication

No secrets stored in GitHub. The runner exchanges a short-lived JWT for an Azure access token scoped to specific resources.

```mermaid
sequenceDiagram
    participant GH as GitHub Actions Runner
    participant AAD as Azure AD
    participant ARM as Azure Resource Manager

    GH->>AAD: Request token<br/>(JWT with subject claim)
    Note over GH,AAD: Subject: ref:refs/heads/main<br/>Audience: api://AzureADTokenExchange

    AAD->>AAD: Validate federated credential<br/>match subject + issuer

    AAD->>GH: Return access token<br/>(short-lived, scoped)

    GH->>ARM: API calls with access token
    ARM->>ARM: Validate RBAC<br/>(scoped to resource groups)
    ARM->>GH: Response
```

### Federated Credential Subjects

Two credentials are configured per repository — one for each distinct GitHub event type:

| Credential             | Subject Claim         | Workflow            |
| ---------------------- | --------------------- | ------------------- |
| `github-main-branch`   | `ref:refs/heads/main` | Direct push applies |
| `github-pull-requests` | `pull_request`        | PR plan jobs        |

A token issued for a PR plan job **cannot** be used to trigger an apply — the subject claims don't match. This is enforced by Azure AD, not by workflow logic.

---

## CI/CD Pipeline

```mermaid
flowchart TD
    PR["📬 Pull Request Opened"]
    DETECT["🔍 Detect Changed Modules\nterraform-modules.json"]
    MATRIX_PLAN["⚡ Matrix Plan\nParallel per changed module"]

    PR --> DETECT
    DETECT --> MATRIX_PLAN

    MATRIX_PLAN --> P1["plan: platform/connectivity"]
    MATRIX_PLAN --> P2["plan: platform/management"]
    MATRIX_PLAN --> P3["plan: platform/governance"]

    P1 --> ART["📦 Upload Plan Artifacts"]
    P2 --> ART
    P3 --> ART

    ART --> COMMENT["💬 Post Plan Diff\nto PR as Comment"]
    COMMENT --> REVIEW["👀 Peer Review"]
    REVIEW --> MERGE["✅ Merge to Main"]

    MERGE --> NOTE["⚠️ All platform modules ci_enabled: false\nNo auto-apply — manual terraform apply required"]

    DRIFT["🕵️ Drift Detection\nWeekly Scheduled"]
    DRIFT --> PLAN_ALL["terraform plan — all modules"]
    PLAN_ALL --> DIFF{"Non-empty\nplan?"}
    DIFF -->|Yes| ALERT["🚨 GitHub Issue Opened\nautomatically"]
    DIFF -->|No| OK["✅ No drift detected"]

    style PR fill:#0078D4,color:#fff
    style MERGE fill:#107c10,color:#fff
    style ALERT fill:#d13438,color:#fff
    style OK fill:#107c10,color:#fff
    style DRIFT fill:#8764b8,color:#fff
    style NOTE fill:#fff4ce,stroke:#f7630c
```

---

## Observability Architecture

```mermaid
graph TB
    subgraph SOURCES["📡 Log Sources"]
        ACT["Azure Activity Logs\n(all subscriptions)"]
        NSG_FLOW["NSG Flow Logs\n(workloads spoke NSGs)"]
    end

    subgraph PLATFORM["🔍 law-platform (rg-platform-management)"]
        LAW["Log Analytics Workspace\n1GB daily cap"]
    end

    subgraph ALERTS["🚨 Scheduled Query Alerts (KQL)"]
        A1["alert-policy-noncompliance\nSeverity: Warning | PT1H"]
        A2["alert-terraform-apply-failure\nSeverity: Error | PT1H"]
        A3["alert-nsg-deny-spike\nSeverity: Warning | PT15M"]
    end

    AG["📧 ag-platform-alerts\nAction Group\n(email)"]

    ACT -->|"Subscription diagnostic setting\n(activity-logs.tf)"| LAW
    NSG_FLOW -->|"NSG diagnostic settings\n(diagnostics.tf)"| LAW

    LAW --> A1
    LAW --> A2
    LAW --> A3

    A1 --> AG
    A2 --> AG
    A3 --> AG

    style LAW fill:#0078D4,color:#fff
    style AG fill:#107c10,color:#fff
    style A1 fill:#fff4ce,stroke:#f7630c
    style A2 fill:#ffe6e6,stroke:#d13438
    style A3 fill:#fff4ce,stroke:#f7630c
```

---

## Resource Group Layout

| Resource Group             | Tier         | Purpose                                | Lifecycle                                   |
| -------------------------- | ------------ | -------------------------------------- | ------------------------------------------- |
| `rg-tfstate`               | Platform     | Terraform remote state storage         | Permanent                                   |
| `rg-platform-connectivity` | Platform     | Hub VNet, spokes, NSGs, NVA, DNS zones | Permanent                                   |
| `rg-platform-management`   | Platform     | Log Analytics, alerts, backup, budgets | Permanent                                   |
| `rg-workloads`             | Landing Zone | Workloads spoke VNet and subnets       | Permanent                                   |
| `rg-data`                  | Landing Zone | Data spoke VNet                        | Permanent                                   |
| `rg-taskflow`              | Landing Zone | Empty boundary for taskflow-platform   | Permanent (boundary) / Ephemeral (contents) |

---

## Design Decisions

### Why hub-spoke over a flat VNet?

Spoke VNets are independently managed — the workloads team controls their address space, subnets, and NSGs without touching platform networking. Adding a second landing zone is a new spoke, not a change to existing infrastructure. The hub provides a single point for shared services and NVA-enforced inter-spoke routing.

### Why modular state over a single backend?

A monolithic state file means any Terraform operation locks the entire infrastructure. Separate state per module means platform changes don't block workload deployments and vice versa. It also limits the blast radius of a corrupted state file to one module.

### Why OIDC over service principal secrets?

Secrets rotate, get leaked, and require management overhead. OIDC federated credentials are bound to specific GitHub subjects (branch, PR) and issued as short-lived tokens. There is no credential to leak because no credential is stored.

### Why sequential apply but parallel plan?

Plan operations are read-only against the Azure API and idempotent — parallelising them is safe and speeds up PR feedback. Apply operations have ordering dependencies (management must exist before connectivity can read its state outputs), so sequential execution with explicit ordering prevents race conditions.

### Why all platform modules have ci_enabled: false?

Platform infrastructure is sensitive. Auto-applying connectivity, governance, or identity changes could have wide blast radius — a misconfigured NSG affects all spokes, an identity mistake could lock the pipeline out of itself. Manual apply forces human review of every platform change. Speed is not the priority here.
