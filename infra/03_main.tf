# ============ GRUPO DE RECURSOS PRINCIPAL ============

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.azure_region

  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = var.project_name
  }
}

# ============ IDENTIDADE GERENCIADA PARA AKS ============

resource "azurerm_user_assigned_identity" "aks" {
  name                = "${var.cluster_name}-identity"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = {
    Environment = var.environment
  }
}

# ============ OBSERVABILIDADE ============

resource "azurerm_log_analytics_workspace" "main" {
  name                = "${var.cluster_name}-logs"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    Environment = var.environment
  }
}

resource "azurerm_application_insights" "main" {
  name                = "${var.cluster_name}-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.main.id

  tags = {
    Environment = var.environment
  }
}

# VNET

module "vnet" {
  source = "./module/vnet"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment

  vnet_name        = var.vnet_name
  vnet_cidr        = var.vnet_cidr
  aks_subnet_cidr  = var.aks_subnet_cidr
  apps_subnet_cidr = var.apps_subnet_cidr
  data_subnet_cidr = var.data_subnet_cidr

  common_tags = var.common_tags
}

# ============ MÓDULO: STORAGE / KEYVAULT / ACR ============

module "storage" {
  source = "./module/storage"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  storage_account_name    = var.storage_account_name
  storage_account_tier    = var.storage_account_tier
  storage_replication     = var.storage_replication
  keyvault_name           = var.keyvault_name
  enable_purge_protection = var.enable_purge_protection
  cluster_name            = var.cluster_name

  aks_subnet_id  = module.vnet.aks_subnet_id
  apps_subnet_id = module.vnet.apps_subnet_id
  data_subnet_id = module.vnet.data_subnet_id

  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  common_tags = var.common_tags

  depends_on = [module.vnet]
}

# ============ MÓDULO: AKS ============

module "aks" {
  source = "./module/aks"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  cluster_name       = var.cluster_name
  kubernetes_version = var.kubernetes_version

  identity_id           = azurerm_user_assigned_identity.aks.id
  identity_principal_id = azurerm_user_assigned_identity.aks.principal_id

  aks_subnet_id = module.vnet.aks_subnet_id

  node_count         = var.node_count
  node_vm_size       = var.node_vm_size
  enable_autoscaling = var.enable_autoscaling
  min_node_count     = var.min_node_count
  max_node_count     = var.max_node_count

  enable_network_policy = var.enable_network_policy
  network_policy_plugin = var.network_policy_plugin

  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  container_registry_id = module.storage.container_registry_id
  key_vault_id          = module.storage.key_vault_id
  storage_account_id    = module.storage.storage_account_id

  aks_nsg_association_id = module.vnet.aks_nsg_association_id

  common_tags = var.common_tags

  depends_on = [module.vnet, module.storage]
}
