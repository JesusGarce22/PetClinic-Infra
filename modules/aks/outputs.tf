output "kubelet_identity_object_id" {
  value = azurerm_kubernetes_cluster.aks_cluster.kubelet_identity[0].object_id
}