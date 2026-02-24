variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Região Azure"
  type        = string
}

variable "storage_account_name" {
  description = "Nome da Storage Account (deve ser único globalmente)"
  type        = string

  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24
    error_message = "Nome da Storage Account deve ter entre 3 e 24 caracteres"
  }
}

variable "storage_account_tier" {
  description = "Tier da Storage Account (Standard ou Premium)"
  type        = string
  default     = "Standard"
}

variable "storage_replication" {
  description = "Tipo de replicação (LRS, GRS, RAGRS)"
  type        = string
  default     = "GRS"
}

variable "keyvault_name" {
  description = "Nome do Key Vault (deve ser único globalmente)"
  type        = string
}

variable "enable_purge_protection" {
  description = "Habilitar purge protection no Key Vault"
  type        = bool
  default     = true
}

variable "cluster_name" {
  description = "Nome do cluster AKS (usado para nomear o ACR)"
  type        = string
}

variable "aks_subnet_id" {
  description = "ID da subnet AKS (para network rules)"
  type        = string
}

variable "apps_subnet_id" {
  description = "ID da subnet de aplicações (para network rules)"
  type        = string
}

variable "data_subnet_id" {
  description = "ID da subnet de dados (para network rules)"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "ID do Log Analytics Workspace para diagnósticos"
  type        = string
}

variable "common_tags" {
  description = "Tags aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}
