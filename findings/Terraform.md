# Terraform

Terraform is an open-source app produced by Hashicorp. A binary distribution is available on their website. 
Configuration is defined in one or more declarative files in Hashicorp Configuration Language (HCL), their custom 
JSON-esque language. Having defined a cluster setup, this can be deployed, updates deployed, and torn down. This all
happens from the machine it's run without need of a master controller or worker processes.


## Initialization

When running in a project, run

```shell script
terraform init
```

This sets up the terraform environment and downloads any required plugins. If you are adding things that require new 
plugins, this will need to be run again.


## Deploy

Specifically, you can run

```shell script
terraform apply
```  

to apply all the setup defined in the current directory. This loads all `*.tf` files in the current directory and 
builds all resources therein.

The resulting state is saved to a `.tfstate` file. This is what allows incremental changes and the ability to tear down
the current deployment. But note - this means that all deployments to the same cluster need to share the same `.tfstate`
or risk getting into inconsistent state. (For managing across multiple people, there are various pipeline or managed 
service options.)

This setup can be torn down with

```shell script
terraform destroy
```

(again - from the same directory where it was create since it relies on the `.tfstate` file).

To deploy changes made to the setup, re-running `terraform apply` will apply the (incremental) changes required. You 
can see the changes proposed with

```shell script
terraform plan
```

## Structure

The structure of the language is as a number of resources. Each resource is defined like:

```hcl-terraform
resource "the_resource_type" "resource_name" {
  param1 = "value1"
  param2 = another_resource_type.that_resource_name.parameter
}
```

It's declarative, so the ordering isn't important (and can live across multiple `*.tf` files). Terraform resolves the
dependency graph and builds respecting this DAG applying parallelism where it can.


## Variables

Terraform supports input and output variables. They are declares similarly in the config:

```hcl-terraform
variable "api_key" {
}

#...

output "api_key" {
  value = var.api_key
}
```

The input variables can be specified in variously:
* via `.tfvars` files
* on the command line with `-var api_key="blah"`
* with env variables like `export TF_VAR_api_key=blah`

Output variable are saved with the `.tfstate` and allow downstream processes to access information about the deployment 
with:

```shell script
API_KEY=$(terraform output api_key)
```


## More features

In building production deployments, there are a few other key features to allow for modularity. As this strays from the 
purpose of this lab, I'm eliding this. But a quick overview of some key features:

### Modules

Components can be encapsulated into modules, which are just folders of Terraform config living elsewhere. These can be 
included like:

```hcl-terraform
module "servers" {
  source = "./web-host"
  servers = 5
}
```

where the source can be a directory or repo. The variables defined in the modules repo become the parameters to the 
module resource.

### Conditionality and repetition

Most resources support a `count` parameter. This, with some games, allows for condionality (true=1, false=0) and 
repetition (using `count.index` to parameterize the other components and `length(var.my_list)`, eg).

Since the 0.12 release, there are additional options with `for` and `for_each`.

### Availability

To ensure availability through deployment updates, Terraform offers some features. Check out the docs on 
`create_before_destroy`.
