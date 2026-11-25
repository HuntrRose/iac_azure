terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    local = {
      source = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "0c3eeefa-272e-4546-ab74-7180a0e3ee92"
}

resource "azurerm_resource_group" "aks" {
  name     = "rg-aks-n8n"
  location = "North Europe"
}

## AKS Cluster with Best Practices
# Reference: https://learn.microsoft.com/en-us/azure/aks/best-practices

resource "azurerm_kubernetes_cluster" "main" {
  name                = "n8n-staging"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = "staging"
  kubernetes_version  = "1.36.0"

  azure_active_directory_role_based_access_control {
    admin_group_object_ids = ["d8d3103e-f192-485a-83ee-1d3540e6edd8"]
  }


  # Automatic upgrades,  patch level only for stability
  automatic_upgrade_channel = "patch"

  # Node OS auto-upgrade for security patches
  node_os_upgrade_channel = "NodeImage"

  node_provisioning_profile {
    default_node_pools = "Auto"
  }
  # System node pool for critical Kubernetes components
  # Tainted with CriticalAddonsOnly so user workloads don't schedule here
  default_node_pool {
    name                         = "agentpool"
    auto_scaling_enabled = true
    min_count = 1
    max_count = 3

    #node_count                   = 2
    vm_size                      = "Standard_D2s_v3"
    only_critical_addons_enabled = true # Adds CriticalAddonsOnly taint

    upgrade_settings {
      max_surge = "33%" # Microsoft recommended for production
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "cilium"
    network_data_plane = "cilium"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = false
  }

  # Maintenance windows - schedule upgrades during low-traffic periods
  # Microsoft recommends at least 4 hours duration
  maintenance_window_auto_upgrade {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "+00:00"
  }

  maintenance_window_node_os {
    frequency   = "Weekly"
    interval    = 1
    duration    = 4
    day_of_week = "Sunday"
    start_time  = "02:00"
    utc_offset  = "+00:00"
  }
}

# User node pool - for application workloads
# No taint, so pods schedule here by default
resource "azurerm_kubernetes_cluster_node_pool" "user" {
  name                  = "userpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D2s_v3"
  auto_scaling_enabled = true
  min_count = 1
  #max_surge = 1
  max_count = 5
  #node_count            = 2

  upgrade_settings {
    max_surge = "33%"
  }
}

## GitOps with Flux
# IMPORTANT: Register provider first: az provider register --namespace Microsoft.KubernetesConfiguration

resource "azurerm_kubernetes_cluster_extension" "flux" {
  name           = "n8n-flux"
  cluster_id     = azurerm_kubernetes_cluster.main.id
  extension_type = "microsoft.flux"

  # Wait for user node pool to be ready before installing extensions
  # The system pool has CriticalAddonsOnly taint, so Flux needs user nodes
  depends_on = [azurerm_kubernetes_cluster_node_pool.user]
}

resource "azurerm_kubernetes_flux_configuration" "main" {
  name       = "n8n-staging"
  cluster_id = azurerm_kubernetes_cluster.main.id
  namespace  = "flux-system"

  git_repository {
    url             = "ssh://git@github.com/HuntrRose/n8n"
    reference_type  = "branch"
    reference_value = "main"

    ssh_private_key_base64 = base64encode(file("~/.ssh/n8n-ssl"))
  }

  kustomizations {
    name                       = "infra-controllers"
    path                       = "./infrastructure/controllers/staging"
    sync_interval_in_seconds   = 300
    garbage_collection_enabled = true
  }

  kustomizations {
    name                       = "infra-operators"
    path                       = "./infrastructure/operators/staging"
    sync_interval_in_seconds   = 300
    garbage_collection_enabled = true
    depends_on                 = ["infra-controllers"]
  }

  kustomizations {
    name                       = "infra-configs"
    path                       = "./infrastructure/configs/staging"
    sync_interval_in_seconds   = 300
    depends_on                 = ["infra-controllers"]
    garbage_collection_enabled = true
  }
  
  kustomizations {
    name                       = "monitoring-controllers"
    path                       = "./monitoring/controllers/staging"
    sync_interval_in_seconds   = 300
    depends_on                 = ["infra-controllers"]
    garbage_collection_enabled = true
  }

  kustomizations {
    name                       = "monitoring-configs"
    path                       = "./monitoring/configs/staging"
    sync_interval_in_seconds   = 300
    depends_on                 = ["monitoring-controllers"]
    garbage_collection_enabled = true
  }

  kustomizations {
    name                       = "apps"
    path                       = "./apps/staging"
    sync_interval_in_seconds   = 300
    depends_on                 = ["infra-configs", "infra-operators"]
    garbage_collection_enabled = true
  }

  scope = "cluster"

  depends_on = [azurerm_kubernetes_cluster_extension.flux]
}

## Key Vault

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "n8n_vault" {
  name                = "kv-n8n-staging-asrgh"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  soft_delete_retention_days = 7
  purge_protection_enabled   = false

  rbac_authorization_enabled = true
  depends_on                 = [azurerm_kubernetes_cluster.main]
}

resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.n8n_vault.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "aks_keyvault_secrets_provider" {
  scope                = azurerm_key_vault.n8n_vault.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_kubernetes_cluster.main.key_vault_secrets_provider[0].secret_identity[0].object_id
}

resource "random_password" "grafana_admin" {
  length  = 24
  special = false

  lifecycle {
    ignore_changes = all
  }
}

resource "azurerm_key_vault_secret" "grafana_admin_password" {
  name         = "grafana-admin-password"
  value        = random_password.grafana_admin.result
  key_vault_id = azurerm_key_vault.n8n_vault.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

resource "azurerm_key_vault_secret" "grafana_admin_user" {
  name         = "grafana-admin-user"
  value        = "admin"
  key_vault_id = azurerm_key_vault.n8n_vault.id

  depends_on = [azurerm_role_assignment.kv_admin]
}

