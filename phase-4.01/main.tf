terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  subscription_id = "0c3eeefa-272e-4546-ab74-7180a0e3ee92"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-aks-n8n"
  location = "northeurope"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "n8n-cluster"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "n8n"
  kubernetes_version  = "1.36.0"

  node_provisioning_profile {
    default_node_pools = "Auto"
  }

  default_node_pool {
    auto_scaling_enabled = true
    name                 = "default"
    min_count            = 1
    max_count            = 5
    vm_size              = "Standard_D2s_v3"
  }

  identity {
    type = "SystemAssigned"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "cilium"
    network_data_plane  = "cilium"
  }
}


resource "azurerm_postgresql_flexible_server" "n8n" {
  name                = "psql-n8n-easfgasasg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  administrator_login    = "psqladmin"
  administrator_password = "n8n_passwd"

  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768
  version    = "16"
  zone       = "2"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  public_network_access_enabled = true
}

resource "azurerm_postgresql_flexible_server_configuration" "disable_ssl" {
  name = "require_secure_transport"
  server_id = azurerm_postgresql_flexible_server.n8n.id
  value = "OFF"
}

resource "azurerm_postgresql_flexible_server_database" "n8n" {
  name = "n8n"
  server_id = azurerm_postgresql_flexible_server.n8n.id
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "n8n" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.n8n.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

data "azurerm_client_config" "current" {
}

resource "azurerm_key_vault" "n8n_vault" {
  name = "kv-n8n-asrghhasdf"
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id = data.azurerm_client_config.current.tenant_id
  sku_name = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled = false

  rbac_authorization_enabled = true
  depends_on = [azurerm_kubernetes_cluster.main]
}

resource "azurerm_role_assignment" "kv_admin" {
  scope = azurerm_key_vault.n8n_vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "aks_keyvault_secrets_provider" {
  scope = azurerm_key_vault.n8n_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
}

resource "azurerm_key_vault_secret" "db_host" {
  name = "db-host"
  value = azurerm_postgresql_flexible_server.n8n.fqdn
  key_vault_id = azurerm_key_vault.n8n_vault.id
  
  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "db_name" {
  name = "db-name"
  value = azurerm_postgresql_flexible_server_database.n8n.name
  key_vault_id = azurerm_key_vault.n8n_vault.id
  
  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "db_user" {
  name = "db-user"
  value = azurerm_postgresql_flexible_server.n8n.administrator_login
  key_vault_id = azurerm_key_vault.n8n_vault.id
  
  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "db_pass" {
  name = "db-pass"
  value = azurerm_postgresql_flexible_server.n8n.administrator_password
  key_vault_id = azurerm_key_vault.n8n_vault.id
  
  depends_on = [azurerm_role_assignment.kv_admin]
}

