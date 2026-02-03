# Week 5: Azure Storage - Summary

## Labs Completed

- Lab 5.1: Storage Fundamentals + Blob Tiers
- Lab 5.2: Access Patterns (SAS, Keys, Entra ID)
- Lab 5.3: Storage Security + Lifecycle Management

## Key Learnings

### Control Plane vs Data Plane

- **Control Plane**: Contributor role - create/manage resources
- **Data Plane**: Storage Blob Data \* roles - read/write data
- Common gotcha: Contributor ≠ blob access!

### Access Methods (Best → Worst)

1. **Entra ID + Managed Identity** - No credentials, auditable ✅
2. **SAS Tokens** - Time-limited, scoped (external access)
3. **Access Keys** - Avoid! Like master passwords ⚠️

### Private Endpoints

- Bring PaaS services into your VNet (private IP)
- Require Private DNS Zone for name resolution
- NSG must allow traffic between subnets!
- Troubleshooting: nslookup → nc -zv → az storage

### Storage Firewall

- Default Deny + allow specific IPs/VNets
- `bypass=AzureServices` for Terraform, Backup, etc.
- Private Endpoint bypasses firewall entirely

### Lifecycle Management

- Automates tier transitions (Hot → Cool → Archive)
- Filter by prefix, blob type
- Reduces cost without manual intervention

## Troubleshooting Wins

1. RBAC error → Needed Storage Blob Data Contributor (data plane)
2. PE timeout → NSG blocking traffic between subnets
3. Added Allow-HTTPS-From-App-Subnet rule → Fixed!

## Interview Talking Points

1. "I implement secretless authentication using Managed Identity with RBAC"
2. "Storage is secured with Private Endpoints - no public internet exposure"
3. "Lifecycle policies automate cost optimization: Hot → Cool → Archive"
4. "Control plane vs data plane - Contributor doesn't grant blob access"

## Architecture

- Storage: stmoshstaqlabjlq3
- Private Endpoint: 10.1.2.4 (snet-data)
- Firewall: Deny public, allow my IP + Azure services
- Access: VM uses MI via PE, CLI uses IP allowlist
