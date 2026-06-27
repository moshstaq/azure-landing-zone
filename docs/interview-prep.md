```markdown
# Interview Questions I Can Now Answer

## Governance & Organization

**Q: How would you organize resources in Azure for an enterprise?**

> I'd use a management group hierarchy to enable policy inheritance. At the top level, separate Platform (shared infrastructure) from Workloads (application teams). Under Workloads, I might further segment by environment (dev/test/prod) or by business unit. Each team gets their own subscription as a blast radius boundary, with policies inherited from parent management groups.

**Q: What's the difference between management groups and resource groups?**

> Management groups are for organizing subscriptions and applying policies at scale - they're an administrative boundary. Resource groups are for organizing resources within a subscription based on lifecycle - resources that deploy together, live together, and get deleted together. For example, I might have a management group for "Production Workloads" containing multiple subscriptions, and within each subscription, resource groups like "rg-app-networking" and "rg-app-compute".

**Q: How do you enforce compliance in Azure?**

> Azure Policy. I start with policies in audit mode to understand the current state and impact, then move to deny effect for critical controls. I'd implement policies for things like: required tags, allowed regions, allowed VM SKUs, encryption requirements, and network security baselines. Policies assigned at management group level automatically apply to all child subscriptions.

---

## Identity & Security

**Q: Why use a Service Principal for Terraform instead of your user account?**

> Three reasons: separation of concerns, least privilege, and auditability. A Service Principal has only the permissions it needs - typically Contributor for resource creation. If those credentials were compromised, the blast radius is limited to what the SP can do. Also, in audit logs, I can clearly distinguish between automated changes (SP) and manual changes (user accounts). It's how enterprises operate, so building this habit now is important.

**Q: What permissions does a Terraform Service Principal need?**

> It depends on what Terraform manages. For my learning lab, the SP has:
>
> - **Contributor** at subscription scope - create and manage resources
> - **User Access Administrator** - assign RBAC roles to resources
> - **Groups Administrator** in Entra ID - create and manage groups
>
> In production, I'd scope these tighter - maybe Contributor only on specific resource groups, with a separate SP for identity operations.

---

## Infrastructure as Code

**Q: How do you handle Terraform state securely?**

> Remote state in Azure Storage Account with:
>
> - Versioning enabled for recovery
> - Encryption at rest (default in Azure)
> - Access limited to the Terraform Service Principal
> - Separate containers for different components (foundation, labs, etc.)
> - State locking via Azure blob leases to prevent concurrent modifications

**Q: What's your approach to structuring Terraform code?**

> I separate concerns:
>
> - `versions.tf` - provider and Terraform version constraints
> - `variables.tf` - input variables with validation
> - `main.tf` - primary resources
> - `outputs.tf` - values needed by other configurations or users
> - `terraform.tfvars` - environment-specific values (not committed to git)
>
> For larger projects, I split by resource type (network.tf, compute.tf) or use modules for reusable patterns.

**Q: You mentioned a deployment failed due to missing tags. Walk me through that.**

> I had an Azure Policy requiring an "Environment" tag on resources. When I deployed a VM lab without tags, the policy denied the deployment. The fix was adding a `tags` block to every resource. I actually improved this by creating a `local.common_tags` map and referencing it everywhere - DRY principle.
>
> This taught me that policies work, and why you should test in audit mode first before enforcing deny. It also showed me the importance of consistent tagging from the start.

---

## Cost Management

**Q: How do you control cloud costs?**

> Multiple layers:
>
> 1. **Budget alerts** - I set a $20/month budget with alerts at 50%, 80%, and 100%
> 2. **Auto-shutdown** - VMs automatically shut down at 7 PM daily
> 3. **Right-sizing** - Using B1s (free tier) for learning instead of larger SKUs
> 4. **Cleanup discipline** - `terraform destroy` after each lab session
> 5. **Policy guardrails** - Could add policies to block expensive SKUs if needed

**Q: What's the most expensive mistake you could make in Azure?**

> For my learning lab? Leaving an AKS cluster or Application Gateway running 24/7 - those can be $30+/day easily. Or accidentally deploying Azure Firewall at $900+/month. That's why I have budget alerts and always check Cost Management after deploying something new.
```
