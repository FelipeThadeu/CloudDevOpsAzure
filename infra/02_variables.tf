variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
  default     = "rg-prod-app"
}

variable "azure_region" {
  description = "Região Azure"
  type        = string
  default     = "westeurope"
}

variable "environment" {
  description = "Ambiente (production, staging, development)"
  type        = string
  default     = "production"
  
  validation {
    condition     = contains(["production", "staging", "development"], var.environment)
    error_message = "Ambiente deve ser: production, staging ou development"
  }
}

variable "project_name" {
  description = "Nome do projeto"
  type        = string
  default     = "cloud-app"
}

# ============ NETWORK ============

variable "vnet_name" {
  description = "Nome da Virtual Network"
  type        = string
  default     = "vnet-prod"
}

variable "vnet_cidr" {
  description = "CIDR da VNet (ex: 10.0.0.0/16)"
  type        = string
  default     = "10.0.0.0/16"
  
  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "Deve ser um CIDR válido"
  }
}

variable "aks_subnet_cidr" {
  description = "CIDR da subnet AKS"
  type        = string
  default     = "10.0.1.0/24"
}

variable "apps_subnet_cidr" {
  description = "CIDR da subnet de aplicações"
  type        = string
  default     = "10.0.2.0/24"
}

variable "data_subnet_cidr" {
  description = "CIDR da subnet de dados"
  type        = string
  default     = "10.0.3.0/24"
}

# ============ KUBERNETES ============

variable "cluster_name" {
  description = "Nome do cluster AKS"
  type        = string
  default     = "aks-prod"
}

variable "kubernetes_version" {
  description = "Versão do Kubernetes"
  type        = string
  default     = "1.28.3"
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

# ============ STORAGE ============

variable "storage_account_name" {
  description = "Nome da Storage Account (deve ser único globalmente)"
  type        = string
  default     = "stgprodapp"
  
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

# ============ KEYVAULT ============

variable "keyvault_name" {
  description = "Nome do Key Vault (deve ser único globalmente)"
  type        = string
  default     = "kv-prod-app"
}

variable "enable_purge_protection" {
  description = "Habilitar purge protection no Key Vault"
  type        = bool
  default     = true
}

# ============ TAGS ============

variable "common_tags" {
  description = "Tags aplicadas a todos os recursos"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    CostCenter = "Engineering"
  }
}
