variable "your_name" {
  description = "Your prefix (same as foundation)"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "vm_size" {
  description = "Vm size - B1s is a low cost option for testing"
  type        = string
  default     = "Standard_B1s"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key file"
  type        = string
  default     = "~/.ssh/azure-lab-vm.pub"
}

variable "auto_shutdown_time" {
  description = "Daily auto-shutdown time in UTC (HH:MM format)"
  type        = string
  default     = "2300"
}

variable "tags" {
  description = "A map of tags to assign to resources"
  type        = map(string)
  default = {
    Lab         = "3.1-vm-linux"
    Environment = "dev"
    Project     = "azure-learning"
    ManagedBy   = "terraform"
  }
}
