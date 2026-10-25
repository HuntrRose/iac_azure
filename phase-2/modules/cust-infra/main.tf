resource "azurerm_resource_group" "customer" {
  name     = "rg-${var.customer_name}"
  location = var.location
}

resource "azurerm_virtual_network" "customer" {
  name                = "vnet-${var.customer_name}"
  address_space       = [var.vnet_cidr]
  location            = azurerm_resource_group.customer.location
  resource_group_name = azurerm_resource_group.customer.name
}

resource "azurerm_subnet" "customer" {
  name                 = "subnet-${var.customer_name}"
  resource_group_name  = azurerm_resource_group.customer.name
  virtual_network_name = azurerm_virtual_network.customer.name
  address_prefixes     = [var.vnet_cidr]
}

resource "azurerm_public_ip" "customer" {
  name                = "pip-${var.customer_name}"
  resource_group_name = azurerm_resource_group.customer.name
  allocation_method   = "Static"
  location            = azurerm_resource_group.customer.location
}

resource "azurerm_network_interface" "customer" {
  name                = "nic-${var.customer_name}"
  resource_group_name = azurerm_resource_group.customer.name
  location            = azurerm_resource_group.customer.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.customer.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.customer.id
  }
}

resource "azurerm_linux_virtual_machine" "customer" {
  name                = "vm-${var.customer_name}"
  location            = azurerm_resource_group.customer.location
  resource_group_name = azurerm_resource_group.customer.name
  size                = "Standard_B2s"
  admin_username      = var.admin_username

  network_interface_ids = [
    azurerm_network_interface.customer.id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_pub_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
  disable_password_authentication = true
}

data "azurerm_client_config" "current" {}

resource "azurerm_postgresql_flexible_server" "customer" {
  name                = "psql-${var.customer_name}"
  location            = azurerm_resource_group.customer.location
  resource_group_name = azurerm_resource_group.customer.name

  administrator_login    = "psqladmin"
  administrator_password = var.pg_adm_passwd

  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768
  version    = "16"
  zone       = "2"

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  public_network_access_enabled = true
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "customer" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.customer.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
