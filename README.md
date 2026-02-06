# Azure Landing Zone 🚀

Hands-on Azure infrastructure built with Terraform, following the Cloud Adoption Framework (CAF) landing zone pattern.

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

- moshstaq
- platform -> Shared infrastructure
- workloads -> Application landing zones
- [Azure Subscription]
- rg--platform- (permanent)
- rg--lab- (disposable)

Network:

- Hub VNet (10.0.0.0/16)
- snet-shared-services (10.0.0.0/24)
  Spoke VNets ():
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


# Deploy platform infrastructure
cd platform
terraform init
terraform apply

See docs/learning-log.md for detailed notes.
```

### Project Structure

- platform/ # Core governance infrastructure
  -- bootstrap/ # Terraform state storage (local state)
  -- connectivity/ # Hub VNet, shared networking
  -- management/ # Log Analytics, monitoring

- landing-zones/
  -- app-dev/
  -- networking/ # Spoke VNets, subnet, NSGs, peering
  -- workloads/ # ACI, future services

- docs/
  -- weekly-summaries/
  --learning-log.md # What I learned
  --interview-prep.md # Q&A from experience

- scripts/ # Helper scripts

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details
