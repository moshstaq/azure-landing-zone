variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Azure region for ACI deployment"
  type        = string
  default     = "eastus2"
}

variable "resource_group_name" {
  description = "Resource group for ACI deployment"
  type        = string
}

variable "container_group_name" {
  description = "Name of the container group"
  type        = string
}

variable "container_name" {
  description = "Name of the container instance"
  type        = string
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

variable "subnet_id" {
  description = "Subnet ID for ACI deployment"
  type        = string
}
