terraform {
  backend "azurerm" {
    resource_group_name  = "az_rg"
    storage_account_name = "divergencia"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
  }
}

provider "azurerm" {
  features {}

  subscription_id            = var.subscription_id
  skip_provider_registration = true
}