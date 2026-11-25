## Required variables
#

variable "customer_name" {
  type = string
  description = "Customer identifier (lowercase, alphanumeric, hyphens allowed)"

  validation {
    condition = can(regex("^[a-z][a-z0-9-]{1,20}$", var.customer_name))
    error_message = "Customer name must be lowercase, start with letter, 2-21 chars, alphanumeric with hyphens"
  }
}

variable "environment" {
  type = string
  description = "Target environment (staging, production)"

  validation {
    condition = contains(["staging", "production", "n8n"], var.environment)
    error_message = "Environment must be staging, production or n8n"
  }
}

variable "keyvault_id" {
  type = string
  description = "Azure Key Vault resource ID for secret managment"
}

variable "storage_account_id" { 
  type = string
  description = "Storage account resource ID"
}

variable "storage_account_name" {
  type = string
  description = "Storage account name for DB backups"
}

variable "storage_account_primary_connection_string" {
  type = string
  sensitive = true
  description = "Storage account connectionstring for SAS generation"
}

variable "gitops_repo_path" {
  type = string
  description = "Local path for gitops repo"
  default = "/workspaces/iacazure/phase-10/n8n"
}

variable "domain" {
  type = string
  description = "Base domain for ingress"
}

# Sizing vars

variable "db_instances" {
  type = number
  description = "Number of PG instances. (1 for dev, 3 gor HA)"
  default = 3
}

variable "db_storage_size" {
  type = string
  description = "PostgreSQL storage size"
  default = "1Gi"
}

variable "n8n_storage_size" {
  type = string
  description = "N8n PVc storage size"
  default = "1Gi"
}

variable "n8n_version" {
  type        = string
  description = "n8n container image version"
  default     = "2.45.6"
}

## Resource limits

variable "n8n_memory_request" {
  type = string
  description = "n8n memory request"
  default = "256Mi"
}

variable "n8n_memory_limit" {
  type = string
  description = "n8n memory limit"
  default = "1Gi"
}

variable "n8n_cpu_request" {
  type = string
  description = "n8n CPU limit"
  default = "100m"
}

variable "n8n_cpu_limit" {
  type = string
  description = "n8n CPU request"
  default = "1000m"
}

## Key Vault CSI Configuration

variable "keyvault_name" {
  type        = string
  description = "Key Vault name for SecretProviderClass"
}

variable "keyvault_tenant_id" {
  type        = string
  description = "Azure tenant ID for SecretProviderClass"
}

variable "aks_keyvault_identity_client_id" {
  type        = string
  description = "AKS Key Vault Secrets Provider managed identity client ID"
}
