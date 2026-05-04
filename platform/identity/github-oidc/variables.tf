variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "tenant_id" {
  description = "Azure AD tenant ID"
  type        = string
}

variable "github_org" {
  description = "GitHub organization or username"
  type        = string
}

variable "repos" {
  description = "Map of GitHub repositories to provision OIDC service principals for. Key must match the exact GitHub repository name."
  type = map(object({
    display_name = string
  }))
}

variable "environment" {
  description = "Environment tag"
  type        = string
  default     = "platform"
}
