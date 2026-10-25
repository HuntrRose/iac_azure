output "resource_group_name" {
  description = "Name of resource group"
  value       = azurerm_resource_group.customer.name
}

output "vm_public_ip" {
  description = "Public IP for VM"
  value       = azurerm_public_ip.customer.ip_address
}

output "postgres_fqdn" {
  description = "FQDN for Postgres DB"
  value       = azurerm_postgresql_flexible_server.customer.fqdn
}

output "ssh_connection" {
  description = "SSH Connection command"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.customer.ip_address}"
}
