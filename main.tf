provider "azuread" {}

# Backend for Terraform state file
resource "azurerm_resource_group" "terraformbackend" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "terraform_backend" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.terraformbackend.name
  location                 = azurerm_resource_group.terraformbackend.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_account_replication_type
}

resource "azurerm_storage_container" "terraform_backend" {
  name                  = var.storage_container_name
  storage_account_name  = azurerm_storage_account.terraform_backend.name
  container_access_type = var.container_access_type
}

# AKS modules
module "aks" {
  source              = "./modules/aks"
  aks_cluster_name    = var.aks_cluster_name
  location            = var.location
  resource_group_name = azurerm_resource_group.terraformbackend.name
  dns_prefix          = var.dns_prefix
  node_count          = var.node_count
  vm_size             = var.vm_size
}

# ACR module
module "acr" {
  source              = "./modules/acr"
  acr_name            = var.acr_name
  location            = var.location
  resource_group_name = azurerm_resource_group.terraformbackend.name
}

# Key Vault module
module "keyvault" {
  source              = "./modules/keyvault"
  key_vault_name      = var.key_vault_name
  location            = var.location
  resource_group_name = azurerm_resource_group.terraformbackend.name
  tenant_id           = var.tenant_id
  object_id           = "7c8ab49a-20e5-46a5-a434-3ad3ec71335c"
}

# Role Assignment AKS y ACR
resource "azurerm_role_assignment" "aks_acr_role_assignment" {
  principal_id         = module.aks.kubelet_identity_object_id
  role_definition_name = "AcrPull"
  scope                = module.acr.acr_id
}