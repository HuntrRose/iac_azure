variable "customer_name" {
  description = "Name of customer"
  type        = string
}

variable "location" {
  description = "Customer location for resources"
  type        = string
  default     = "Sweden Central"
}

variable "vnet_cidr" {
  description = "CIDR block for cust vnet"
  type        = string
}

variable "admin_username" {
  description = "Admin user for vm"
  type        = string
}

variable "ssh_pub_key" {
  description = "Public key for vm login"
  type        = string
}

variable "pg_adm_passwd" {
  description = "Admin password for PG database"
  type        = string
  sensitive   = true
}
