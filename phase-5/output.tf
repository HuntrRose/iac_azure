output "aks_keyvault_secrets_provider_client_id" {
  description = "Client ID"
  value = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].client_id
}

output "tenant_id" {
  value = data.azurerm_client_config.current.tenant_id
}

#output "pg_addr" {
#   value = azurerm_postgresql_flexible_server.n8n.fqdn
#   description = "DB FQDN"
#}
#
#output "pg_db" {
#   value = azurerm_postgresql_flexible_server_database.n8n.name
#   description = "DB_name"
#}
#
#output "db_user" {
#   value = azurerm_postgresql_flexible_server.n8n.administrator_login
#   description = "Admin user"
#}
#
#output "db_pass" {
#   value = azurerm_postgresql_flexible_server.n8n.administrator_password
#   description = "Admin Passwd"
#   sensitive = true
#}
#

