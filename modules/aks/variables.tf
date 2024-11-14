variable "aks_cluster_name" {
  type        = string
  description = "Name of the AKS cluster"
}

variable "location" {
  type        = string
  description = "Location of the resources"
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group"
}

variable "dns_prefix" {
  type        = string
  description = "DNS prefix for the cluster"
}

variable "node_count" {
  type        = number
  description = "Number of nodes in the cluster"
}

variable "vm_size" {
  type        = string
  description = "Size of the virtual machine nodes"
}