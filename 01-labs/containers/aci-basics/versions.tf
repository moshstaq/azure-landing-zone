terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-moshstaq-tfstate"
    storage_account_name = "stmoshstaqtfstm0n4"
    container_name       = "tfstate"
    key                  = "aci-basics.tfstate"
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}
