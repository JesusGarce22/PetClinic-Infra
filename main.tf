# Provider configuration
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

provider "azuread" {}

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# AKS module
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

# AKS and ACR role assignment
resource "azurerm_role_assignment" "aks_acr_role_assignment" {
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id

  depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

