resource "azurerm_subnet" "subnet" {
  address_prefixes     = ["10.0.0.0/24"]
  name                 = "AppGatewaySubnet"
  resource_group_name  = "app-gateway"
  virtual_network_name = "prd-vnet-001"
  depends_on = [
    azurerm_virtual_network.vnet,
  ]
}
resource "azurerm_application_gateway" "app-gateway" {
  enable_http2        = true
  firewall_policy_id  = "/subscriptions/2cfb85f8-b2ba-49fb-a9b5-47c7ad185245/resourceGroups/app-gateway/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/app-gateway-waf-pol-001"
  location            = "uksouth"
  name                = "prd-appgw-001"
  resource_group_name = "app-gateway"
  tags = {
    Environment = "Test"
    Solution    = "Application Gateway"
  }
  autoscale_configuration {
    max_capacity = 3
    min_capacity = 1
  }
  backend_address_pool {
    ip_addresses = ["192.168.23.23"]
    name         = "backendpool"
  }
  backend_http_settings {
    cookie_based_affinity = "Disabled"
    name                  = "default-backend-settings"
    port                  = 80
    probe_name            = "default-probe"
    protocol              = "Http"
    request_timeout       = 20
  }
  frontend_ip_configuration {
    name                 = "appGwPublicFrontendIpIPv4"
    public_ip_address_id = "/subscriptions/2cfb85f8-b2ba-49fb-a9b5-47c7ad185245/resourceGroups/app-gateway/providers/Microsoft.Network/publicIPAddresses/app-gw-pip"
  }
  frontend_ip_configuration {
    name                          = "appGwPrivateFrontendIpIPv4"
    private_ip_address_allocation = "Static"
    subnet_id                     = "/subscriptions/2cfb85f8-b2ba-49fb-a9b5-47c7ad185245/resourceGroups/app-gateway/providers/Microsoft.Network/virtualNetworks/prd-vnet-001/subnets/AppGatewaySubnet"
  }
  frontend_port {
    name = "port_80"
    port = 80
  }
  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = "/subscriptions/2cfb85f8-b2ba-49fb-a9b5-47c7ad185245/resourceGroups/app-gateway/providers/Microsoft.Network/virtualNetworks/prd-vnet-001/subnets/AppGatewaySubnet"
  }
  http_listener {
    frontend_ip_configuration_name = "appGwPublicFrontendIpIPv4"
    frontend_port_name             = "port_80"
    host_names                     = ["nowcloud.co.uk"]
    name                           = "default-listener"
    protocol                       = "Http"
  }
  probe {
    host                = "10.20.3.4"
    interval            = 30
    name                = "default-probe"
    path                = "/"
    protocol            = "Http"
    timeout             = 30
    unhealthy_threshold = 3
    match {
      status_code = []
    }
  }
  request_routing_rule {
    backend_address_pool_name  = "backendpool"
    backend_http_settings_name = "default-backend-settings"
    http_listener_name         = "default-listener"
    name                       = "default-rule"
    priority                   = 100
    rule_type                  = "Basic"
  }
  sku {
    name = "WAF_v2"
    tier = "WAF_v2"
  }
  depends_on = [
    azurerm_web_application_firewall_policy.firewall_policy,
    azurerm_public_ip.apgw-pip,
    azurerm_subnet.subnet,
  ]
}
resource "azurerm_web_application_firewall_policy" "firewall_policy" {
  location            = "uksouth"
  name                = "app-gateway-waf-pol-001"
  resource_group_name = "app-gateway"
  managed_rules {
    managed_rule_set {
      version = "3.2"
    }
    managed_rule_set {
      type    = "Microsoft_BotManagerRuleSet"
      version = "0.1"
    }
  }
  policy_settings {
    mode = "Detection"
  }
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_resource_group" "rg" {
  location = "uksouth"
  name     = "app-gateway"
}
resource "azurerm_public_ip" "apgw-pip" {
  allocation_method   = "Static"
  location            = "uksouth"
  name                = "app-gw-pip"
  resource_group_name = "app-gateway"
  sku                 = "Standard"
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
resource "azurerm_virtual_network" "vnet" {
  address_space       = ["10.0.0.0/16"]
  location            = "uksouth"
  name                = "prd-vnet-001"
  resource_group_name = "app-gateway"
  depends_on = [
    azurerm_resource_group.rg,
  ]
}
