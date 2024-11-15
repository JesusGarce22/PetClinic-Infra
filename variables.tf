variable "tenant_id" {
  type        = string
  description = "Azure tenant id"
}

variable "subscription_id" {
  type        = string
  description = "Azure subscription id"
}

variable "resource_group_name" {
  type    = string
  default = "az_rg"
}

variable "location" {
  type    = string
  default = "eastus"
}


variable "storage_account_name" {
  type    = string
  default = "divergencia"
}

variable "storage_account_tier" {
  type    = string
  default = "Standard"
}

variable "storage_account_replication_type" {
  type    = string
  default = "LRS"
}


variable "storage_container_name" {
  type    = string
  default = "terraform-state"
}

variable "container_access_type" {
  type    = string
  default = "blob"
}

variable "aks_cluster_name" {
  type        = string
  description = "Name AKS cluster"
  default     = "aks_cn"
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the cluster"
  default     = "clt"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the cluster"
  default     = 1
}

variable "vm_size" {
  type        = string
  description = "Size of the virtual machine nodes"
  default     = "standard_b4pls_v2"
}

variable "acr_name" {
  type        = string
  description = "Name of the Azure Container Registry"
  default     = "divergencia"
}

variable "key_vault_name" {
  type        = string
  description = "Name of the Azure Key Vault"
  default     = "divergenciakeyvault"
}
