# Week 4: Security - Key Learnings

## Lab 4.1: Key Vault

### What Key Vault Stores

|
Type
|
Example
|
|

---

## |

|
|
Secrets
|
Passwords, API keys, connection strings
|
|
Keys
|
Encryption keys
|
|
Certificates
|
TLS/SSL certs
|

### Access Models

- **Access Policies**: Legacy, avoid
- **RBAC**: Recommended ✅ (granular, auditable, inheritable)

### Key Vault Roles

|
Role
|
Use Case
|
|

---

## |

|
|
Key Vault Secrets User
|
Apps that read secrets
|
|
Key Vault Secrets Officer
|
Admins who manage secrets
|
|
Key Vault Administrator
|
Full control
|

### Data Protection

- **Soft Delete**: Recover accidentally deleted items (7-90 days)
- **Purge Protection**: Even admins can't permanently delete

### Interview Points

- "I use RBAC for Key Vault - granular, inheritable, auditable"
- "Managed Identity + Key Vault = secretless authentication"
- "Soft delete protects against accidental deletion"
- "Secrets User for apps, Secrets Officer for admins"

---

## Lab 4.2: Private Endpoints

### Why Private Endpoints?

Without PE: App → Internet → Azure PaaS (public IP) ⚠️
With PE: App → VNet → Private IP → Azure PaaS ✅

text
Traffic never leaves Azure backbone.

### Components

| Component        | Purpose                            |
| ---------------- | ---------------------------------- |
| Private Endpoint | NIC with private IP in your subnet |
| Private DNS Zone | Resolves FQDN to private IP        |
| VNet Link        | Connects DNS zone to your VNet     |

### DNS Zones to Memorize

| Service      | Zone                              |
| ------------ | --------------------------------- |
| Key Vault    | privatelink.vaultcore.azure.net   |
| Storage Blob | privatelink.blob.core.windows.net |
| SQL Database | privatelink.database.windows.net  |

### Troubleshooting Steps

1. **DNS**: `nslookup <service>.azure.net` → Should return private IP
2. **Layer 4**: `nc -zv <private-ip> 443` → Test TCP connectivity
3. **NSG**: Check rules allow traffic between subnets
4. **Layer 7**: `curl https://<service>` → Test application layer

### Critical Lesson (from Week 5)

- NSG must explicitly allow traffic to Private Endpoint subnet
- Deny-all rules block inter-subnet traffic including to PEs
- Add rule: Allow HTTPS (443) from app subnet to data subnet

### Interview Points

- "Private Endpoints bring PaaS into the VNet with a private IP"
- "Traffic stays on Azure backbone, never touches public internet"
- "Private DNS Zones resolve service names to private IPs"
- "NSGs must allow traffic to PE subnets - common troubleshooting issue"

---

## Lab 4.3: Load Balancer

### LB Types

| Type                | Layer        | Use Case               |
| ------------------- | ------------ | ---------------------- |
| Standard LB         | L4 (TCP/UDP) | Basic load balancing   |
| Application Gateway | L7 (HTTP)    | SSL, WAF, path routing |

### Components

Frontend IP → LB Rule → Backend Pool
↓
Health Probe

text

### Health Probe Tuning

Detection Time = Interval × Unhealthy Threshold
Example: 15s × 2 = 30 seconds to mark unhealthy

text

- Slow-starting apps: Increase interval or threshold
- Fast detection needed: Decrease interval (more probe traffic)

### Key Behaviors

- Automatic failover when health probe fails
- Automatic recovery when VM becomes healthy
- Session persistence can route all traffic to one VM (by design)

### Interview Points

- "Standard LB required for VMs without public IPs"
- "Health probe detection time = interval × threshold"
- "Layer 4 for TCP/UDP, Application Gateway for HTTP with WAF"
- "Automatic failover on health probe failure, automatic recovery when healthy"
