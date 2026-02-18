variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "eastus2"
}


variable "alert_email" {
  description = "Email address for platform alert notifications"
  type        = string
}
