# Azure

## Setup

The relevant provider is `azurerm`, now on v2:

```hcl-terraform
provider "azurerm" {
  version = "~>2.0"
  features {}
}
```

Azure recommends using creating a Service Principal authorized under your Account to to run Terraform. Once this is
created, it's credentials are passed to Terraform through environment variables.



## Permissions

Permissions felt less factored out than in AWS, for example. Most things happen directly through key-based auth.

Access to a storage bucket, for example, is via shared access signatures (SAS) that act as delegation tokens:

```hcl-terraform
data "azurerm_storage_account_sas" "postboard" {
  connection_string = azurerm_storage_account.postboard.primary_connection_string
  ...
}
```

The Cosmos DB database provides its own auth keys on creation. 

Calling Functions from others, meanwhile, goes through whatever auth is configured on the Function App directly.  



## Database

Azure's primary offering is Cosmos DB. This exposes a number of different APIs (for different use cases, but also to be
compatible with existing code). For key-value stores, there's either Azure's proprietary API or a MongoDB API (which 
will be used here).

This requires a Cosmos DB Account, which defines the API and localization, and then API-specific entities. For MongoDB,
this is a Database which then holds Collection.

The standard MongoDB client libraries can then be used to connect to it using the 
`azurerm_cosmosdb_account.{account}.primary_master_key` from the Account for credentials.



## Functions

The Functions are defined in a `azurerm_function_app`. This contains code for a single runtime living in a storage blob
ZIP with all dependencies. It has to be set up following Azure Function's opinionated structure, which involves looks 
like (with minor variants by language):

```
base-dir/
|- function1/
|  |- function.json
|  |- index.js
|- function2/
|  |- function.json
|  |- index.js
|...
|- node_modules/
|- shared_code/
|- host.json
```

The app_settings define both some parameters used to define the runtime as well as environment variable made available 
to the functions.

The Function App includes a light-weight proxy that lives on the container running the runtime. This provides an easy 
way to do simple:

* Auth. This has integrated both API key auth (used here, with keys living on the `azurerm_function_app` output) or a 
variety of oauth providers. These are configured through a mix of function.json and the resource in Terraform. 
* Routing. Each function can specify simple routing in its function.json. 

Azure also offers a more heavy-weight API gateway (offering OpenAPI, multiple protocols, and more auth option) with its 
API Management platform.



### But where is Python?

One big caveat to this exercise was that for Azure I had to abandon Python and build in Node.js.

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
value might be. As it's rather tangential to this lab, moved to Node.js instead. The Node.js runtime all just worked out
of the box as advertised.



## Debugging

The Node package `azure-functions-core-tools` offers a number of utilities for Azure Functions dev. One is to run a 
local server hosting you local Functions. To use this, from you functions directory:

```shell script
func start
```

Note - It requires particular versions of Node. You can use `n` to set that. See the references. 

Microsoft also seem to recommend Visual Studio Code, into which they have implemented a number of integrations. I 
didn't try that here.



## Logging

The Application Insights is Azure's central logging and monitoring service. 

It's easily added with a `azurerm_application_insights` and then referenced in the Function App Resource.



### Functions API

The functions receive a Context, as well as the relevant bindings as defined in the function.json definition. The 
function returns a JSON blob in the right form.

In Node.js, the index.js file has to export the single function. This function can either be synchronous or async. 

Note that different methods at the same endpoint are handled by the same handler.

For example:

```javascript
module.exports = async function (context, req) {
  var board = req.params.boardName;
  var method = req.method;
  var base_url = req.url.replace(/^(https?:\/\/[^\/]+)\/.*$/, '$1');
  var api_key = req.query.code;


  if (method.toUpperCase() === 'POST') {
    return await post_message(board, context.req.body, base_url, api_key);
  } else if (method.toUpperCase() === 'GET') {
    return await get_messages(board);
  } else {
    return {
      status: 403,
      body: {
        'error': `Unsupported method: ${method}`,
      },
      headers: {
        "content-type": "application/json",
      },
    };
  }
};
```


## Calling Azure Services from a Function

As mentioned above, I didn't find a unified Role-based model. Instead, the Function needs to get the 
credentials for the relevant services.

Here, eg, I connect to the Cosmos DB database using it's API key (passed via env variables). And call other functions by
passing through the API key passed to the original function.
