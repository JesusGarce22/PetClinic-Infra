variable "key_vault_name" {
  type        = string
  description = "Name of the Azure Key Vault"
}

variable "location" {
  type        = string
  description = "Location of the resources"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "tenant_id" {
  type        = string
  description = "Azure tenant id"
}

variable "object_id" {
  type        = string
  description = "Object id for the access policy"
}