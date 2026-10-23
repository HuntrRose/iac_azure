terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=5.0.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "0c3eeefa-272e-4546-ab74-7180a0e3ee92"
}

resource "azurerm_resource_group" "rg-vm-test" {
  name     = "rg-vm-test"
  location = "Sweden Central"
}

resource "azurerm_virtual_network" "vnet-vm-test" {
  name                = "vnet-vm-test"
  location            = azurerm_resource_group.rg-vm-test.location
  resource_group_name = azurerm_resource_group.rg-vm-test.name
  address_space       = ["10.51.0.0/24"]
  dns_servers         = ["10.51.0.4"]
}

resource "azurerm_subnet" "snet-vm-test" {
  name                 = "snet-vm-test"
  resource_group_name  = azurerm_resource_group.rg-vm-test.name
  virtual_network_name = azurerm_virtual_network.vnet-vm-test.name
  address_prefixes     = ["10.51.0.128/25"]
}

resource "azurerm_public_ip" "pip-vm-test" {
  name                = "pip-vm-test"
  resource_group_name = azurerm_resource_group.rg-vm-test.name
  allocation_method   = "Static"
  location            = azurerm_resource_group.rg-vm-test.location
}

resource "azurerm_network_security_group" "nsg-vm-test" {
  name                = "nsg-vm-test"
  resource_group_name = azurerm_resource_group.rg-vm-test.name
  location            = azurerm_resource_group.rg-vm-test.location

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    source_address_prefix      = "*"
    destination_port_range     = "22"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "nic-vm-test" {
  name                = "nic-vm-test"
  resource_group_name = azurerm_resource_group.rg-vm-test.name
  location            = azurerm_resource_group.rg-vm-test.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet-vm-test.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip-vm-test.id
  }
}

resource "azurerm_network_interface_security_group_association" "int-nsg-assoc-vm-test" {
  network_interface_id      = azurerm_network_interface.nic-vm-test.id
  network_security_group_id = azurerm_network_security_group.nsg-vm-test.id
}

resource "azurerm_linux_virtual_machine" "vm-vm-test" {
  name                  = "vm-vm-test"
  resource_group_name   = azurerm_resource_group.rg-vm-test.name
  location              = azurerm_resource_group.rg-vm-test.location
  network_interface_ids = [azurerm_network_interface.nic-vm-test.id]
  size                  = "Standard_B2s"
  admin_username        = "simen"

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  admin_ssh_key {
    username   = "simen"
    public_key = file("~/.ssh/test.pub")
  }
}

output "public_ip" {
  value = azurerm_public_ip.pip-vm-test.ip_address
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/test simen@${azurerm_public_ip.pip-vm-test.ip_address}"
}
