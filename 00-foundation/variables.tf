# variables.tf

variable "your_name" {
  description = "Your name/alias (lowercase, 2-10 chars)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,10}$", var.your_name))
    error_message = "Must be 2-10 lowercase alphanumeric characters."
  }
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
