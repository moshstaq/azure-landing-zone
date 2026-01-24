# Azure Landing Zone 🚀

Enterprise-grade Azure governance implemented with Terraform.

[![Terraform](https://img.shields.io/badge/Terraform-1.5+-623CE4?logo=terraform)](https://terraform.io)
[![Azure](https://img.shields.io/badge/Azure-Landing%20Zone-0078D4?logo=microsoft-azure)](https://azure.microsoft.com)

## Overview

This project demonstrates production-ready Azure governance patterns:

- **Management Groups** — Hierarchical policy inheritance
- **Azure Policy** — Compliance enforcement and auditing
- **Hub-Spoke Network** — Centralized connectivity with security controls
- **Identity & Access** — Entra ID groups, RBAC, Service Principal
- **Cost Management** — Budgets, alerts, and tagging policies
- **Observability** — Centralized Log Analytics workspace

> Built as a hands-on learning project while preparing for Cloud Engineer roles.

## Architecture

### Management Groups:

- yourname-learning
- yourname-platform
- yourname-workloads
- [Subscription]
- rg--platform- (permanent)
- rg--lab- (disposable)

Network:

- Hub VNet (10.0.0.0/16)
- snet-shared-services (10.0.0.0/24)
  Spoke VNets (labs):
- 10.x.0.0/16 (peered to hub)

## Getting Started

### Prerequisites

- Azure subscription (Pay-as-you-go or Free Tier)
- Terraform >= 1.5.0
- Azure CLI

### Deployment

```bash
# Clone this repo
git clone https://github.com/YOUR_USERNAME/azure-learning-lab.git
cd azure-learning-lab

# Configure variables
cp 00-foundation/terraform.tfvars.example 00-foundation/terraform.tfvars
# Edit terraform.tfvars with your values

# Deploy foundation
cd 00-foundation
terraform init
terraform apply

See docs/learning-log.md for detailed notes.
```

### Project Structure

- 00-foundation/ # Core governance infrastructure

### 01-labs/ # Disposable learning environments

- compute/ # VMs, containers
- networking/ # VNets, peering, NSGs
- monitoring/ # Alerts, dashboards

### docs/

- learning-log.md # What I learned
- interview-prep.md # Q&A from experience

### scripts/ # Helper scripts

### Cost Management

- Budget alerts set at $20/month
- Governance resources: Free
- Storage (Terraform state): ~$0.50/month
- Labs: Deploy → Learn → Destroy

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details
