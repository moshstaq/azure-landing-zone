# Work Notes — Pipeline Fix & RBAC Remediation Session

**Date:** 26 February 2026
**Session Focus:** Fix pipeline 403 errors, AGIC RBAC into Terraform, GitHub Actions SP permissions

---

## 1. Problem Statement

Pipeline failing with two 403 errors on push to main:

**Error 1 — Public IP read forbidden:**

```
Error: retrieving Public IP Address "pip-appgw"
AuthorizationFailed: The client 'a814055a-7ff5-411d-9c31-fa4cdd2f06e1' does not have
authorization to perform action 'Microsoft.Network/publicIPAddresses/read' over scope
'/subscriptions/***/resourceGroups/rg-platform-connectivity/providers/Microsoft.Network/publicIPAddresses/pip-appgw'
```

**Error 2 — Key Vault secret read forbidden:**

```
Error: making Read request on Azure KeyVault Secret db-password
Caller is not authorized to perform action on resource
Action: 'Microsoft.KeyVault/vaults/secrets/getSecret/action'
ForbiddenByRbac
```

**Root cause:** The GitHub Actions service principal object ID changed from `f91fda37` to `a814055a`. The `terraform_kv_admin` role assignment in `keyvault.tf` was created with the old object ID. The new identity had no permissions on `rg-platform-connectivity`.

---

## 2. Investigation

### Service Principal Confirmed

```
Display Name: sp-github-actions-azure-landing-zone
Object ID:    a814055a-7ff5-411d-9c31-fa4cdd2f06e1
App ID:       f84ff2d5-5d1d-431e-b39d-631a18353f24
```

### Existing Role Assignments — Before Fix

Query by assignee returned nothing. Scope-based query confirmed:

| Role                          | Scope        |
| ----------------------------- | ------------ |
| Contributor                   | `rg-app-dev` |
| Storage Blob Data Contributor | `rg-tfstate` |
| Reader                        | `rg-tfstate` |

Missing: any permissions on `rg-platform-connectivity`.

### Why rg-platform-connectivity Was Never Covered

The identity module `platform/identity/github-oidc/main.tf` only defined role assignments for `rg-app-dev` and `rg-tfstate`. The App Gateway and Public IP resources live in `rg-platform-connectivity` — added during Week 16 as ephemeral resources — but the corresponding pipeline permissions were never added to the identity module.

---

## 3. Security Discussion — Least Privilege vs Practicality

Before applying the fix, considered three approaches:

**Option A — Contributor on rg-platform-connectivity (broad)**
Simple, one assignment. Grants full CRUD on everything in the resource group including hub VNet, NSGs, peering. Security concern — a compromised token could modify core hub networking affecting all spokes.

**Option B — Resource-scoped assignments (strict least-privilege)**
Individual Contributor assignments on `agw-hub`, `pip-appgw`, and Network Contributor on `snet-appgw`. More secure but creates dependency on ephemeral resource IDs that change or don't exist between sessions.

**Option C — Data source driven scoped assignments**
Use data sources to look up resource IDs dynamically. Cleaner than hardcoding but creates chicken-and-egg problem — data sources fail when ephemeral resources don't exist (cluster destroyed between sessions).

**Decision — Reader + Contributor on RG level**
Chosen approach balances security and practicality:

- `Reader` — visibility across the resource group
- `Contributor` — required to manage ephemeral App Gateway and Public IP

Rationale documented in code comment. Resource group boundary is the standard enterprise scope for pipeline permissions. Revisit if hub VNet resources need stricter protection.

---

## 4. Fix Applied

Added to `platform/identity/github-oidc/main.tf`:

```hcl
data "azurerm_resource_group" "connectivity" {
  name = "rg-platform-connectivity"
}

resource "azurerm_role_assignment" "connectivity_reader" {
  scope                = data.azurerm_resource_group.connectivity.id
  role_definition_name = "Reader"
  principal_id         = azuread_service_principal.github_actions.object_id
}

resource "azurerm_role_assignment" "connectivity_contributor" {
  scope                = data.azurerm_resource_group.connectivity.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.github_actions.object_id
}
```

Applied manually — identity module has `ci_enabled: false` so pipeline does not auto-apply it.

### Role Assignments Verified — After Fix

| Role                          | Scope                      |
| ----------------------------- | -------------------------- |
| Contributor                   | `rg-app-dev`               |
| Reader                        | `rg-platform-connectivity` |
| Contributor                   | `rg-platform-connectivity` |
| Storage Blob Data Contributor | `rg-tfstate`               |
| Reader                        | `rg-tfstate`               |

---

## 5. AGIC RBAC — Moved into Terraform

### Background

During Week 17, AGIC identity and RBAC assignments were created manually via CLI. This meant they were not tracked in state and would be lost on destroy. Created `agic-rbac.tf` to bring them under Terraform management.

### What Was Added — agic-rbac.tf

```
azurerm_user_assigned_identity.agic         (mi-agic)
azurerm_federated_identity_credential.agic  (fed-agic)
azurerm_role_assignment.agic_appgw_contributor
azurerm_role_assignment.agic_rg_reader
azurerm_role_assignment.agic_subnet_network_contributor
output.agic_client_id
output.appgw_id
```

### Branch Strategy

Changes committed to `fix/agic-rbac-terraform` branch — not main — to prevent pipeline from attempting to provision AKS resources while cluster was destroyed.

Merged to main once pipeline permissions were confirmed working.

---

## 6. Pipeline Behaviour — ci_enabled Explained

`terraform-modules.json` controls which modules the CI/CD pipeline processes:

```json
{
  "name": "platform-github-oidc",
  "path": "platform/identity/github-oidc",
  "tier": 2,
  "ci_enabled": false   ← pipeline skips this module
}
```

**All platform modules have `ci_enabled: false`:**

- `platform-connectivity`
- `platform-management`
- `platform-governance`
- `platform-github-oidc`

**Why this is correct:**
Platform infrastructure is sensitive. Auto-applying identity changes could lock the pipeline out of itself if something goes wrong. Manual apply is the safer pattern for platform modules. Landing zone modules (`ci_enabled: true`) run through the automated pipeline.

**Implication:** Any changes to platform modules must be applied manually:

```bash
cd ~/Infra/azure-learning/platform/<module>
terraform apply -auto-approve
```

---

## 7. Pipeline Result

After merge to main — pipeline ran green. AKS module skipped apply correctly — cluster not provisioned since `agic-rbac.tf` resources depend on the cluster existing first. Apply will succeed next AKS session when cluster is provisioned.

---

## 8. Key Lessons

**RBAC assignments must be in Terraform from day one** — manual CLI assignments get lost on destroy and cause pipeline failures in future sessions. Every role assignment created via CLI should be immediately moved into the appropriate Terraform module.

**Platform module permissions need updating when new resources are added** — adding the App Gateway to `rg-platform-connectivity` in Week 16 should have triggered a review of the identity module permissions at the same time. This was the gap that caused the 403.

**ci_enabled: false is a feature not a bug** — platform modules being excluded from auto-apply is deliberate security design. It forces a human to review and apply sensitive infrastructure changes.

**az role assignment list --assignee can be unreliable** — use scope-based query for reliable results:

```bash
az role assignment list \
  --scope $(az group show --name <rg-name> --query id -o tsv) \
  --query "[?principalId=='<object-id>'].{Role:roleDefinitionName}" \
  -o table
```
