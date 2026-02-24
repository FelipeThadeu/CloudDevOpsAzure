variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "location" {
  description = "Região Azure"
  type        = string
}

variable "environment" {
  description = "Ambiente (production, staging, development)"
  type        = string
}

variable "vnet_name" {
  description = "Nome da Virtual Network"
  type        = string
}

variable "vnet_cidr" {
  description = "CIDR da VNet (ex: 10.0.0.0/16)"
  type        = string

  validation {
    condition     = can(cidrhost(var.vnet_cidr, 0))
    error_message = "Deve ser um CIDR válido"
  }
}

variable "aks_subnet_cidr" {
  description = "CIDR da subnet AKS"
  type        = string
}

variable "apps_subnet_cidr" {
  description = "CIDR da subnet de aplicações"
  type        = string
}

variable "data_subnet_cidr" {
  description = "CIDR da subnet de dados"
  type        = string
}

variable "common_tags" {
  description = "Tags aplicadas a todos os recursos"
  type        = map(string)
  default     = {}
}
