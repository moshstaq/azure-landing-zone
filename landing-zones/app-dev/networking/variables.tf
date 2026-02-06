variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}

variable "hub_vnet_id" {
  description = "Resource ID of the hub VNet for peering"
  type        = string
}

variable "hub_vnet_name" {
  description = "Name of the hub VNet for peering"
  type        = string
}

variable "hub_resource_group_name" {
  description = "Resource group name of the hub VNet"
  type        = string
}
