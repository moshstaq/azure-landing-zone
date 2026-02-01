# Reference existing resources
data "azurerm_virtual_machine" "vm" {
  name                = "vm-dev-001"
  resource_group_name = "rg-moshstaq-lab-compute"
}

data "azurerm_resource_group" "monitoring" {
  name = "rg-moshstaq-lab-monitoring"
}

data "azurerm_log_analytics_workspace" "main" {
  name                = "law-moshstaq-main"
  resource_group_name = "rg-moshstaq-platform-core"
}
