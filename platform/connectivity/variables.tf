variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}

variable "nva_private_ip" {
  description = "Static private IP assigned to the NVA NIC in snet-nva. Used as next-hop in spoke UDRs."
  type        = string
  default     = "10.0.3.4"
}

variable "nva_subnet_cidr" {
  description = "CIDR for the NVA subnet in vnet-hub"
  type        = string
  default     = "10.0.3.0/28"
}
