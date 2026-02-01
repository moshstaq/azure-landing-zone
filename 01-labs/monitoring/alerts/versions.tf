terraform {
  required_version = ">= 1.5.0"

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
    key                  = "monitoring-alerts.tfstate"
  }
}

provider "azurerm" {
  features {}
}
