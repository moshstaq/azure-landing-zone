markdown

# GitHub Actions OIDC Authentication for Azure

This module configures secure, secretless CI/CD authentication from GitHub Actions to Azure using OpenID Connect (OIDC).

## Overview

Traditional CI/CD pipelines store service principal credentials as secrets. OIDC eliminates this by exchanging GitHub's short-lived tokens for Azure credentials automatically—no secrets to rotate or leak.

## Architecture

GitHub Actions Workflow
│
▼
OIDC Token Exchange (no secrets stored)
│
▼
Azure AD Service Principal
│
├──► Contributor ──────────────► Spoke Resource Group
│
├──► Reader ───────────────────► State Storage Resource Group
│
├──► Storage Blob Data ────────► State Storage Resource Group
│ Contributor
│
└──► Network Contributor ──────► Hub Virtual Network

## Components

| File           | Purpose                                     |
| -------------- | ------------------------------------------- |
| `main.tf`      | App registration and federated credentials  |
| `rbac.tf`      | Role assignments for least-privilege access |
| `variables.tf` | Input variables                             |
| `outputs.tf`   | Values needed for GitHub secrets            |
| `providers.tf` | AzureRM and AzureAD provider configuration  |
| `backend.tf`   | Remote state configuration                  |

## RBAC Configuration

| Scope                        | Role                          | Purpose                           |
| ---------------------------- | ----------------------------- | --------------------------------- |
| Spoke Resource Group         | Contributor                   | Create and manage spoke resources |
| State Storage Resource Group | Reader                        | Read storage account properties   |
| State Storage Resource Group | Storage Blob Data Contributor | Read/write Terraform state files  |
| Hub Virtual Network          | Network Contributor           | Manage hub-side VNet peering      |

## GitHub Secrets Required

After applying this module, configure these secrets in your GitHub repository:

| Secret Name             | Source                                  |
| ----------------------- | --------------------------------------- |
| `AZURE_CLIENT_ID`       | `terraform output -raw client_id`       |
| `AZURE_TENANT_ID`       | `terraform output -raw tenant_id`       |
| `AZURE_SUBSCRIPTION_ID` | `terraform output -raw subscription_id` |

## Workflow Configuration

The workflows require these environment variables:

```yaml
env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
  ARM_USE_OIDC: true
  ARM_USE_AZUREAD: true
Federated Credentials
Two credentials are configured for different GitHub events:

Credential	Subject	Trigger
Main branch	repo:<org>/<repo>:ref:refs/heads/main	Push to main
Pull requests	repo:<org>/<repo>:pull_request	PR opened/updated
Usage
bash
# Initialize
terraform init

# Plan
terraform plan

# Apply
terraform apply

# Get outputs for GitHub secrets
terraform output
Key Design Decisions
OIDC over secrets - Eliminates credential rotation and reduces leak risk

Least-privilege RBAC - Permissions scoped to specific resources, not broad subscription access

Resource-level permissions - Network Contributor granted on VNet, not entire resource group

Separate credentials per event - Main branch and PR triggers use distinct federated credentials

Troubleshooting
Error	                                     Cause	                Solution
AuthorizationPermissionMismatch            ARM_USE_AZUREAD: true   Add environment variable to workflow
on backend	Missing
No matching federated identity record	   Subject mismatc       Verify repo name and branch in federated credential
does not have authorization	                    Missing RBAC	        Add appropriate role assignment

```
