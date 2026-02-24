# ============ KUBERNETES CLUSTER ============

output "kubernetes_cluster_id" {
  description = "ID do cluster Kubernetes"
  value       = module.aks.cluster_id
}

output "kubernetes_cluster_name" {
  description = "Nome do cluster Kubernetes"
  value       = module.aks.cluster_name
}

output "kube_config" {
  description = "Configuração kubeconfig (para kubectl)"
  value       = module.aks.kube_config_raw
  sensitive   = true
}

output "kubernetes_cluster_host" {
  description = "Kubernetes API endpoint"
  value       = module.aks.host
  sensitive   = true
}

# ============ NETWORK ============

output "vnet_id" {
  description = "ID da Virtual Network"
  value       = module.vnet.vnet_id
}

output "aks_subnet_id" {
  description = "ID da subnet AKS"
  value       = module.vnet.aks_subnet_id
}

output "aks_subnet_cidr" {
  description = "CIDR da subnet AKS"
  value       = module.vnet.aks_subnet_cidr
}

# ============ STORAGE ============

output "storage_account_id" {
  description = "ID da Storage Account"
  value       = module.storage.storage_account_id
}

output "storage_account_name" {
  description = "Nome da Storage Account"
  value       = module.storage.storage_account_name
}

output "storage_primary_blob_endpoint" {
  description = "Endpoint primário de blobs"
  value       = module.storage.storage_primary_blob_endpoint
}

# ============ KEY VAULT ============

output "key_vault_id" {
  description = "ID do Key Vault"
  value       = module.storage.key_vault_id
}

output "key_vault_uri" {
  description = "URI do Key Vault"
  value       = module.storage.key_vault_uri
}

# ============ CONTAINER REGISTRY ============

output "container_registry_id" {
  description = "ID do Container Registry"
  value       = module.storage.container_registry_id
}

output "container_registry_login_server" {
  description = "URL de login do ACR"
  value       = module.storage.container_registry_login_server
}

# ============ MONITORING ============

output "log_analytics_workspace_id" {
  description = "ID do Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "application_insights_instrumentation_key" {
  description = "Chave de instrumentação do Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

# ============ RESOURCE GROUP ============

output "resource_group_name" {
  description = "Nome do Resource Group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID do Resource Group"
  value       = azurerm_resource_group.main.id
}

# ============ MANAGED IDENTITY ============

output "aks_identity_principal_id" {
  description = "Principal ID da identidade gerenciada do AKS"
  value       = azurerm_user_assigned_identity.aks.principal_id
}

output "aks_identity_client_id" {
  description = "Client ID da identidade gerenciada do AKS"
  value       = azurerm_user_assigned_identity.aks.client_id
}

# ============ ÚTIL PARA OPERAÇÕES ============

output "kubectl_config_command" {
  description = "Comando para configurar kubectl"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.cluster_name}"
}

output "acr_login_command" {
  description = "Comando para fazer login no ACR"
  value       = "az acr login --name ${module.storage.container_registry_name}"
}
