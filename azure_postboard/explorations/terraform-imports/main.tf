provider "azurerm" {
  # The "feature" block is required for AzureRM provider 2.x.
  # If you are using version 1.x, the "features" block is not allowed.
  version = "~>2.0"
  features {}
}

//resource "azurerm_app_service_plan" "test" {
//}

resource "azurerm_function_app" "test" {
}