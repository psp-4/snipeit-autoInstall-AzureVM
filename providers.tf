// Specifying provider dependencies
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

// Specifying the provider
provider "azurerm" {
  features {}
}