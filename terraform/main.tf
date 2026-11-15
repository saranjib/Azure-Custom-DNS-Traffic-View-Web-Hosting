resource "azurerm_resource_group" "rg" {
  name     = "rg-custom-dns-project"
  location = "Central India"
}

locals {
  sites = {
    primary = {
      location = "Central India"
      address  = "10.1.0.0/16"
      subnet   = "10.1.1.0/24"
      name     = "web-vm-01"
    }

    secondary = {
      location = "Southeast Asia"
      address  = "10.2.0.0/16"
      subnet   = "10.2.1.0/24"
      name     = "web-vm-02"
    }
  }
}

resource "azurerm_virtual_network" "vnet" {
  for_each = local.sites

  name                = "vnet-${each.key}"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = [each.value.address]
}

resource "azurerm_subnet" "subnet" {
  for_each = local.sites

  name                 = "subnet-web-${each.key}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet[each.key].name
  address_prefixes     = [each.value.subnet]
}

resource "azurerm_network_security_group" "nsg" {
  for_each = local.sites

  name                = "nsg-${each.key}"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "Allow-HTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-SSH"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.admin_source_cidr
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "pip" {
  for_each = local.sites

  name                = "pip-${each.key}"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  for_each = local.sites

  name                = "nic-${each.key}"
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet[each.key].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip[each.key].id
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  for_each = local.sites

  network_interface_id      = azurerm_network_interface.nic[each.key].id
  network_security_group_id = azurerm_network_security_group.nsg[each.key].id
}

resource "azurerm_linux_virtual_machine" "vm" {
  for_each = local.sites

  name                = each.value.name
  computer_name       = each.value.name
  location            = each.value.location
  resource_group_name = azurerm_resource_group.rg.name
  size                = "Standard_B1s"

  admin_username                  = var.admin_username
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.nic[each.key].id
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  custom_data = base64encode(<<-SCRIPT
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2

    systemctl enable apache2
    systemctl start apache2

    echo '<h1>Azure Custom DNS Website</h1>
    <h2>Server: ${each.value.name}</h2>
    <p>Hosted on Azure Linux VM</p>' > /var/www/html/index.html

    echo 'Healthy' > /var/www/html/health.html
  SCRIPT
  )

  depends_on = [
    azurerm_network_interface_security_group_association.nsg_assoc
  ]
}


