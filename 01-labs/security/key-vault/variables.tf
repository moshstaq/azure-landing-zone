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

variable "project" {
  description = "Project name"
  type        = string
  default     = "moshstaq-lab"
}

variable "vm_principal_id" {
  description = "Principal ID of vm-dev-001 managed identity"
  type        = string
  default     = "36e9322f-74f7-4bbf-a98c-cc11106c1591"
}

variable "soft_delete_retention_days" {
  description = "Days to retain soft-deleted secrets (7-90)"
  type        = number
  default     = 7
}
