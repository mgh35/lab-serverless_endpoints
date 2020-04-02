provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x.
  # If you are using version 1.x, the "features" block is not allowed.
  version = "~>2.0"
  features {}
}

resource "azurerm_resource_group" "postboard" {
    name = "postboard"
    location = "East US"
}

resource "random_id" "postboard_source" {
  byte_length = 4
  prefix = "postboardsource"
  keepers = {
    # Locks the ID until we change the version
    version = "1"
  }
}

resource "azurerm_storage_account" "postboard" {
  name                     = random_id.postboard_source.hex
  resource_group_name      = azurerm_resource_group.postboard.name
  location                 = azurerm_resource_group.postboard.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "source" {
  name                  = "source"
  storage_account_name  = azurerm_storage_account.postboard.name
  container_access_type = "private"
}

data "archive_file" "source" {
  type        = "zip"
  output_path = ".pkg/source.zip"
  source_dir = "../postboard"
}

resource "azurerm_storage_blob" "source" {
  name = "source-${data.archive_file.source.output_base64sha256}.zip"
  storage_account_name   = azurerm_storage_account.postboard.name
  storage_container_name = azurerm_storage_container.source.name
  type   = "Block"
  source = data.archive_file.source.output_path
}

data "azurerm_storage_account_sas" "postboard" {
  connection_string = azurerm_storage_account.postboard.primary_connection_string
  https_only        = true
  resource_types {
    service   = false
    container = false
    object    = true
  }
  services {
    blob  = true
    queue = false
    table = false
    file  = false
  }
  start  = "2020-04-01"
  expiry = "2030-04-01"
  permissions {
    read    = true
    write   = false
    delete  = false
    list    = false
    add     = false
    create  = false
    update  = false
    process = false
  }
}

resource "azurerm_application_insights" "postboard" {
  name                = "postboard-appInsights"
  location            = azurerm_resource_group.postboard.location
  resource_group_name = azurerm_resource_group.postboard.name
  application_type    = "web"
}

resource "azurerm_app_service_plan" "postboard" {
  name = "postboard"
  resource_group_name = azurerm_resource_group.postboard.name
  location = azurerm_resource_group.postboard.location
  kind = "FunctionApp"

  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "random_id" "postboard_app" {
  byte_length = 8
  prefix = "postboard-"
  keepers = {
    # Locks the ID until we change the version
    version = "1"
  }
}

resource "azurerm_function_app" "functions" {
  name = random_id.postboard_app.hex
  location = azurerm_resource_group.postboard.location
  resource_group_name = azurerm_resource_group.postboard.name
  app_service_plan_id =azurerm_app_service_plan.postboard.id
  storage_connection_string = azurerm_storage_account.postboard.primary_connection_string

  version = "~2"

  app_settings = {
    https_only = true
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.postboard.instrumentation_key
    FUNCTIONS_WORKER_RUNTIME = "node"
    WEBSITE_NODE_DEFAULT_VERSION = "~10"
    FUNCTION_APP_EDIT_MODE = "readonly"
    HASH = data.archive_file.source.output_base64sha256
    WEBSITE_RUN_FROM_PACKAGE = "https://${azurerm_storage_account.postboard.name}.blob.core.windows.net/${azurerm_storage_container.source.name}/${azurerm_storage_blob.source.name}${data.azurerm_storage_account_sas.postboard.sas}"
  }

  auth_settings {
    enabled = false
  }
}

output "functionapp_id" {
  value = azurerm_function_app.functions.id
}

output "api_host" {
  value = azurerm_function_app.functions.default_hostname
}
