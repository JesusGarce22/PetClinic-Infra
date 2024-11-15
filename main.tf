# Provider
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}

# Crear el grupo de recursos
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Crear la cuenta de almacenamiento
resource "azurerm_storage_account" "tfstate" {
  name                     = "divergenciaSA"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Crear el contenedor de almacenamiento para el estado remoto
resource "azurerm_storage_container" "tfstate" {
  name                  = "terraform-state"
  storage_account_name  = azurerm_storage_account.tfstate.name
  container_access_type = "private"
}

# Módulo AKS
module "aks" {
  source              = "./modules/aks"
  aks_cluster_name    = var.aks_cluster_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix
  node_count          = var.node_count
  vm_size             = var.vm_size
}

# Módulo ACR
module "acr" {
  source              = "./modules/acr"
  acr_name            = var.acr_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Módulo Key Vault
module "keyvault" {
  source              = "./modules/keyvault"
  key_vault_name      = var.key_vault_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = var.tenant_id
  object_id           = "7c8ab49a-20e5-46a5-a434-3ad3ec71335c"
}

# Asignación de roles para AKS y ACR
resource "azurerm_role_assignment" "aks_acr_role_assignment" {
  principal_id         = module.aks.kubelet_identity_object_id
  role_definition_name = "AcrPull"
  scope                = module.acr.acr_id

  depends_on = [module.aks]
}