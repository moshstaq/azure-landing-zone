variable "your_name" {
  description = "Your name/identifier for resource naming"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}

variable "alert_email" {
  description = "Email for budget alerts"
  type        = string
}
