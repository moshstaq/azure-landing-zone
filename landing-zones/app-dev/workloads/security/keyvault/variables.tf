variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group for Key Vault resources"
  type        = string
  default     = "rg-app-dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

variable "keyvault_name_prefix" {
  description = "Prefix for Key Vault name (suffix will be random for uniqueness)"
  type        = string
  default     = "kv-appdev"
}

variable "keyvault_sku" {
  description = "Key Vault SKU - standard or premium"
  type        = string
  default     = "standard"
}

variable "deployment_ip" {
  description = "Your public IP for temporary Key Vault access during deployment"
  type        = string
}
