variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for storage account"
  type        = string
  default     = "rg-app-dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}

variable "vnet_name" {
  description = "Virtual network name"
  type        = string
  default     = "vnet-app-dev"
}

variable "subnet_name" {
  description = "Subnet for Private Endpoint"
  type        = string
  default     = "snet-data"
}

variable "container_name" {
  description = "Name of the blob container"
  type        = string
  default     = "uploads"
}

variable "lifecycle_delete_days" {
  description = "Days after which blobs are deleted"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Environment = "dev"
    Project     = "azure-learning-lab"
    Week        = "10"
  }
}
