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
    public_key = file(pathexpand(var.ssh_public_key_path))
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

cat > /var/www/html/index.html <<'HTML'
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Azure Custom DNS Store</title>

<style>
* {
    margin: 0;
    padding: 0;
    box-sizing: border-box;
    font-family: Arial, sans-serif;
}

body {
    background: #f1f5f9;
    color: #1e293b;
}

header {
    background: #0f172a;
    color: white;
    padding: 22px 8%;
    display: flex;
    justify-content: space-between;
    align-items: center;
}

.logo {
    color: #38bdf8;
    font-size: 26px;
    font-weight: bold;
}

nav a {
    color: white;
    text-decoration: none;
    margin-left: 20px;
}

.hero {
    padding: 90px 8%;
    color: white;
    background: linear-gradient(120deg,#0f172a,#2563eb);
}

.hero h1 {
    font-size: 46px;
    margin-bottom: 20px;
}

.hero p {
    font-size: 18px;
    margin-bottom: 25px;
}

.btn {
    background: #38bdf8;
    color: #0f172a;
    padding: 14px 25px;
    display: inline-block;
    border-radius: 7px;
    text-decoration: none;
    font-weight: bold;
}

.server {
    background: #dbeafe;
    color: #1e40af;
    padding: 15px;
    text-align: center;
    font-weight: bold;
}

.products {
    padding: 55px 8%;
}

.products h2 {
    text-align: center;
    font-size: 32px;
    margin-bottom: 35px;
}

.grid {
    display: grid;
    grid-template-columns: repeat(auto-fit,minmax(220px,1fr));
    gap: 25px;
}

.card {
    background: white;
    padding: 30px;
    text-align: center;
    border-radius: 12px;
    box-shadow: 0 5px 20px #00000012;
    transition: .3s;
}

.card:hover {
    transform: translateY(-7px);
}

.emoji {
    font-size: 65px;
    margin-bottom: 20px;
}

.price {
    color: #2563eb;
    font-size: 23px;
    font-weight: bold;
    margin: 15px;
}

button {
    background: #0f172a;
    color: white;
    border: none;
    padding: 12px 20px;
    border-radius: 6px;
    cursor: pointer;
}

.offer {
    margin: 20px 8% 50px;
    padding: 40px;
    text-align: center;
    background: linear-gradient(120deg,#0284c7,#2563eb);
    color: white;
    border-radius: 12px;
}

footer {
    background: #0f172a;
    color: white;
    padding: 30px;
    text-align: center;
    line-height: 2;
}

@media(max-width:600px) {
    header {
        flex-wrap: wrap;
        gap: 15px;
    }
    .hero h1 {
        font-size: 34px;
    }
}
</style>
</head>

<body>

<header>
    <div class="logo">AZURE STORE</div>
    <nav>
        <a href="#">Home</a>
        <a href="#products">Products</a>
        <a href="#offers">Offers</a>
    </nav>
</header>

<section class="hero">
    <h1>Upgrade Your Lifestyle</h1>
    <p>Discover premium products and exclusive shopping deals.</p>
    <a href="#products" class="btn">Shop Now →</a>
</section>

<div class="server">
    Hosted on Azure Linux VM | Server: SERVER_NAME
</div>

<section class="products" id="products">
    <h2>Featured Products</h2>

    <div class="grid">

        <div class="card">
            <div class="emoji">🎧</div>
            <h3>Premium Headphones</h3>
            <div class="price">₹2,499</div>
            <button onclick="alert('Headphones added to cart!')">
                Add to Cart
            </button>
        </div>

        <div class="card">
            <div class="emoji">⌚</div>
            <h3>Smart Watch</h3>
            <div class="price">₹3,999</div>
            <button onclick="alert('Watch added to cart!')">
                Add to Cart
            </button>
        </div>

        <div class="card">
            <div class="emoji">📱</div>
            <h3>Smart Phone</h3>
            <div class="price">₹14,999</div>
            <button onclick="alert('Phone added to cart!')">
                Add to Cart
            </button>
        </div>

        <div class="card">
            <div class="emoji">🎒</div>
            <h3>Travel Backpack</h3>
            <div class="price">₹1,299</div>
            <button onclick="alert('Backpack added to cart!')">
                Add to Cart
            </button>
        </div>

    </div>
</section>

<section class="offer" id="offers">
    <h2>Special Shopping Offer!</h2>
    <p>Get up to 40% OFF on selected products.</p>
</section>

<footer>
    <h3>AZURE STORE</h3>
    <p>Hosted on Microsoft Azure Virtual Machine</p>
    <p>Custom DNS Website Project</p>
    <p>© 2026 Azure Store</p>
</footer>

</body>
</html>
HTML

# Replace placeholder with actual Terraform VM name
sed -i 's/SERVER_NAME/${each.value.name}/g' /var/www/html/index.html

echo 'Healthy' > /var/www/html/health.html

chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html

systemctl restart apache2

SCRIPT
)


  depends_on = [
    azurerm_network_interface_security_group_association.nsg_assoc
  ]
}


