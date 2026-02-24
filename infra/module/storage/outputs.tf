output "storage_account_id" {
  description = "ID da Storage Account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Nome da Storage Account"
  value       = azurerm_storage_account.main.name
}

output "storage_primary_blob_endpoint" {
  description = "Endpoint primário de blobs"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "key_vault_id" {
  description = "ID do Key Vault"
  value       = azurerm_key_vault.main.id
}

output "key_vault_uri" {
  description = "URI do Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

output "container_registry_id" {
  description = "ID do Container Registry"
  value       = azurerm_container_registry.main.id
}

output "container_registry_name" {
  description = "Nome do Container Registry"
  value       = azurerm_container_registry.main.name
}

output "container_registry_login_server" {
  description = "URL de login do ACR"
  value       = azurerm_container_registry.main.login_server
}
