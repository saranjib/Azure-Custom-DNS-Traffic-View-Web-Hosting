output "public_dns_nameservers" {
  value = azurerm_dns_zone.public_dns.name_servers
}

output "primary_vm_public_ip" {
  value = azurerm_public_ip.pip["primary"].ip_address
}

output "website_url" {
  value = "http://www.${var.domain_name}"
}

