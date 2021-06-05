provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

data "azurerm_client_config" "current" {}

data "http" "ifconfig" {
  url = "http://ifconfig.me"
}

resource "random_pet" "apim" {
  length    = 2
  separator = ""
}

resource "random_password" "apim" {
  length  = 16
  lower   = true
  upper   = true
  special = true
}

##############################################
# AZURE RESOURCE GROUP
##############################################

resource "azurerm_resource_group" "apim" {
  name     = "rg-${random_pet.apim.id}-apim"
  location = var.location
  tags     = var.tags
}

##############################################
# AZURE MONITOR
##############################################

resource "azurerm_log_analytics_workspace" "apim" {
  name                = "law-${random_pet.apim.id}"
  resource_group_name = azurerm_resource_group.apim.name
  location            = azurerm_resource_group.apim.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}

resource "azurerm_application_insights" "apim" {
  name                = "ai-${random_pet.apim.id}"
  resource_group_name = azurerm_resource_group.apim.name
  location            = azurerm_resource_group.apim.location
  application_type    = "web"
  tags                = var.tags
}

##############################################
# AZURE VIRTUAL NETWORK
##############################################

resource "azurerm_virtual_network" "apim" {
  name                = "vn-${random_pet.apim.id}"
  resource_group_name = azurerm_resource_group.apim.name
  location            = azurerm_resource_group.apim.location
  address_space       = var.vnet_address_space
  tags                = var.tags
}

resource "azurerm_subnet" "appgw" {
  name                 = "ApplicationGatewaySubnet"
  resource_group_name  = azurerm_resource_group.apim.name
  virtual_network_name = azurerm_virtual_network.apim.name
  address_prefixes     = var.snet_agw_address_space
}

resource "azurerm_subnet" "apim" {
  name                 = "APIManagementSubnet"
  resource_group_name  = azurerm_resource_group.apim.name
  virtual_network_name = azurerm_virtual_network.apim.name
  address_prefixes     = var.snet_api_address_space
}

resource "azurerm_network_security_group" "apim" {
  name                = "nsg-${random_pet.apim.id}"
  location            = azurerm_resource_group.apim.location
  resource_group_name = azurerm_resource_group.apim.name

  security_rule {
    name                       = "AllowClientCommunicationInBound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowManagementEndpointInBound"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3443"
    source_address_prefix      = "ApiManagement"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowStorageOutBound"
    priority                   = 1002
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Storage"
  }

  security_rule {
    name                       = "AllowAzureActiveDirectoryOutBound"
    priority                   = 1003
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureActiveDirectory"
  }

  security_rule {
    name                       = "AllowSQLOutBound"
    priority                   = 1004
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Sql"
  }

  security_rule {
    name                       = "AllowAzureKeyVaultOutBound"
    priority                   = 1005
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureKeyVault"
  }

  security_rule {
    name                       = "AllowEventHubOutBound"
    priority                   = 1006
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["5671", "5672", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "EventHub"
  }

  security_rule {
    name                       = "AllowFileShareOutBound"
    priority                   = 1007
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "445"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Storage"
  }

  security_rule {
    name                       = "AllowAzureCloudOutBound"
    priority                   = 1008
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["443", "12000"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureCloud"
  }

  security_rule {
    name                       = "AllowAzureMonitorOutBound"
    priority                   = 1009
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["1886", "443"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "AzureMonitor"
  }

  security_rule {
    name                       = "AllowInternetOutBound"
    priority                   = 1010
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["25", "587", "25028"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
  }

  security_rule {
    name                       = "AllowRedisInBound"
    priority                   = 1011
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["6381-6383"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowRedisOutBound"
    priority                   = 1012
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["6381-6383"]
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowSyncCountersInBound"
    priority                   = 1013
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4290"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowSyncCountersOutBound"
    priority                   = 1014
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "4290"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  security_rule {
    name                       = "AllowAzureLoadBalancerInBound"
    priority                   = 1015
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = var.tags
}

resource "azurerm_subnet_network_security_group_association" "apim" {
  subnet_id                 = azurerm_subnet.apim.id
  network_security_group_id = azurerm_network_security_group.apim.id
}

##############################################
# AZURE API MANAGEMENT
##############################################

resource "azurerm_api_management" "apim" {
  name                = "apim-${random_pet.apim.id}"
  resource_group_name = azurerm_resource_group.apim.name
  location            = azurerm_resource_group.apim.location
  publisher_name      = var.apim_publishername
  publisher_email     = var.apim_publisheremail
  sku_name            = var.apim_sku

  virtual_network_type = "External"

  virtual_network_configuration {
    subnet_id = azurerm_subnet.apim.id
  }

  tags = var.tags
}

resource "azurerm_api_management_logger" "apim" {
  name                = "apim-${random_pet.apim.id}-logger"
  resource_group_name = azurerm_resource_group.apim.name
  api_management_name = azurerm_api_management.apim.name

  application_insights {
    instrumentation_key = azurerm_application_insights.apim.instrumentation_key
  }
}

resource "azurerm_api_management_diagnostic" "apim" {
  identifier               = "applicationinsights"
  resource_group_name      = azurerm_resource_group.apim.name
  api_management_name      = azurerm_api_management.apim.name
  api_management_logger_id = azurerm_api_management_logger.apim.id
}

resource "azurerm_monitor_diagnostic_setting" "apim" {
  name                           = "${azurerm_api_management.apim.name}-diagnostics"
  target_resource_id             = azurerm_api_management.apim.id
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.apim.id
  log_analytics_destination_type = "Dedicated"

  log {
    category = "GatewayLogs"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }
}

##############################################
# AZURE REDIS CACHE
##############################################

resource "azurerm_redis_cache" "apim" {
  name                = "redis-${random_pet.apim.id}"
  resource_group_name = azurerm_resource_group.apim.name
  location            = azurerm_resource_group.apim.location
  capacity            = 1
  family              = "C"
  sku_name            = "Standard"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"

  redis_configuration {
  }
}

##############################################
# AZURE SQL DATABASE
##############################################

resource "azurerm_resource_group" "sql" {
  name     = "rg-${random_pet.apim.id}-sql"
  location = var.location
  tags     = var.tags
}

resource "azurerm_sql_server" "sql" {
  name                         = "sql${replace(random_pet.apim.id, "-", "")}"
  resource_group_name          = azurerm_resource_group.sql.name
  location                     = azurerm_resource_group.sql.location
  version                      = "12.0"
  administrator_login          = var.username
  administrator_login_password = random_password.apim.result
  tags                         = var.tags
}

resource "azurerm_sql_firewall_rule" "rule1" {
  name                = "AllowAllWindowsAzureIps"
  resource_group_name = azurerm_resource_group.sql.name
  server_name         = azurerm_sql_server.sql.name
  start_ip_address    = "0.0.0.0"
  end_ip_address      = "0.0.0.0"
}

# resource "azurerm_sql_firewall_rule" "rule2" {
#   name                = "ClientIPAddress"
#   resource_group_name = azurerm_resource_group.sql.name
#   server_name         = azurerm_sql_server.sql.name
#   start_ip_address    = data.http.ifconfig.body
#   end_ip_address      = data.http.ifconfig.body
# }

resource "azurerm_sql_database" "sql" {
  name                             = var.database_name
  resource_group_name              = azurerm_resource_group.sql.name
  location                         = azurerm_resource_group.sql.location
  server_name                      = azurerm_sql_server.sql.name
  edition                          = "Standard"
  requested_service_objective_name = "S0"
  tags                             = var.tags
}

##########################################################
# AZURE KEY VAULT
##########################################################

resource "azurerm_key_vault" "apim" {
  name                            = "kv-${random_pet.apim.id}"
  resource_group_name             = azurerm_resource_group.apim.name
  location                        = azurerm_resource_group.apim.location
  tags                            = var.tags
  enabled_for_disk_encryption     = true
  enabled_for_template_deployment = true
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days      = 90
  purge_protection_enabled        = true
  sku_name                        = "standard"
}

resource "azurerm_key_vault_access_policy" "me" {
  key_vault_id = azurerm_key_vault.apim.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "backup",
    "create",
    "delete",
    "deleteissuers",
    "get",
    "getissuers",
    "import",
    "list",
    "listissuers",
    "managecontacts",
    "manageissuers",
    "purge",
    "recover",
    "restore",
    "setissuers",
    "update"
  ]
  key_permissions = [
    "backup",
    "create",
    "decrypt",
    "delete",
    "encrypt",
    "get",
    "import",
    "list",
    "purge",
    "recover",
    "restore",
    "sign",
    "unwrapKey",
    "update",
    "verify",
    "wrapKey"
  ]
  secret_permissions = [
    "backup",
    "delete",
    "get",
    "list",
    "purge",
    "recover",
    "restore",
    "set"
  ]
  storage_permissions = [
    "backup",
    "delete",
    "deletesas",
    "get",
    "getsas",
    "list",
    "listsas",
    "purge",
    "recover",
    "regeneratekey",
    "restore",
    "set",
    "setsas",
    "update"
  ]

  depends_on = [
    azurerm_key_vault.apim
  ]
}

resource "azurerm_key_vault_secret" "conn" {
  name         = "connection-string"
  value        = "Server=tcp:${azurerm_sql_server.sql.fully_qualified_domain_name},1433;Initial Catalog=ContosoUniversity;Persist Security Info=False;User ID=${var.username};Password=${random_password.apim.result};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = azurerm_key_vault.apim.id
  tags         = var.tags

  depends_on = [
    azurerm_key_vault_access_policy.me
  ]
}

##########################################################
# AZURE APP SERVICE - WINDOWS
##########################################################

resource "azurerm_resource_group" "web1" {
  name     = "rg-${random_pet.apim.id}-web1"
  location = var.location

  tags = var.tags
}

resource "azurerm_app_service_plan" "web1" {
  name                = "app-${random_pet.apim.id}-web1plan"
  resource_group_name = azurerm_resource_group.web1.name
  location            = azurerm_resource_group.web1.location

  sku {
    tier = "Standard"
    size = "S1"
  }

  tags = var.tags
}

resource "azurerm_app_service" "web1" {
  name                = "app-${random_pet.apim.id}-web1wcf"
  resource_group_name = azurerm_resource_group.web1.name
  location            = azurerm_resource_group.web1.location
  app_service_plan_id = azurerm_app_service_plan.web1.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    dotnet_framework_version = "v4.0"
  }

  connection_string {
    name  = "DbContext"
    type  = "SQLAzure"
    value = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.apim.name};SecretName=${azurerm_key_vault_secret.conn.name})"
  }

  tags = var.tags
}

resource "azurerm_key_vault_access_policy" "web1" {
  key_vault_id = azurerm_key_vault.apim.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_app_service.web1.identity.0.principal_id

  certificate_permissions = [
    "get",
    "list",
  ]

  secret_permissions = [
    "get",
    "list",
  ]

  depends_on = [
    azurerm_key_vault.apim,
    azurerm_app_service.web1
  ]
}

##########################################################
# AZURE APP SERVICE - LINUX
##########################################################

resource "azurerm_resource_group" "web2" {
  name     = "rg-${random_pet.apim.id}-web2"
  location = var.location
  tags     = var.tags
}

resource "azurerm_app_service_plan" "web2" {
  name                = "app-${random_pet.apim.id}-web2plan"
  resource_group_name = azurerm_resource_group.web2.name
  location            = azurerm_resource_group.web2.location
  kind                = "Linux"
  reserved            = true

  sku {
    tier = "Standard"
    size = "S1"
  }

  tags = var.tags
}

resource "azurerm_app_service" "web2" {
  name                = "app-${random_pet.apim.id}-web2rest"
  location            = azurerm_resource_group.web2.location
  resource_group_name = azurerm_resource_group.web2.name
  app_service_plan_id = azurerm_app_service_plan.web2.id

  app_settings = {
    WEBSITE_WEBDEPLOY_USE_SCM = true
  }

  site_config {
    linux_fx_version = "DOTNETCORE|5.0" # az webapp list-runtimes --linux
    default_documents = [
      "Default.htm",
      "Default.html",
      "Default.asp",
      "index.htm",
      "index.html",
      "iisstart.htm",
      "default.aspx",
      "index.php",
      "hostingstart.html",
    ]
    use_32_bit_worker_process = true
  }

  identity {
    type = "SystemAssigned"
  }

  connection_string {
    name  = "DbContext"
    type  = "SQLAzure"
    value = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.apim.name};SecretName=${azurerm_key_vault_secret.conn.name})"
  }

  tags = var.tags
}

resource "azurerm_app_service_slot" "web2slot" {
  name                = "main"
  app_service_name    = azurerm_app_service.web2.name
  location            = azurerm_resource_group.web2.location
  resource_group_name = azurerm_resource_group.web2.name
  app_service_plan_id = azurerm_app_service_plan.web2.id

  app_settings = {
    WEBSITE_WEBDEPLOY_USE_SCM = true
  }

  site_config {
    linux_fx_version = "DOTNETCORE|5.0" # az webapp list-runtimes --linux
    default_documents = [
      "Default.htm",
      "Default.html",
      "Default.asp",
      "index.htm",
      "index.html",
      "iisstart.htm",
      "default.aspx",
      "index.php",
      "hostingstart.html",
    ]
    use_32_bit_worker_process = true
  }

  identity {
    type = "SystemAssigned"
  }

  connection_string {
    name  = "DbContext"
    type  = "SQLAzure"
    value = "@Microsoft.KeyVault(VaultName=${azurerm_key_vault.apim.name};SecretName=${azurerm_key_vault_secret.conn.name})"
  }
}

resource "azurerm_key_vault_access_policy" "web2" {
  key_vault_id = azurerm_key_vault.apim.id
  tenant_id    = azurerm_app_service.web2.identity.0.tenant_id
  object_id    = azurerm_app_service.web2.identity.0.principal_id

  certificate_permissions = [
    "get",
    "list",
  ]

  secret_permissions = [
    "get",
    "list",
  ]

  depends_on = [
    azurerm_key_vault.apim,
    azurerm_app_service.web2
  ]
}

resource "azurerm_key_vault_access_policy" "web2slot" {
  key_vault_id = azurerm_key_vault.apim.id
  tenant_id    = azurerm_app_service_slot.web2slot.identity[0].tenant_id
  object_id    = azurerm_app_service_slot.web2slot.identity[0].principal_id

  certificate_permissions = [
    "get",
    "list",
  ]

  secret_permissions = [
    "get",
    "list",
  ]

  depends_on = [
    azurerm_key_vault.apim,
    azurerm_app_service.web2
  ]
}

##########################################################
# AZURE FUNCTION
##########################################################

resource "azurerm_resource_group" "func1" {
  name     = "rg-${random_pet.apim.id}-func1"
  location = var.location
}

resource "azurerm_storage_account" "func1" {
  name                     = "sa${replace(random_pet.apim.id, "-", "")}"
  resource_group_name      = azurerm_resource_group.func1.name
  location                 = azurerm_resource_group.func1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_app_service_plan" "func1" {
  name                         = "app-${random_pet.apim.id}-func1plan"
  resource_group_name          = azurerm_resource_group.func1.name
  location                     = azurerm_resource_group.func1.location
  kind                         = "elastic"
  maximum_elastic_worker_count = 1
  is_xenon                     = false

  sku {
    tier     = "ElasticPremium"
    size     = "EP1"
    capacity = 1
  }
}

resource "azurerm_function_app" "func1" {
  name                       = "app-${random_pet.apim.id}-func1"
  resource_group_name        = azurerm_resource_group.func1.name
  location                   = azurerm_resource_group.func1.location
  app_service_plan_id        = azurerm_app_service_plan.func1.id
  storage_account_name       = azurerm_storage_account.func1.name
  storage_account_access_key = azurerm_storage_account.func1.primary_access_key
  version                    = "~3"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_key_vault_access_policy" "func1" {
  key_vault_id = azurerm_key_vault.apim.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_function_app.func1.identity.0.principal_id

  certificate_permissions = [
    "get",
    "list",
  ]

  secret_permissions = [
    "get",
    "list",
  ]

  depends_on = [
    azurerm_key_vault.apim,
    azurerm_function_app.func1
  ]
}

# create logic app

# create app gateway