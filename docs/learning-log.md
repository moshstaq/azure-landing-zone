# Azure Learning Journey

## Overview

Building hands-on Azure skills through a self-directed learning lab. This repository demonstrates enterprise-grade governance patterns implemented from scratch using Terraform.

**Timeline:** 6 months  
**Goal:** Cloud Engineer / Platform Engineer / DevOps Engineer roles  
**Certifications:** AZ-104, SC-300

---

## Week 1: Foundation & Governance

### What I Built

- **Management Group Hierarchy**
  - Root → Platform → Workloads structure
  - Demonstrates understanding of enterprise Azure organization
- **Governance Framework**
  - Azure Policies (audit mode) for compliance visibility
  - Budget alerts for cost control ($20/month limit)
  - Centralized Log Analytics workspace
- **Network Foundation**
  - Hub VNet (10.0.0.0/16) ready for spoke peering
  - Network Security Groups with default-deny posture
- **Identity & Access**
  - Entra ID groups for RBAC (Admins, Contributors, Readers)
  - Service Principal for Terraform automation
  - Least-privilege access pattern

### Key Learnings

| Topic              | What I Learned                              | Why It Matters                          |
| ------------------ | ------------------------------------------- | --------------------------------------- |
| Management Groups  | Hierarchical policy inheritance             | Enables consistent governance at scale  |
| Azure Policy       | Audit vs Deny modes                         | Start permissive, tighten over time     |
| Resource Groups    | Logical containers for lifecycle management | Deploy/destroy resources together       |
| Terraform State    | Remote state in Azure Storage               | Team collaboration, state locking       |
| Service Principals | Dedicated identity for automation           | Security, auditability, least privilege |
| Tagging            | Policies can enforce tag requirements       | Cost tracking, ownership, compliance    |

### Challenges & Solutions

| Challenge                             | Root Cause                              | Solution                                               |
| ------------------------------------- | --------------------------------------- | ------------------------------------------------------ |
| Deployment failed due to missing tags | Policy enforcement on `Environment` tag | Added `tags` block with required tags to all resources |
| Understanding policy inheritance      | New to management group hierarchy       | Drew diagram, tested policy at different scopes        |

### Cost

- **Week 1 Total:** $0.50 (storage account only)
- **Budget Remaining:** $19.50

---

## Technical Decisions

### Why Service Principal Instead of User Account?

**Decision:** Use dedicated Service Principal for all Terraform operations

**Reasoning:**

1. **Security** - Limited blast radius if credentials compromised
2. **Auditability** - Clear separation between manual and automated changes
3. **Least Privilege** - SP has only Contributor + User Access Administrator
4. **Enterprise Pattern** - Matches how production environments work

**Trade-off:** Initial setup complexity vs. long-term security posture

### Why Audit Mode for Policies?

**Decision:** All policies in audit mode initially

**Reasoning:**

1. **Learning Friendly** - See what would fail without being blocked
2. **Iterative Approach** - Understand impact before enforcing
3. **Enterprise Pattern** - Always test policies before enforcement

**Future:** Toggle to `Deny` effect when testing enforcement behavior

---

## Commands Reference

```bash
# Terraform Workflow
terraform init          # Initialize providers
terraform plan          # Preview changes
terraform apply         # Deploy infrastructure
terraform destroy       # Clean up resources
terraform output        # View outputs

# Azure CLI
az login                                    # Interactive login
az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET --tenant $ARM_TENANT_ID
az account show                             # Current context
az group list -o table                      # List resource groups
az policy assignment list -o table          # List policies

# Cost Check
az consumption budget list -o table
```
