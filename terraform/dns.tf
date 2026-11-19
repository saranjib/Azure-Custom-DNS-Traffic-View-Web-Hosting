resource "azurerm_dns_zone" "public_dns" {
  name                = var.domain_name
  resource_group_name = azurerm_resource_group.rg.name
}


resource "azurerm_dns_a_record" "vm_IP_record" {
  name                = "www"
  zone_name           = azurerm_dns_zone.public_dns.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300
  records = [azurerm_public_ip.pip["primary"].ip_address,]
}


