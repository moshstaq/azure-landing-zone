

data "azurerm_resource_group" "spoke_dev" {
  name = "rg-spoke-dev"
}

data "azurerm_virtual_machine" "vm" {
  name                = "vm-${var.environment}-001"
  resource_group_name = data.azurerm_resource_group.lab_compute.name
}


data "azurerm_resource_group" "lab_compute" {
  name = "rg-moshstaq-lab-compute"
}
