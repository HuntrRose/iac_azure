terraform {
  required_version = ">=1.0"
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

module "tom" {
  source = "./modules/cust-infra"

  customer_name  = "tom"
  location       = "Sweden Central"
  vnet_cidr      = "10.1.0.0/16"
  admin_username = "tom"
  ssh_pub_key    = file("~/.ssh/test.pub")
  pg_adm_passwd  = "T0mP@55w0rd"
}

output "tom_vm_ip" {
  description = "Public ip for Toms VM"
  value       = module.tom.vm_public_ip
}

output "tom_pg_fqdn" {
  description = "Toms PG FQDN"
  value       = module.tom.postgres_fqdn
}

output "tom_ssh_string" {
  description = "SSH command string for Tom"
  value       = module.tom.ssh_connection
}

module "dick" {
  source = "./modules/cust-infra"

  customer_name  = "dick"
  location       = "northeurope"
  vnet_cidr      = "10.2.0.0/16"
  admin_username = "dick"
  ssh_pub_key    = file("~/.ssh/test.pub")
  pg_adm_passwd  = "DickP@55w0rd"
}

output "dick_vm_ip" {
  description = "Public ip for Dicks VM"
  value       = module.dick.vm_public_ip
}

output "dick_pg_fqdn" {
  description = "Dicks PG FQDN"
  value       = module.dick.postgres_fqdn
}

output "dick_ssh_string" {
  description = "SSH command string for Dick"
  value       = module.dick.ssh_connection
}

module "harry" {
  source = "./modules/cust-infra"

  customer_name  = "harry"
  location       = "westeurope"
  vnet_cidr      = "10.2.0.0/16"
  admin_username = "harry"
  ssh_pub_key    = file("~/.ssh/test.pub")
  pg_adm_passwd  = "HarryP@55w0rd"
}

output "harry_vm_ip" {
  description = "Public ip for Harrys VM"
  value       = module.harry.vm_public_ip
}

output "harry_pg_fqdn" {
  description = "Harrys PG FQDN"
  value       = module.harry.postgres_fqdn
}

output "harry_ssh_string" {
  description = "SSH command string for Harry"
  value       = module.harry.ssh_connection
}

