
resource "azurerm_traffic_manager_profile" "tm" {
  name                = "custom-dns-tm-profile"
  resource_group_name = azurerm_resource_group.rg.name

  # Change Performance to Weighted
  traffic_routing_method = "Weighted"

  profile_status      = "Enabled"
  traffic_view_enabled = true

  dns_config {
    relative_name = "custom-dns-web-project"
    ttl           = 30
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/health.html"
    interval_in_seconds          = 30
    timeout_in_seconds           = 9
    tolerated_number_of_failures = 3
  }
}

resource "azurerm_traffic_manager_azure_endpoint" "endpoints" {
  for_each = azurerm_public_ip.pip

  name       = "endpoint-${each.key}"
  profile_id = azurerm_traffic_manager_profile.tm.id

  target_resource_id = each.value.id

  # Equal weights
  weight = 1

  enabled = true
}
