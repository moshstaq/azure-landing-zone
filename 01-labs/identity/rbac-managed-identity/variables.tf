variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}


variable "lab_admins_group_id" {
  description = "Object ID of moshstaq-Lab-Admins group"
  type        = string
}

variable "lab_readers_group_id" {
  description = "Object ID of moshstaq-Lab-Readers group"
  type        = string
}
