variable "location" {
  description = "Azure region for ACI deployment"
  type        = string
  default     = "eastus2"
}

variable "container_group_name" {
  description = "Name of the container group"
  type        = string
  default     = "cg-app-dev"
}

variable "container_name" {
  description = "Name of the container instance"
  type        = string
  default     = "aci-helloworld"
}

variable "container_image" {
  description = "Container image to deploy"
  type        = string
  default     = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
}

variable "cpu_cores" {
  description = "CPU cores for container"
  type        = number
  default     = 0.5
}

variable "memory_gb" {
  description = "Memory in GB for container"
  type        = number
  default     = 0.5
}
