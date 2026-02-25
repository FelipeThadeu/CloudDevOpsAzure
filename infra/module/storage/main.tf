# STORAGE ACCOUNT

resource "azurerm_storage_account" "main" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = var.storage_account_tier
  account_replication_type = var.storage_replication

  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"

  # Encriptação em repouso
  infrastructure_encryption_enabled = true

  # Habilitar soft delete
  blob_properties {
    delete_retention_policy {
      days = 7
    }
    container_delete_retention_policy {
      days = 7
    }
  }

  # Acesso temporário habilitado para permitir a criação dos blobs/logs via Terraform
  network_rules {
    default_action             = "Allow"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = [
      var.aks_subnet_id,
      var.apps_subnet_id,
      var.data_subnet_id
    ]
  }

  tags = var.common_tags
}

# Blob Container para logs
resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Blob Container para backups
resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# AZURE KEY VAULT

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = var.keyvault_name
  location            = var.location
  resource_group_name = var.resource_group_name

  sku_name                        = "standard"
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  enable_rbac_authorization       = true
  purge_protection_enabled        = var.enable_purge_protection

  # Acesso temporário habilitado
  network_acls {
    default_action             = "Allow"
    bypass                     = "AzureServices"
    virtual_network_subnet_ids = [
      var.aks_subnet_id,
      var.apps_subnet_id,
      var.data_subnet_id
    ]
  }

  tags = var.common_tags
}

# Role Assignment: Current user pode gerenciar KV
resource "azurerm_role_assignment" "keyvault_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# AZURE CONTAINER REGISTRY

resource "azurerm_container_registry" "main" {
  name                = replace(var.cluster_name, "-", "") # ACR não permite hífens
  resource_group_name = var.resource_group_name
  location            = var.location

  sku           = "Premium"
  admin_enabled = false # Use identidades gerenciadas

  # Replicação geográfica
  georeplications {
    location                  = "eastus"
    regional_endpoint_enabled = true
  }

  network_rule_bypass_option    = "AzureServices"
  public_network_access_enabled = true

  # Trust policy
  trust_policy {
    enabled = true
  }

  # Retention policy para limpeza automática
  retention_policy {
    days    = 30
    enabled = true
  }

  # Quarantine policy para imagens
  quarantine_policy_enabled = true

  tags = var.common_tags
}

# MONITORING E DIAGNOSTICS

# Diagnostics para Storage Account (Blob Services)
resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "storage-diagnostics"
  target_resource_id         = "${azurerm_storage_account.main.id}/blobServices/default"
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  metric {
    category = "Transaction"
  }
}

# Diagnostics para Key Vault
resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "keyvault-diagnostics"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
  }
}

# ALERTAS

# Alert: Storage Account alta latência
resource "azurerm_monitor_metric_alert" "storage_latency" {
  name                = "storage-high-latency"
  resource_group_name = var.resource_group_name
  scopes              = [azurerm_storage_account.main.id]
  description         = "Alerta quando latência de storage exceder 1000ms"

  criteria {
    metric_name      = "SuccessServerLatency"
    metric_namespace = "Microsoft.Storage/storageAccounts"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 1000
  }

  window_size = "PT5M"
  frequency   = "PT1M"
  enabled     = true
}
