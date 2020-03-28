# Lab: Serverless Endpoint


## Introduction

How can I set up and connect to serverless endpoints?

The point of this lab is to investigate how to set up serverless endpoints. Specifically, I want to have set up on each 
of AWS, GCP, and Azure a serverless collection that will exercise:

* authenticated HTTP REST endpoints
* calling authenticated HTTP REST endpoints from other endpoints
* reading from and writing to a database from endpoints

The focus is strictly on the serverless setup itself. So things like authentication will be kept as simple as possible 
(eg hard-coded user lists), albeit in the spirit of how they live in the wild. Also, there won't be any sharing of the 
library across examples - it should be the simplest possible setup not on each environment.



## Application

The app will be a simple postboard. It will let you POST Messages to a Board and GET Messages from a Board. It will
offer basic substition with the `@` escape character. Specifically `@random_word` will get replaced with a random word.

Endpoints:

| Endpoint          | Method        | Description   |
| ---               | ---           | ---           |
| /board/<board-id> | GET           | Returns a list of the Messages posted to Board <board-id> |
|                   | POST          | Adds the content as a Message to Board <board-id>. Returns the resolved message |
| /random_word      | GET           | Returns a random word. | 


See flask_postboard for a basic Flask implementation.



# Deployment

For the obvious reasons, deployment should be entirely automated. As far as direct cloud provisioning tools go, 
Terraform seems to be the only one that works across all the major clouds. It has all the nice features:
* open source
* declarative
* masterless
* large community
* engine behind a lot of enterprise stacks
So Terraform it is.

The alternatives seem to lie in two main groups:

1) Cloud-specific. Each cloud has their own CLI, which allows building a procedural script to provision a cluster. Some 
provide a declarative layer on to, eg CloudFormation on AWS (with SAM a serverless-specific component on top).
2) API abstractions. There are a few API frameworks which provide an additional layer of abstraction by allowing the
user just to define an API and have ther framework decide the appropriate things to provision. The Serverless framework
seems to be the leader here.

While (2) sounds closer to where I'd like to eventually end up, the point of this lab is to explore the different 
clouds' setups so I will avoid these extra abstractions.



# Terraform

Terraform is an open-source app produced by Hashicorp. A binary distribution is available on their website. 
Configuration is defined in one or more declarative files in Hashicorp Configuration Language (HCL), their custom 
JSON-esque language. Having defined a cluster setup, this can be deployed, updates deployed, and torn down. This all
happens from the machine it's run without need of a master controller or worker processes.


### Deploy

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

### Format

The format is as a number of resources. Each resource is defined like:

```hcl-terraform
resource "the_resource_type" "resource_name" {
  param1 = "value1"
  param2 = another_resource_type.that_resource_name.parameter
}
```

It's declarative, so the ordering isn't important (and can live across multiple `*.tf` files). Terraform resolves the
dependency graph and builds respecting this DAG applying parallelism where it can.


### Variables

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


### More features

In building production deployments, there are a few other key features to allow for modularity. As this strays from the 
purpose of this lab, I'm eliding this. But a quick overview of some key features:

#### Modules

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

#### Conditionality and repetition

Most resources support a `count` parameter. This, with some games, allows for condionality (true=1, false=0) and 
repetition (using `count.index` to parameterize the other components and `length(var.my_list)`, eg).

Since the 0.12 release, there are additional options with `for` and `for_each`.

#### Availability

To ensure availability through deployment updates, Terraform offers some features. Check out the docs on 
`create_before_destroy`.



## AWS







## References

### Terraform

https://learn.hashicorp.com/terraform#getting-started

https://www.endava.com/en/blog/Engineering/2019/11-Things-I-wish-I-knew-before-working-with-Terraform-I

https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9


### AWS

https://medium.com/galvanize/aws-lambda-deployment-with-terraform-24d36cc86533

https://learn.hashicorp.com/terraform/aws/lambda-api-gateway

https://www.davidbegin.com/the-most-minimal-aws-lambda-function-with-python-terraform/

https://github.com/awslabs/aws-apigateway-lambda-authorizer-blueprints/blob/master/blueprints/python/api-gateway-authorizer-python.py

https://github.com/terraform-providers/terraform-provider-aws/issues/6352