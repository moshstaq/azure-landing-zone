# Work Notes — Week 17 Session

**Date:** 23 February 2026  
**Session Focus:** AGIC, upgrade_settings cleanup, dynamic manifest updates, end-to-end validation

---

## 1. upgrade_settings — Already Done

Confirmed `upgrade_settings` was added to both node pools after Week 16 as instructed. No action needed this session. Plan confirmed clean on that front.

---

## 2. Application Gateway Backend IP — Recurring Problem

Every session the Application Gateway `appgw.tf` had a stale hardcoded backend IP from the previous session. This triggered a spurious `terraform plan` diff every time:

```
- probe { host = "10.1.4.38" }
+ probe { host = "10.1.4.38" }  ← same value, different object ID
```

**Root cause:** Pod IPs are dynamic — assigned at scheduling time. Hardcoding them in Terraform is not viable.

**Solution:** AGIC — removes the need for Terraform to manage backend pool configuration entirely.

---

## 3. AGIC Installation

### What AGIC Does

AGIC (Application Gateway Ingress Controller) runs inside the cluster and watches Kubernetes Ingress resources. When an Ingress is created or updated, AGIC automatically translates it into Application Gateway backend pool and routing rule configuration via the Azure API. No manual backend IP management required.

```
Ingress resource created/updated
        │
        ▼
AGIC watches Kubernetes API
        │
        ▼
AGIC calls Azure ARM API
        │
        ▼
Application Gateway backend pool updated automatically
```

### Old Helm Repo Deprecated

The original AGIC Helm repo URL no longer exists. AGIC is now distributed via OCI registry on MCR:

```bash
helm install ingress-azure \
  oci://mcr.microsoft.com/azure-application-gateway/charts/ingress-azure \
  --namespace kube-system \
  --set appgw.applicationGatewayID=$APPGW_ID \
  --set armAuth.type=workloadIdentity \
  --set armAuth.identityClientID=$AGIC_CLIENT_ID \
  --set rbac.enabled=true
```

### AGIC Identity Setup

AGIC needs its own managed identity — separate from the workload identity. Three RBAC assignments required:

| Role                | Scope                      | Purpose                                |
| ------------------- | -------------------------- | -------------------------------------- |
| Contributor         | `agw-hub` resource         | Modify backend pools and routing rules |
| Reader              | `rg-platform-connectivity` | Read resource group                    |
| Network Contributor | `snet-appgw` subnet        | Join subnet (required by App Gateway)  |

### Errors Hit and Resolutions

**Error 1 — No federated credential on mi-agic:**

```
AADSTS70025: The client 'mi-agic' has no configured federated identity credentials
```

AGIC uses workload identity but the managed identity had no federated credential linking it to the AGIC Kubernetes service account. Fixed by creating the federated credential:

```bash
az identity federated-credential create \
  --name fed-agic \
  --identity-name mi-agic \
  --resource-group rg-app-dev \
  --issuer $OIDC_ISSUER \
  --subject "system:serviceaccount:kube-system:ingress-azure" \
  --audience "api://AzureADTokenExchange"
```

Subject must exactly match the service account AGIC creates for itself: `system:serviceaccount:kube-system:ingress-azure`.

**Error 2 — Insufficient permission on subnet:**

```
ApplicationGatewayInsufficientPermissionOnSubnet
Client does not have permission on vnet-hub/subnets/snet-appgw
to perform action Microsoft.Network/virtualNetworks/subnets/join/action
```

`Contributor` on the App Gateway resource is not sufficient — AGIC also needs `Network Contributor` on the subnet itself. Fixed by adding the subnet-scoped role assignment. Note: Azure RBAC propagation takes 2-5 minutes — restart AGIC pod after granting.

**Error 3 — Wrong ingress class:**

```
Unable to fetch IngressClass 'nginx' from cluster. IngressClass "nginx" not found
Skipping event — pod is not used by any Ingress
```

`ingress.yaml` still referenced `ingressClassName: nginx` — pointing to NGINX ingress controller which wasn't installed. AGIC uses a different class. Fixed by updating the Ingress:

```yaml
# Remove ingressClassName from spec
# Add annotation instead:
annotations:
  kubernetes.io/ingress.class: azure/application-gateway
```

**Error 4 — Service not found:**

```
Error from server (NotFound): endpoints "nginx-demo" not found
```

The Service resource was embedded in the old `deployment.yaml` which was deleted in Week 16. The new `deployment-wi.yaml` only contains the Deployment. Service never got reapplied. Fixed by separating the Service into its own `service.yaml` manifest — better separation of concerns.

---

## 4. Workload Identity Client ID — Stale Manifest Problem

Every time the cluster is destroyed and reprovisioned, Terraform creates a new managed identity with a new client ID. The manifests had the old client ID hardcoded:

```
Old: 5605f84e-8771-424d-b0ec-47fdbd063acc  ← Week 16
New: 5044e54e-3ee6-43ea-b7bf-d4596dbfadae  ← Week 17
```

**Error seen:**

```
AADSTS700016: Application with identifier '5605f84e-8771-424d-b0ec-47fdbd063acc'
was not found in the directory
```

**Solution — update-manifests.sh:**
Created a script that reads current Terraform outputs and patches the manifests automatically:

```bash
#!/bin/bash
CLIENT_ID=$(terraform output -raw workload_identity_client_id)
KV_NAME=$(terraform output -raw key_vault_name)

sed -i '' "s|azure.workload.identity/client-id:.*|azure.workload.identity/client-id: \"$CLIENT_ID\"|" \
  manifests/serviceaccount.yaml

sed -i '' "s|clientID:.*|clientID: \"$CLIENT_ID\"|" \
  manifests/secretprovider.yaml

sed -i '' "s|keyvaultName:.*|keyvaultName: \"$KV_NAME\"|" \
  manifests/secretprovider.yaml
```

**macOS vs Linux sed difference:**
`sed -i` works on Linux. On macOS, `-i` requires an explicit empty string: `sed -i ''`. Script uses macOS syntax since development is on Mac.

### Deployment Order for All Future Sessions

```
1. terraform apply
2. az aks get-credentials --overwrite-existing
3. helm install azure-keyvault-provider (CSI driver with syncSecret.enabled=true)
4. helm install ingress-azure (AGIC via OCI)
5. ./update-manifests.sh
6. kubectl apply -f manifests/
7. curl to validate
8. terraform destroy
```

---

## 5. CSI Secrets Store — Reminder

CSI driver must be installed every session with `syncSecret.enabled=true` from the start:

```bash
helm install azure-keyvault-provider csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system \
  --set secrets-store-csi-driver.enableSecretRotation=true \
  --set secrets-store-csi-driver.syncSecret.enabled=true
```

Omitting `syncSecret.enabled=true` causes:

```
secrets is forbidden: cannot create resource "secrets" in namespace "default"
```

---

## 6. End-to-End Validation

Full traffic path confirmed working:

```
Internet
    │
    ▼
20.110.136.121 (Application Gateway - agw-hub)
    │  ← AGIC manages backend pool dynamically
    ▼
VNet Peering (hub 10.0.0.0/16 → spoke 10.1.0.0/16)
    │
    ▼
nginx-demo pods (workload node - 10.1.4.41, 10.1.4.6)
    │  ← Secret from Key Vault via workload identity
    ▼
DB_PASSWORD = real-secret-managed-by-keyvault
```

`curl http://20.110.136.121` returned nginx welcome page.

---

## 7. Manifest Structure — Final State

```
manifests/
├── configmap.yaml        ← non-sensitive config as env vars
├── secret.yaml           ← placeholder (superseded by Key Vault)
├── serviceaccount.yaml   ← annotated with workload identity client ID
├── secretprovider.yaml   ← maps Key Vault secret to Kubernetes secret
├── deployment-wi.yaml    ← deployment using SA + CSI volume
├── service.yaml          ← ClusterIP service (separated from deployment)
└── ingress.yaml          ← AGIC annotation, no ingressClassName
```

---

## 8. Pending Items

| Item                                      | When                                    |
| ----------------------------------------- | --------------------------------------- |
| Move AGIC RBAC assignments into Terraform | Week 17 cleanup / next session          |
| Move mi-agic identity into Terraform      | Week 17 cleanup / next session          |
| Helm chart for app manifests              | Deferred — complexity vs value tradeoff |
| Monitoring alerts wired to real data      | Week 18 wrap-up                         |
| Disaster Recovery / Backup                | Week 19                                 |
| Cost Management + Budget Alerts           | Week 20                                 |

---

## 9. Concepts Covered

- **AGIC** — Kubernetes controller that translates Ingress resources to App Gateway config
- **OCI Helm registry** — modern distribution method replacing legacy Helm repos
- **Federated credential subject** — must exactly match the Kubernetes service account name and namespace
- **RBAC propagation delay** — Azure RBAC assignments take 2-5 minutes to propagate
- **Network Contributor on subnet** — required for App Gateway subnet join action, separate from App Gateway Contributor
- **IngressClass vs annotation** — AGIC uses annotation `kubernetes.io/ingress.class: azure/application-gateway`, not `ingressClassName`
- **Service separation** — Service and Deployment should be in separate manifests for clarity and independent lifecycle
- **macOS sed** — requires `-i ''` vs Linux `-i` for in-place file editing
