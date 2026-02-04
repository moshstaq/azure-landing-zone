#---------------------------------------------------------------
# Resource Group for Container Labs
#---------------------------------------------------------------
resource "azurerm_resource_group" "containers" {
  name     = "rg-${var.project_name}-lab-containers"
  location = var.location
  tags     = var.tags
}

#---------------------------------------------------------------
# ACI Container Group 1: Hello World (Always restart)
#---------------------------------------------------------------
resource "azurerm_container_group" "helloworld" {
  name                = "aci-${var.project_name}-helloworld"
  location            = azurerm_resource_group.containers.location
  resource_group_name = azurerm_resource_group.containers.name
  os_type             = "Linux"

  # Public IP and DNS for easy access
  ip_address_type = "Public"
  dns_name_label  = "aci-${var.project_name}-hello"

  # Restart policy: Always (keep running)
  restart_policy = "Always"

  container {
    name   = "helloworld"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = var.container_cpu
    memory = var.container_memory

    ports {
      port     = 80
      protocol = "TCP"
    }

    # Environment variables
    environment_variables = {
      "ENVIRONMENT" = var.environment
      "DEPLOYED_BY" = "Terraform"
    }
  }

  tags = var.tags
}

#---------------------------------------------------------------
# ACI Container Group 2: Batch Job (Never restart)
# This demonstrates a one-time task pattern
#---------------------------------------------------------------
resource "azurerm_container_group" "batchjob" {
  name                = "aci-${var.project_name}-batchjob"
  location            = azurerm_resource_group.containers.location
  resource_group_name = azurerm_resource_group.containers.name
  os_type             = "Linux"

  # No public IP needed for batch jobs
  ip_address_type = "None"

  # Never restart - run once and stop
  restart_policy = "Never"

  container {
    name = "batchjob"
    # Using busybox for a simple task
    image  = "mcr.microsoft.com/azure-cli:latest"
    cpu    = var.container_cpu
    memory = var.container_memory

    # Simple command that runs and exits
    commands = [
      "/bin/sh",
      "-c",
      "echo 'Batch job started at $(date)' && echo 'Processing...' && sleep 30 && echo 'Batch job completed at $(date)' && echo 'Exit code: 0'"
    ]

    environment_variables = {
      "JOB_ID"   = "batch-001"
      "JOB_TYPE" = "demo"
    }
  }

  tags = merge(var.tags, {
    Purpose = "Batch-Job-Demo"
  })
}

#---------------------------------------------------------------
# ACI Container Group 3: Multi-Container (Sidecar Pattern)
# Demonstrates containers sharing network namespace
#---------------------------------------------------------------
resource "azurerm_container_group" "multicontainer" {
  name                = "aci-${var.project_name}-multi"
  location            = azurerm_resource_group.containers.location
  resource_group_name = azurerm_resource_group.containers.name
  os_type             = "Linux"

  ip_address_type = "Public"
  dns_name_label  = "aci-${var.project_name}-multi"
  restart_policy  = "Always"

  # Main application container
  container {
    name   = "webapp"
    image  = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
    cpu    = 0.5
    memory = 0.5

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  # Sidecar container - monitors the main app
  # In real scenarios: logging, metrics, service mesh proxy
  container {
    name   = "sidecar"
    image  = "mcr.microsoft.com/azure-cli:latest"
    cpu    = 0.25
    memory = 0.1

    # Sidecar can access main container via localhost
    commands = [
      "/bin/sh",
      "-c",
      "while true; do echo \"[$(date)] Health check: $(curl -s -o /dev/null -w '%%{http_code}' http://localhost:80 || echo 'FAILED')\"; sleep 60; done"
    ]
  }

  tags = merge(var.tags, {
    Purpose = "Multi-Container-Demo"
  })
}
