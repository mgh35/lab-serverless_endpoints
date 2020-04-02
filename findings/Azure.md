# Azure


## Functions

Python seems to be a recent addition with limited support. The issue that killed me was that it currently only works on
Linux but I couldn't find the right way to set this up in Terraform. From what I could gather, this requires adding:

```hcl-terraform
resource "azurerm_function_app" "functions" {
  ...

  os_type = "linux"

  ...

  site_config {
    // linux_fx_version = "DOCKER|microsoft/azure-functions-python3.6:2.0"
    // linux_fx_version = "DOCKER|mcr.microsoft.com/azure-functions/python:2.0-python3.6-appservice"
    // linux_fx_version = "DOCKER|mcr.microsoft.com/azure-functions/python:2.0"
    // linux_fx_version = "DOCKER|azure-functions/python:2.0"
    // linux_fx_version = "Python|3.7"
    ...
  }
}
```

But all of the linux_fx_version I could find referenced were rejected by Azure's API with no indication of what a valid
value might be. As it's rather tangential to this lab, moving to Node instead.

## Authentication

## Debugging

The Node package `azure-functions-core-tools` offers a number of utilities for Azure Functions dev. One is to run a 
local server hosting you local Functions. To use this, from you functions directory:

```shell script
func start
```

Note - It requires particular versions of Node. You can use `n` to set that. See the references. 