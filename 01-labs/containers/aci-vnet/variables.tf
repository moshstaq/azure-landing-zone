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
    Lab         = "6.2-aci-vnet"
    ManagedBy   = "Terraform"
  }
}

# Network configuration
variable "container_subnet_cidr" {
  description = "CIDR for container subnet"
  type        = string
  default     = "10.1.3.0/24"
}
