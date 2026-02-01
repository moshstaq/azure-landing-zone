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

variable "alert_email" {
  description = "Email for alert notifications"
  type        = string
  default     = ""
}
