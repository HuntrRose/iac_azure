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
  name     = "rg-aks-test"
  location = "northeurope"
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = "test-cluster"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  dns_prefix          = "test"
  kubernetes_version  = "1.36.0"

  node_provisioning_profile {
    default_node_pools = "Auto"
  }

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2s_v3"
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

