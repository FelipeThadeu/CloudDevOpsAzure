# AKS

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = var.cluster_name
  kubernetes_version  = var.kubernetes_version

  # Identidade gerenciada para AKS
  identity {
    type         = "UserAssigned"
    identity_ids = [var.identity_id]
  }

  # Node Pool Padrão
  default_node_pool {
    name            = "system"
    node_count      = var.node_count
    vm_size         = var.node_vm_size
    os_disk_size_gb = 30
    type            = "VirtualMachineScaleSets"
    vnet_subnet_id  = var.aks_subnet_id

    # Zona de disponibilidade para HA
    zones = ["1", "2", "3"]

    # Autoscaling
    enable_auto_scaling = var.enable_autoscaling
    min_count            = var.enable_autoscaling ? var.min_node_count : null
    max_count            = var.enable_autoscaling ? var.max_node_count : null

    # Labels
    node_labels = {
      node_type = "system"
      workload  = "management"
    }

    tags = var.common_tags
  }

  # RBAC
  role_based_access_control_enabled = true

  # NETWORK PLUGIN 
  network_profile {
    network_plugin    = "azure"
    network_policy    = var.enable_network_policy ? var.network_policy_plugin : null
    load_balancer_sku = "standard"
    service_cidr      = "10.1.0.0/16"
    dns_service_ip    = "10.1.0.10"
  }

  # OBSERVABILITY
  microsoft_defender {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  oms_agent {
    log_analytics_workspace_id = var.log_analytics_workspace_id
  }

  # ADD-ONS
  http_application_routing_enabled = false

  # SECURITY 
  api_server_access_profile {
    authorized_ip_ranges = [] # Ajustar em produção
  }

  # Encryption at Rest via Key Vault
  key_vault_secrets_provider {
    secret_rotation_enabled  = true
    secret_rotation_interval = "2h"
  }

  auto_scaler_profile {
    balance_similar_node_groups      = true
    expander                         = "priority"
    max_graceful_termination_sec     = 600
    new_pod_scale_up_delay           = "10s"
    scale_down_delay_after_add       = "10m"
    scale_down_delay_after_failure   = "3m"
    scale_down_delay_after_delete    = "10s"
    scale_down_unneeded              = "10m"
    scale_down_unready               = "20m"
    scale_down_utilization_threshold = "0.5"
    skip_nodes_with_local_storage    = true
    skip_nodes_with_system_pods      = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = var.cluster_name
    }
  )

  lifecycle {
    ignore_changes = [
      # Evita re-create ao mudar node_count com autoscaling ativo
      default_node_pool[0].node_count
    ]
  }
}

# NODE POOL ADICIONAL

resource "azurerm_kubernetes_cluster_node_pool" "workload" {
  name                  = "workload"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  node_count            = 2
  vm_size               = var.node_vm_size
  os_type               = "Linux"
  os_disk_size_gb       = 30
  vnet_subnet_id        = var.aks_subnet_id

  zones = ["1", "2", "3"]

  enable_auto_scaling = var.enable_autoscaling
  min_count            = var.enable_autoscaling ? 2 : null
  max_count            = var.enable_autoscaling ? 8 : null

  node_labels = {
    node_type = "workload"
    workload  = "application"
  }

  # Taint para direcionar workloads específicas
  node_taints = ["workload=app:NoSchedule"]

  tags = var.common_tags
}

# ROLE ASSIGNMENTS

# Permitir que AKS pull de ACR
resource "azurerm_role_assignment" "aks_acr" {
  scope                = var.container_registry_id
  role_definition_name = "AcrPull"
  principal_id         = var.identity_principal_id
}

# Permitir que AKS acesse Key Vault
resource "azurerm_role_assignment" "aks_keyvault" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = var.identity_principal_id
}

# Permitir que AKS acesse Storage Account
resource "azurerm_role_assignment" "aks_storage" {
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.identity_principal_id
}

# KUBERNETES RBAC ROLES

# Namespace para aplicações
resource "kubernetes_namespace" "apps" {
  metadata {
    name = "production"
    labels = {
      name = "production"
    }
  }
}

# Service Account para aplicações
resource "kubernetes_service_account" "api" {
  metadata {
    name      = "api-sa"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }
}

resource "kubernetes_service_account" "worker" {
  metadata {
    name      = "worker-sa"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }
}

# Role para developers
resource "kubernetes_role" "developer" {
  metadata {
    name      = "developer"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/logs"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = ["apps"]
    resources  = ["deployments", "statefulsets"]
    verbs      = ["get", "list"]
  }
}

# RoleBinding para developers
resource "kubernetes_role_binding" "developer" {
  metadata {
    name      = "dev-rolebinding"
    namespace = kubernetes_namespace.apps.metadata[0].name
  }
  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.developer.metadata[0].name
  }
  subject {
    kind = "User"
    name = "developers@company.com"
  }
}
