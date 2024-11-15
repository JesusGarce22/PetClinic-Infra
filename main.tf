#tf remote backend
terraform {
  backend "azurerm" {
    resource_group_name  = "az_rg"
    storage_account_name = "divergenciaSA"
    container_name       = "terraform-state"
    key                  = "terraform.tfstate"
  }
}

# AKS modules
module "aks" {
  source              = "./modules/aks"
  aks_cluster_name    = var.aks_cluster_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix
  node_count          = var.node_count
  vm_size             = var.vm_size
}

# ACR module
module "acr" {
  source              = "./modules/acr"
  acr_name            = var.acr_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Key Vault module
module "keyvault" {
  source              = "./modules/keyvault"
  key_vault_name      = var.key_vault_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = var.tenant_id
  object_id           = "7c8ab49a-20e5-46a5-a434-3ad3ec71335c"
}

# Role Assignment AKS y ACR
resource "azurerm_role_assignment" "aks_acr_role_assignment" {
  principal_id         = module.aks.kubelet_identity_object_id
  role_definition_name = "AcrPull"
  scope                = module.acr.acr_id

  depends_on = [module.aks]
}