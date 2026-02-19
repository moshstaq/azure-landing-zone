resource "azurerm_kubernetes_cluster" "this" {
  name                = "aks-app-dev"
  location            = data.terraform_remote_state.networking.outputs.location
  resource_group_name = data.terraform_remote_state.networking.outputs.resource_group_name
  dns_prefix          = "aks-app-dev"


  identity {
    type = "SystemAssigned"
  }


  default_node_pool {
    name            = "system"
    node_count      = 1
    vm_size         = "Standard_B2s"
    vnet_subnet_id  = data.terraform_remote_state.networking.outputs.snet_aks_id
    os_disk_size_gb = 30
    max_pods        = 30


    os_sku = "AzureLinux"
  }

  # Azure CNI for VNet integration
  network_profile {
    network_plugin    = "azure"
    network_policy    = "azure"
    service_cidr      = "10.2.0.0/16"
    dns_service_ip    = "10.2.0.10"
    load_balancer_sku = "standard"
  }


  oms_agent {
    log_analytics_workspace_id = data.azurerm_log_analytics_workspace.platform.id
  }

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}


resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = "Standard_B2s"
  node_count            = 1
  vnet_subnet_id        = data.terraform_remote_state.networking.outputs.snet_aks_id
  os_disk_size_gb       = 30
  max_pods              = 30
  os_sku                = "AzureLinux"

  # Taint system pool so apps schedule on workload pool
  node_taints = []

  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
}
