
resource "azurerm_dns_zone" "public_dns" {
  name                = var.domain_name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_dns_cname_record" "www" {
  name                = "www"
  zone_name           = azurerm_dns_zone.public_dns.name
  resource_group_name = azurerm_resource_group.rg.name
  ttl                 = 300

  record = azurerm_traffic_manager_profile.tm.fqdn
}
