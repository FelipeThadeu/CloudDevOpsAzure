variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Região Azure"
  type        = string
}

variable "cluster_name" {
  description = "Nome do cluster AKS"
  type        = string
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes"
  type        = string
  default     = "1.28.3"
}

variable "identity_id" {
  description = "ID da User Assigned Identity para o AKS"
  type        = string
}

variable "identity_principal_id" {
  description = "Principal ID da User Assigned Identity"
  type        = string
}

variable "aks_subnet_id" {
  description = "ID da subnet AKS"
  type        = string
}

variable "node_count" {
  description = "Número inicial de nós"
  type        = number
  default     = 3

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 100
    error_message = "node_count deve estar entre 1 e 100"
  }
}

variable "node_vm_size" {
  description = "Tamanho da VM dos nós (ex: Standard_D4s_v3)"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "enable_autoscaling" {
  description = "Habilitar autoscaling de nós"
  type        = bool
  default     = true
}

variable "min_node_count" {
  description = "Mínimo de nós para autoscaling"
  type        = number
  default     = 3
}

variable "max_node_count" {
  description = "Máximo de nós para autoscaling"
  type        = number
  default     = 10
}

variable "enable_network_policy" {
  description = "Habilitar Network Policies"
  type        = bool
  default     = true
}

variable "network_policy_plugin" {
  description = "Plugin de network policy (azure ou calico)"
  type        = string
  default     = "azure"
}

variable "log_analytics_workspace_id" {
  description = "ID do Log Analytics Workspace para OMS Agent"
  type        = string
}

variable "container_registry_id" {
  description = "ID do Container Registry para AcrPull"
  type        = string
}

variable "key_vault_id" {
  description = "ID do Key Vault para acesso de secrets"
  type        = string
}

variable "storage_account_id" {
  description = "ID da Storage Account para acesso de blobs"
  type        = string
}

variable "aks_nsg_association_id" {
  description = "ID da associação NSG-Subnet AKS (depends_on)"
  type        = string
}

variable "common_tags" {
  description = "Tags aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}
