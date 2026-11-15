
output "public_dns_nameservers" {
  value = azurerm_dns_zone.public_dns.name_servers
}

output "primary_vm_public_ip" {
  value = azurerm_public_ip.pip["primary"].ip_address
}

output "secondary_vm_public_ip" {
  value = azurerm_public_ip.pip["secondary"].ip_address
}

output "traffic_manager_url" {
  value = azurerm_traffic_manager_profile.tm.fqdn
}

output "website_url" {
  value = "http://www.${var.domain_name}"
}

