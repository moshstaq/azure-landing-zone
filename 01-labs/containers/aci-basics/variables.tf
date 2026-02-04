variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project identifier"
  type        = string
  default     = "moshstaq"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "Azure-Learning-Lab"
    Environment = "dev"
    Week        = "6"
    Lab         = "6.1-aci-basics"
    ManagedBy   = "Terraform"
  }
}

# Container configuration
variable "container_cpu" {
  description = "CPU cores for container"
  type        = number
  default     = 0.5
}

variable "container_memory" {
  description = "Memory in GB for container"
  type        = number
  default     = 0.5
}
