terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.80"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "~> 1.13"
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
    key                  = "nsg-spoke-dev.tfstate"
  }
}

provider "azurerm" {
  features {}
}

provider "azapi" {}
