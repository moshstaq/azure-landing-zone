# Week 3: Compute & Identity - Key Learnings

## Lab 3.1: Linux VM Deployment

### Core Concepts

- VM requires: NIC + OS Disk + VM resource (minimum)
- NIC lives in subnet, VM references NIC
- Always use SSH keys, never passwords
- B-series = burstable (dev/test), D-series = production

### Cost Control

- Deallocated VM = no compute cost (disk still charges ~$1/month)
- Delete public IPs when not needed (~$3.50/month each)
- Free tier: Standard_B1s (750 hrs/month for 12 months)

### Interview Points

- "I deploy VMs with SSH key authentication, never passwords"
- "VMs are deallocated during off-hours to minimize costs"
- "I use appropriate VM sizing - B-series for dev, D-series for production"

---

## Lab 3.2: RBAC & Managed Identity

### Managed Identity Types

|
Type
|
Lifecycle
|
Use Case
|
|

---

## |

## |

|
|
System-Assigned
|
Tied to resource (deleted together)
|
Single resource
|
|
User-Assigned
|
Independent lifecycle
|
Shared across resources
|

### RBAC Formula

WHO (Principal) + WHAT (Role) + WHERE (Scope) = Access

text

### Key Roles to Know

| Role                          | What It Does                   |
| ----------------------------- | ------------------------------ |
| Owner                         | Everything + assign roles      |
| Contributor                   | Everything except assign roles |
| Reader                        | View only                      |
| Storage Blob Data Contributor | Read/write blob data           |
| Key Vault Secrets User        | Read secrets only              |

### Critical Concept: Control Plane vs Data Plane

- **Control Plane**: Managing resources (create, delete, configure)
  - Roles: Contributor, Owner, Reader
- **Data Plane**: Accessing data inside resources
  - Roles: Storage Blob Data _, Key Vault Secrets _
- **Gotcha**: Contributor ≠ data access!

### RBAC Behavior

- Additive only (permissions combine, never subtract)
- Propagation takes 1-5 minutes
- Inherited down scope hierarchy (Subscription → RG → Resource)

### Interview Points

- "Managed Identity eliminates credential management entirely"
- "I follow least-privilege: minimum permissions needed"
- "System-Assigned MI is deleted when the resource is deleted"
- "Control plane and data plane have separate role hierarchies"

---

## Lab 3.3: Monitoring (DCR & Alerts)

### Monitoring Architecture

Data Source (VM) → DCR (what to collect) → Log Analytics (storage) → Alerts (action)

text

### Alert Components

- **Scope**: What to monitor
- **Condition**: When to trigger (metric threshold or log query)
- **Action Group**: What to do (email, SMS, webhook, runbook)

### Alert Severity

| Level | Meaning       | Example          |
| ----- | ------------- | ---------------- |
| 0     | Critical      | Production down  |
| 1     | Error         | Service degraded |
| 2     | Warning       | High CPU         |
| 3     | Informational | Unusual pattern  |
| 4     | Verbose       | Debug info       |

### Interview Points

- "Data Collection Rules centralize monitoring configuration"
- "Alerts enable proactive detection, not reactive troubleshooting"
- "Log Analytics is the central repository for all Azure monitoring data"
- "I configure appropriate severity levels and action groups for each alert type"
