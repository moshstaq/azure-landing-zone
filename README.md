# Azure Learning Lab 🚀

A hands-on Azure Landing Zone implementation demonstrating enterprise governance patterns using Terraform.

## What This Project Demonstrates

- **Management Group Hierarchy** - Organizing subscriptions with policy inheritance
- **Azure Policy** - Compliance enforcement (audit mode for learning)
- **Network Architecture** - Hub VNet ready for spoke peering
- **Identity & Access** - Entra ID groups, RBAC, Service Principal
- **Cost Management** - Budget alerts and resource tagging
- **Infrastructure as Code** - Terraform with remote state

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
