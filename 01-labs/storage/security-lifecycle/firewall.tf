# Note: configure the firewall via Azure CLI after Private Endpoint is ready
# This is because Terraform can lock you me if not careful

# Output the commands to run manually
output "firewall_commands" {
  description = "Run these commands to configure storage firewall after Private Endpoint is ready"
  value       = <<-EOT
    
    # After Private Endpoint is working, restrict public access:
    
    # 1. First, test private endpoint connectivity from VM
    
    # 2. Then deny public access (keep Azure services allowed for Terraform state):
    az storage account update \
      --name ${var.storage_account_name} \
      --resource-group rg-moshstaq-lab-project \
      --default-action Deny \
      --bypass AzureServices
    
    # 3. Add your current IP for CLI access:
    MY_IP=$(curl -4 -s ifconfig.me)
    az storage account network-rule add \
      --account-name ${var.storage_account_name} \
      --resource-group rg-moshstaq-lab-project \
      --ip-address $MY_IP
    
    # To revert (allow all):
    az storage account update \
      --name ${var.storage_account_name} \
      --resource-group rg-moshstaq-lab-project \
      --default-action Allow
    
  EOT
}
