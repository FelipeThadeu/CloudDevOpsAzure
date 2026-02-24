output "cluster_id" {
  description = "ID do cluster AKS"
  value       = azurerm_kubernetes_cluster.main.id
}

output "cluster_name" {
  description = "Nome do cluster AKS"
  value       = azurerm_kubernetes_cluster.main.name
}

output "kube_config_raw" {
  description = "Configuração kubeconfig (para kubectl)"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "kube_config" {
  description = "Bloco kube_config para uso pelo provider Kubernetes"
  value       = azurerm_kubernetes_cluster.main.kube_config
  sensitive   = true
}

output "host" {
  description = "Kubernetes API endpoint"
  value       = azurerm_kubernetes_cluster.main.kube_config[0].host
  sensitive   = true
}
