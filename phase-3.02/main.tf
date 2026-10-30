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

output "pg_addr" {
   value = azurerm_postgresql_flexible_server.n8n.fqdn
   description = "DB FQDN"
}

output "pg_db" {
   value = azurerm_postgresql_flexible_server_database.n8n.name
   description = "DB_name"
}

output "db_user" {
   value = azurerm_postgresql_flexible_server.n8n.administrator_login
   description = "Admin user"
}

output "db_pass" {
   value = azurerm_postgresql_flexible_server.n8n.administrator_password
   description = "Admin Passwd"
   sensitive = true
}
