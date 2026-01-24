variable "prefix" {
  description = "Your prefix (same as foundation)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}
