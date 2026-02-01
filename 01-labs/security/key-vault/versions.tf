terraform {
  required_version = ">= 1.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-moshstaq-tfstate"
    storage_account_name = "stmoshstaqtfstm0n4"
    container_name       = "tfstate"
    key                  = "key-vault.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Important: Allows Terraform to purge soft-deleted vaults
      # Set to true in production to prevent accidental purge
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}
