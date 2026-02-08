variable "management_group_name" {
  description = "Root management group where policies will be assigned"
  type        = string
  default     = "moshstaq"
}

variable "allowed_locations" {
  description = "List of allowed Azure regions"
  type        = list(string)
  default     = ["eastus2"]
}

variable "required_tag_name" {
  description = "Tag that must exist on resource groups"
  type        = string
  default     = "Environment"
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace for diagnostic settings policy"
  type        = string
}
