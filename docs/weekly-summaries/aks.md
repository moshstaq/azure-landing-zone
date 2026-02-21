Architecture decisions and diagrams → [`docs/architecture.md`](docs/architecture.md)

**Session Focus:** AKS rebuild, Kubernetes concepts

## 1. AKS — Rebuilt

Cluster reprovisioned with corrections from original build:

- `node_labels` moved inside `default_node_pool` block (was incorrectly at cluster level)
- Labels applied: `nodepool-type=system` and `nodepool-type=workload`
- Stale comment removed from workload pool
- Kubeconfig updated with `--overwrite-existing` after fresh provision (old FQDN cached)

Validated:

- Both nodes Ready, Azure CNI pod IPs from `snet-aks` (10.1.4.x)
- `nodepool-type` labels confirmed on both nodes via `kubectl get nodes --show-labels`

---

## 2. AKS — ConfigMaps, Secrets, Ingress

### Manifests created in `aks/manifests/`

**configmap.yaml**

- Injects `APP_ENV`, `APP_REGION`, `LOG_LEVEL`, `WELCOME_MESSAGE` as environment variables
- Uses `envFrom.configMapRef` pattern

**secret.yaml**

- Injects `DB_PASSWORD`, `API_KEY` using `stringData` (Kubernetes handles base64 encoding)
- Placeholder values only — will be replaced with Key Vault in Week 16

**deployment.yaml**

- 2 replicas, `nodeSelector: nodepool-type=workload`
- ConfigMap injected via `envFrom`
- Secret injected via `env.valueFrom.secretKeyRef`
- Resource requests/limits set explicitly

**ingress.yaml**

- `ingressClassName: nginx`
- Routes all traffic (`/`) to `nginx-demo` service on port 80

### Errors hit and resolved

- `ConfigMap` applied with `apiVersion: apps/v1` — fixed to `v1`
- `ConfigMapRef` capitalisation error in deployment — fixed to `configMapRef`

### Validation

- `kubectl exec` confirmed all 5 env vars present inside pod
- NGINX ingress controller installed via Helm, pinned to system node via `nodeSelector`
- Controller logs confirmed `200` responses and load balancing across both pod IPs
- External `curl` timed out — confirmed as NSG blocking internet inbound (correct behaviour)
- Azure Load Balancer health probe traffic visible in logs from inside VNet

### Key architectural decision

Decided against adding `Allow-Internet` NSG rule on `snet-aks`. Internet traffic should flow through Application Gateway in hub VNet, not directly into spoke subnet. This preserves hub-spoke trust boundary.

---

## 3. Networking NSG — Corrected

Added explicit inbound rule to `nsg-app-dev-aks`:

- Source: `10.0.0.0/16` (hub VNet only)
- Documents intent in code rather than relying on default `AllowVnetInBound` rule
- Internet remains blocked by default deny at priority 65500

**Rationale:** Default `AllowVnetInBound` is broader than intended — covers all peered VNets and future additions. Explicit rule scoped to hub CIDR matches least-privilege standard held elsewhere in the repo.

---

## 4. Pending Items

| Item                                                  | When |
| ----------------------------------------------------- | ---- |
| Application Gateway in hub VNet                       |
| Workload Identity + Key Vault integration             |
| Replace dummy Secret with Key Vault reference         |
| Validate platform alerts with real Log Analytics data |
| Additional projects discussion (post-roadmap)         |

---

## 5. Concepts Covered

- **ConfigMap** — externalise non-sensitive config from container image, injected as env vars
- **Secret** — sensitive values, base64 encoded, injected individually via `secretKeyRef`
- **Ingress** — single load balancer, path-based routing, TLS termination point
- **Helm** — package manager for Kubernetes, used to install ingress-nginx controller
- **Node labels vs taints** — labels enable optional scheduling preference, taints enforce exclusion
- **NSG default rules** — `AllowVnetInBound` at 65000 vs explicit rules for documented intent
- **Hub-spoke trust boundary** — internet traffic should enter via hub shared services, not spoke subnets directly
