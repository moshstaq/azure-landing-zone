Enterprise Security Pattern
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

1. Zero Trust Network Access
   └── Public internet blocked (firewall: Deny)
   └── Only Private Endpoint access allowed
   └── Traffic never leaves Azure backbone

2. Identity-Based Security
   └── No storage keys or connection strings
   └── Managed Identity for authentication
   └── RBAC for authorization

3. Least Privilege
   └── VM can READ but not WRITE
   └── Minimal permissions = reduced blast radius

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

WEEK 10 COMPLETE
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Resources Deployed:
├── stappdevmy20wp (Storage Account)
├── uploads (Blob Container)
├── pe-stappdevmy20wp-blob (Private Endpoint)
├── privatelink.blob.core.windows.net (DNS Zone)
├── RBAC: VM → Storage Blob Data Reader
└── Lifecycle Policy: Delete after 30 days

Patterns Learned:
├── Private Endpoint for Storage and Keyvault
├── Separate network_rules resource
├── Lifecycle policies for cost management
└── Testing RBAC with curl + Managed Identity

State File: lz-app-dev-storage.tfstate
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
