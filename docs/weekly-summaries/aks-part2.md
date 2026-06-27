# Work Notes — AKS Part 2: Ingress and Workload Identity

**Session Focus:** Application Gateway (hub ingress pattern), Workload Identity, Key Vault CSI integration

---

## 1. Application Gateway — Hub Ingress Pattern

### Architectural Decision

Application Gateway is conceptually a hub resource but managed ephemerally alongside AKS due to budget constraints (~$0.30/hour). In production it would be permanent in `platform/connectivity`.

Alternatives considered and rejected:

| Option                              | Reason Rejected                                            |
| ----------------------------------- | ---------------------------------------------------------- |
| Azure Firewall                      | ~$1.25/hour, overkill for HTTP routing                     |
| Azure Front Door                    | Bypasses hub-spoke model, traffic doesn't flow through hub |
| Direct ingress (public IP on spoke) | Breaks hub-spoke trust boundary claim in README            |

### What Was Built

- `azurerm_subnet.appgw` — dedicated `snet-appgw` (10.0.2.0/24) in hub VNet. Microsoft requirement — App Gateway cannot share a subnet
- `azurerm_public_ip.appgw` — static Standard SKU public IP
- `azurerm_application_gateway.hub` — Standard_v2, capacity 1

### Files

- `platform/connectivity/main.tf` — App Gateway resources removed (wrong placement)
- `landing-zones/app-dev/workloads/compute/aks/appgw.tf` — correct location alongside AKS

### Errors Hit

**TLS policy error on apply:**

```
ApplicationGatewayDeprecatedTlsVersionUsedInSslPolicy
```

Fix — added explicit SSL policy block:

```hcl
ssl_policy {
  policy_type = "Predefined"
  policy_name = "AppGwSslPolicy20220101"
}
```

`AppGwSslPolicy20220101` enforces TLS 1.2 minimum — current Microsoft recommended policy.

### Backend IP Problem

App Gateway backend pool requires the ingress controller pod IP. Pod IPs are dynamic — assigned at scheduling time. Workflow each session:

1. Deploy App Gateway with placeholder IP
2. Deploy ingress controller — get pod IP
3. Update backend pool — `terraform apply`

Attempted static ClusterIP assignment failed — ClusterIP must come from service CIDR (`10.2.0.0/16`), not VNet subnet. Pod IPs and service IPs are separate ranges.

**Permanent fix identified:** AGIC (Application Gateway Ingress Controller) — reads Kubernetes Ingress resources directly and updates backend pool automatically. Scheduled for Week 17.

### Traffic Path Validated

```
Internet
    │
    ▼
20.114.201.182 (Application Gateway - rg-platform-connectivity)
    │
    ▼
VNet Peering (hub 10.0.0.0/16 → spoke 10.1.0.0/16)
    │
    ▼
10.1.4.38 (NGINX Ingress Controller - system node)
    │
    ▼
10.1.4.57 / 10.1.4.40 (nginx-demo pods - workload node)
```

`curl http://20.114.201.182` returned nginx welcome page — full path confirmed.

### NSG Validation

`snet-aks` NSG has no internet inbound rule. External traffic blocked at spoke — only hub VNet traffic allowed via explicit rule (`10.0.0.0/16`). This is correct. The App Gateway in the hub is the internet entry point.

---

## 2. Workload Identity + Key Vault

### What Was Built

**AKS changes:**

- `oidc_issuer_enabled = true` — enables OIDC issuer URL on the cluster
- `workload_identity_enabled = true` — enables workload identity webhook
- Both applied in-place, no cluster recreate required

**Azure resources (`keyvault.tf`):**

| Resource               | Name                    | Purpose                           |
| ---------------------- | ----------------------- | --------------------------------- |
| Key Vault              | `kv-aks-appdev`         | Stores real secrets, RBAC auth    |
| Key Vault Secret       | `db-password`           | Replaces dummy Kubernetes Secret  |
| User Assigned Identity | `mi-aks-nginx-demo`     | Pod identity, one per workload    |
| Role Assignment        | Key Vault Secrets User  | Managed identity → Key Vault read |
| Role Assignment        | Key Vault Administrator | Terraform → Key Vault write       |
| Federated Credential   | `fed-aks-nginx-demo`    | Links identity to Kubernetes SA   |

**Federated credential subject:**

```
system:serviceaccount:default:nginx-demo-sa
```

Only this specific service account in the `default` namespace can assume the managed identity. Nothing else in the cluster can.

**Kubernetes resources (`manifests/`):**

| Manifest              | Purpose                                            |
| --------------------- | -------------------------------------------------- |
| `serviceaccount.yaml` | SA annotated with managed identity client ID       |
| `secretprovider.yaml` | SecretProviderClass — maps KV secret to K8s secret |
| `deployment-wi.yaml`  | Updated deployment using SA and CSI volume mount   |

### Errors Hit

**Error 1 — ServiceAccount indentation:**

```
unknown field "labels"
```

`labels` was at root level instead of nested under `metadata`. Fixed indentation.

**Error 2 — CSI driver forbidden:**

```
secrets is forbidden: User "system:serviceaccount:kube-system:secrets-store-csi-driver"
cannot create resource "secrets" in API group "" in the namespace "default"
```

CSI driver successfully fetched secret from Key Vault but lacked RBAC to create the Kubernetes secret. Fix — reinstall with `syncSecret.enabled=true`:

```bash
helm upgrade azure-keyvault-provider csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system \
  --set secrets-store-csi-driver.enableSecretRotation=true \
  --set secrets-store-csi-driver.syncSecret.enabled=true
```

### Validation

```bash
kubectl exec -it nginx-demo-dc6d75f7c-6mhfp -- env | grep DB_PASSWORD
DB_PASSWORD=real-secret-managed-by-keyvault
```

Value originated in Azure Key Vault. No credentials stored in the cluster. Workload identity token exchange confirmed working.

### How Workload Identity Works

```
Pod (nginx-demo-sa service account)
    │
    │  Projected service account token (OIDC)
    ▼
Azure AD — validates federated credential subject match
    │
    │  Access token for managed identity
    ▼
Azure Key Vault — RBAC: Key Vault Secrets User
    │
    │  Secret value
    ▼
CSI driver creates Kubernetes secret → injected as env var
```

---

## 3. Pending Items

| Item                                      | When            |
| ----------------------------------------- | --------------- |
| AGIC — eliminate manual backend IP update | Week 17         |
| Helm chart for nginx-demo manifests       | Week 17         |
| `upgrade_settings` on both node pools     | Week 17         |
| Monitoring alerts wired to real data      | Week 18 wrap-up |
| Cost Management + Budget Alerts           | Week 20         |

---

## 4. Concepts Covered

- **Application Gateway** — L7 load balancer, WAF capable, hub ingress pattern
- **Standard_v2 SKU** — required for zone redundancy and autoscaling in production
- **TLS policy** — `AppGwSslPolicy20220101` enforces TLS 1.2 minimum
- **OIDC issuer** — enables federated identity between AKS and Azure AD
- **Workload identity** — pod-level managed identity, no secrets in cluster
- **Federated credential** — subject claim scopes identity to specific service account
- **CSI Secrets Store** — mounts Key Vault secrets as volumes, syncs to Kubernetes secrets
- **syncSecret.enabled** — required for CSI driver to create Kubernetes secrets from Key Vault values
- **Key Vault RBAC** — `enable_rbac_authorization = true` replaces legacy access policies
