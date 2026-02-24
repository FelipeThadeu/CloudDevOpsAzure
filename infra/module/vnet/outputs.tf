output "vnet_id" {
  description = "ID da Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Nome da Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "aks_subnet_id" {
  description = "ID da subnet AKS"
  value       = azurerm_subnet.aks.id
}

output "apps_subnet_id" {
  description = "ID da subnet de aplicações"
  value       = azurerm_subnet.apps.id
}

output "data_subnet_id" {
  description = "ID da subnet de dados"
  value       = azurerm_subnet.data.id
}

output "aks_subnet_cidr" {
  description = "CIDR da subnet AKS"
  value       = azurerm_subnet.aks.address_prefixes[0]
}

output "aks_nsg_association_id" {
  description = "ID da associação NSG-Subnet AKS (para depends_on externos)"
  value       = azurerm_subnet_network_security_group_association.aks.id
}
