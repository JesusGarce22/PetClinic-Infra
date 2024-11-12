# Provider configuration
provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "azuread" {}

# Resource group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Azure Key Vault
resource "azurerm_key_vault" "key_vault" {
  name                     = var.key_vault_name
  location                 = azurerm_resource_group.rg.location
  resource_group_name      = azurerm_resource_group.rg.name
  tenant_id                = var.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = true

  access_policy {
    tenant_id = var.tenant_id
    object_id = "7c8ab49a-20e5-46a5-a434-3ad3ec71335c"

    secret_permissions = ["Get", "List"]
  }

  tags = {
    environment = "Dev"
  }

   depends_on = [azurerm_kubernetes_cluster.aks_cluster]
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "aks_cluster" {
  name                = var.aks_cluster_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = var.dns_prefix

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }

  tags = {
    environment = "Production"
  }
}

# Azure Container Registry
resource "azurerm_container_registry" "acr" {
  name                = var.acr_name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# AKS and ACR role assignment
resource "azurerm_role_assignment" "aks_acr_role_assignment" {
  principal_id         = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = azurerm_container_registry.acr.id
}